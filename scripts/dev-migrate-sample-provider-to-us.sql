-- DEV/TEST DATA ONLY. Never run against production.
-- Re-points the Phase 3 sample provider (originally Ethiopia-based) to the
-- product pivot's new launch city, reusing the existing test account rather
-- than creating a fresh one - a brand-new provider would need its own real
-- OTP login first (see dev-seed-sample-provider.sql's own comment on why
-- that account exists in the first place). `latitude`/`longitude` changing
-- re-fires trg_provider_profiles_sync_location, which recomputes the
-- geography `location` column used by search_providers' radius filtering.
do $$
declare
  v_provider_id uuid;
  v_city_id uuid;
begin
  select id into v_city_id from public.cities where name_en = 'Washington, DC';

  update public.provider_profiles
  set business_name = 'DC Metro Plumbing Experts',
      description_en = 'Fast, reliable plumbing repairs across the DC metro area.',
      description_am = 'በዋሽንግተን ዲሲ አካባቢ ፈጣንና አስተማማኝ የቧንቧ ጥገና አገልግሎት።',
      address = 'Silver Spring, MD',
      city_id = v_city_id,
      latitude = 38.9959,
      longitude = -77.0281
  where business_name = 'Addis Plumbing Experts'
  returning id into v_provider_id;

  if v_provider_id is null then
    raise notice 'No provider named Addis Plumbing Experts found - nothing to migrate.';
  else
    update public.provider_services
    set min_price = 50, max_price = 150
    where provider_id = v_provider_id;

    raise notice 'Migrated provider_id to DC: %', v_provider_id;
  end if;
end $$;
