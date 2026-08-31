-- Server-side, paginated, filterable provider search. The mobile app calls
-- this single RPC instead of ever selecting raw rows from provider_profiles
-- for search purposes, so filtering/sorting/pagination always happens in
-- Postgres, not on-device (spec section 17).
--
-- p_lat/p_lng/p_radius_km are optional: when omitted, results are not
-- distance-filtered or distance-sorted (falls back to rating desc), which
-- supports the "manual address, no GPS" flow from spec section 18.
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
