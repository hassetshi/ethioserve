-- Product pivot: providers now pay a recurring subscription to be listed
-- in search (spec: "Service Provider -> Paid registration/listing"), using
-- Stripe Subscriptions rather than the one-off PaymentIntent flow already
-- built for bookings. These columns let the webhook find/update the right
-- row from a Stripe event, and let a provider have at most one active plan.
alter table public.subscriptions
  add column stripe_customer_id text,
  add column stripe_subscription_id text unique,
  add column current_period_end timestamptz;

create unique index uq_subscriptions_one_active_per_provider
  on public.subscriptions(provider_id)
  where status = 'active';

-- subscriptions_select_own (20260831000008_rls_policies.sql) only lets a
-- provider read their OWN subscription row. search_providers below needs to
-- check *other* providers' subscription status too, and runs `security
-- invoker` (as the anon/authenticated caller, same as every other public
-- search path) rather than `security definer` — so without a public read
-- policy, that existence check would silently see zero rows for every
-- anonymous caller and search_providers would return nothing at all. Whether
-- a provider is actively subscribed isn't sensitive (same exposure level as
-- verification_status, already public); mirrors the existing
-- advertisements_select_own_or_active pattern of exposing just the "active"
-- rows publicly.
create policy subscriptions_select_active_public on public.subscriptions
  for select using (status = 'active');

-- Placeholder pricing, admin-editable (spec: numbers are data, not code -
-- see booking_commission_rate). stripe_price_id is filled in by
-- scripts/create-stripe-subscription-prices.mjs once real Stripe Price
-- objects exist for these plans.
insert into public.platform_settings (key, value, description) values
  (
    'subscription_plan_professional',
    '{"price_usd": 29, "stripe_price_id": null, "interval": "month"}',
    'Professional provider listing plan: price and Stripe Price ID.'
  ),
  (
    'subscription_plan_premium',
    '{"price_usd": 79, "stripe_price_id": null, "interval": "month"}',
    'Premium provider listing plan: price and Stripe Price ID.'
  )
on conflict (key) do nothing;

-- platform_settings is admin-only via RLS (platform_settings_admin_only), so
-- the mobile app needs a narrow, read-only bypass to show real plan prices
-- to a provider deciding whether to subscribe - same bypass pattern as
-- log_admin_action (20260901000022_admin_audit_log_rpc.sql) for writes.
create or replace function public.get_subscription_plans()
returns table (plan text, price_usd numeric, stripe_price_id text, interval text)
language sql
stable
security definer
set search_path = public
as $$
  select
    replace(key, 'subscription_plan_', '') as plan,
    (value ->> 'price_usd')::numeric as price_usd,
    value ->> 'stripe_price_id' as stripe_price_id,
    value ->> 'interval' as interval
  from public.platform_settings
  where key in ('subscription_plan_professional', 'subscription_plan_premium');
$$;

grant execute on function public.get_subscription_plans() to authenticated;

-- Search now requires an active paid subscription in addition to being
-- verified (spec: "Only registered and approved service providers... paid
-- registration/subscription" appear in search). A grace period on lapsed
-- subscriptions is intentionally not modeled here - current_period_end
-- null (subscription created but Stripe hasn't reported a period yet) is
-- treated as "not yet confirmed", not "always valid".
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
        and sub.plan in ('professional', 'premium')
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
