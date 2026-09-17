-- search_providers (20260909000027) gives a result card no way to show a
-- phone number or address without a second round-trip per provider, and no
-- way to say whether a provider looks open right now. This adds both
-- without touching any existing filter/join/order-by:
--   - phone/address: plain passthrough columns from provider_profiles
--     (phone is already nullable as of 20260909000031).
--   - is_open_now: computed from provider_availability for the CURRENT
--     day/time. Every provider seeded so far is DMV-area (see
--     20260909000028/29), so "now" is evaluated in America/New_York
--     rather than the database session's UTC default - this is a known
--     simplification, not real per-provider timezone support (there is no
--     timezone column on provider_profiles). Revisit if/when providers
--     outside the DMV area are onboarded.
--   - is_open_now is null (not false) whenever a provider has zero
--     provider_availability rows, so the client can render "hours not
--     listed" instead of a misleading "closed". As of this migration the
--     real seeded provider set has no availability rows at all, so expect
--     null for virtually every result until providers add hours.
--
-- CREATE OR REPLACE cannot change a function's OUT-parameter row type (even
-- to add columns) - confirmed live: `cannot change return type of existing
-- function (SQLSTATE 42P13)`. Drop and recreate instead, which also drops
-- the explicit grant from 20260831000009_search_functions.sql, so that
-- grant is reissued below.
drop function if exists public.search_providers(
  uuid, uuid, uuid, double precision, double precision, numeric, numeric, boolean, integer, integer
);

create function public.search_providers(
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
  phone text,
  address text,
  rating numeric,
  review_count integer,
  verification_status text,
  distance_km double precision,
  is_open_now boolean
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
    p.phone,
    p.address,
    p.rating,
    p.review_count,
    p.verification_status,
    case
      when p_lat is not null and p_lng is not null and p.location is not null
        then ST_Distance(p.location, ST_SetSRID(ST_MakePoint(p_lng, p_lat), 4326)::geography) / 1000.0
      else null
    end as distance_km,
    case
      when not exists (
        select 1 from public.provider_availability pa where pa.provider_id = p.id
      ) then null
      else exists (
        select 1
        from public.provider_availability pa
        where pa.provider_id = p.id
          and pa.is_available
          and pa.day_of_week = extract(dow from (now() at time zone 'America/New_York'))::smallint
          and (now() at time zone 'America/New_York')::time between pa.start_time and pa.end_time
      )
    end as is_open_now
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

grant execute on function public.search_providers(
  uuid, uuid, uuid, double precision, double precision, numeric, numeric, boolean, integer, integer
) to authenticated, anon;
