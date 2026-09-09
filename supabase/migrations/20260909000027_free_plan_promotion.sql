-- Launch promotion: providers can get listed for free for a limited time,
-- instead of only choosing between the two paid plans added in
-- 20260901000025. The `subscriptions.plan` check constraint has allowed
-- 'free' since the table was first created (20260831000006) - this was
-- simply never wired up to the newer Stripe-backed plan flow.
--
-- The free plan needs no Stripe involvement at all (no stripe_price_id, no
-- customer, no PaymentSheet) - subscribe_free_plan below writes the
-- `subscriptions` row directly, gated by ownership and by the promo window,
-- the same way stripe-create-subscription is gated for the paid plans.
insert into public.platform_settings (key, value, description) values
  (
    'subscription_plan_free',
    jsonb_build_object(
      'price_usd', 0,
      'interval', 'month',
      'promo_ends_at', (now() + interval '3 months')
    ),
    'Free provider listing plan: launch promotion, offered only until promo_ends_at.'
  )
on conflict (key) do nothing;

-- Only surfaces the free plan while its promo window is open, so the
-- mobile app naturally stops offering it afterward with no client-side
-- date logic - the same "numbers are admin-editable data" pattern as the
-- paid plans' pricing.
create or replace function public.get_subscription_plans()
returns table (plan text, price_usd numeric, stripe_price_id text, "interval" text)
language sql
stable
security definer
set search_path = public
as $$
  select
    replace(key, 'subscription_plan_', '') as plan,
    (value ->> 'price_usd')::numeric as price_usd,
    value ->> 'stripe_price_id' as stripe_price_id,
    value ->> 'interval' as "interval"
  from public.platform_settings
  where key in ('subscription_plan_professional', 'subscription_plan_premium')

  union all

  select 'free', 0, null, 'month'
  from public.platform_settings
  where key = 'subscription_plan_free'
    and (value ->> 'promo_ends_at')::timestamptz > now();
$$;

-- A free-plan listing is only ever offered up to the promo's end, so its
-- current_period_end is pinned there rather than to a rolling one-month
-- period like a real recurring plan - it simply stops appearing in search
-- once the promotion ends, same enforcement search_providers already does
-- for lapsed paid plans via current_period_end.
create or replace function public.subscribe_free_plan(p_provider_id uuid)
returns public.subscriptions
language plpgsql
security definer
set search_path = public
as $$
declare
  v_promo_ends_at timestamptz;
  v_is_owner boolean;
  v_has_active boolean;
  v_row public.subscriptions;
begin
  select (user_id = auth.uid()) into v_is_owner
  from public.provider_profiles
  where id = p_provider_id;

  if v_is_owner is not true then
    raise exception 'Only the provider owner can subscribe';
  end if;

  select exists(
    select 1 from public.subscriptions
    where provider_id = p_provider_id and status = 'active'
  ) into v_has_active;

  if v_has_active then
    raise exception 'This provider already has an active subscription';
  end if;

  select (value ->> 'promo_ends_at')::timestamptz into v_promo_ends_at
  from public.platform_settings
  where key = 'subscription_plan_free';

  if v_promo_ends_at is null or v_promo_ends_at <= now() then
    raise exception 'This offer is no longer available';
  end if;

  insert into public.subscriptions (provider_id, plan, price, status, current_period_end)
  values (p_provider_id, 'free', 0, 'active', v_promo_ends_at)
  returning * into v_row;

  return v_row;
end;
$$;

grant execute on function public.subscribe_free_plan(uuid) to authenticated;

-- search_providers (20260901000025) only recognized the two paid plans -
-- a free-plan provider would pass verification but never actually appear
-- in search results, defeating the entire point of the promotion.
create or replace function public.search_providers(
  p_category_id uuid default null,
  p_service_id uuid default null,
  p_city_id uuid default null,
  p_lat double precision default null,
  p_lng double precision default null,
  p_radius_km numeric default 25,
  p_min_rating numeric default null,
  p_verified_only boolean default true,
  p_limit integer default 20,
  p_offset integer default 0
)
returns table (
  provider_id uuid,
  business_name text,
  description_en text,
  description_am text,
  city_id uuid,
  rating numeric,
  review_count integer,
  verification_status text,
  distance_km double precision
)
language sql
stable
security invoker
set search_path = public
as $$
  select
    p.id as provider_id,
    p.business_name,
    p.description_en,
    p.description_am,
    p.city_id,
    p.rating,
    p.review_count,
    p.verification_status,
    case
      when p_lat is not null and p_lng is not null and p.location is not null
        then ST_Distance(p.location, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography) / 1000.0
      else null
    end as distance_km
  from public.provider_profiles p
  where p.is_active
    and (not p_verified_only or p.verification_status = 'verified')
    and exists (
      select 1 from public.subscriptions sub
      where sub.provider_id = p.id
        and sub.status = 'active'
        and sub.plan in ('professional', 'premium', 'free')
        and sub.current_period_end >= now()
    )
    and (p_city_id is null or p.city_id = p_city_id)
    and (p_min_rating is null or p.rating >= p_min_rating)
    and (
      p_category_id is null or exists (
        select 1
        from public.provider_services ps
        join public.services s on s.id = ps.service_id
        where ps.provider_id = p.id and s.category_id = p_category_id
      )
    )
    and (
      p_service_id is null or exists (
        select 1 from public.provider_services ps
        where ps.provider_id = p.id and ps.service_id = p_service_id
      )
    )
    and (
      p_lat is null or p_lng is null or p.location is null or
      ST_DWithin(p.location, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography, p_radius_km * 1000)
    )
  order by
    case when p_lat is not null and p_lng is not null then
      ST_Distance(p.location, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography)
    end asc nulls last,
    p.rating desc
  limit least(p_limit, 50)
  offset greatest(p_offset, 0);
$$;
