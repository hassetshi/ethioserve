-- DEV/TEST DATA ONLY. Never run against staging or production.
-- Turns the existing test user (created by an earlier OTP smoke test) into
-- a verified provider offering Pipe Repair, so the Phase 3 browse flow
-- (categories -> services -> providers -> profile) has real data to show.
do $$
declare
  v_user_id uuid;
  v_provider_id uuid;
  v_service_id uuid;
  v_city_id uuid;
begin
  select id into v_user_id from public.users where phone = '251912345678';
  select id into v_city_id from public.cities where name_en = 'Addis Ababa';
  select id into v_service_id from public.services where name_en = 'Pipe Repair';

  update public.users set role = 'provider' where id = v_user_id;

  insert into public.provider_profiles (
    user_id, business_name, description_en, description_am,
    phone, address, city_id, latitude, longitude,
    verification_status, verification_date, is_active
  ) values (
    v_user_id, 'Addis Plumbing Experts',
    'Fast, reliable plumbing repairs across Addis Ababa.',
    'በአዲስ አበባ ውስጥ ፈጣንና አስተማማኝ የቧንቧ ጥገና አገልግሎት።',
    '+251911000000', 'Bole, Addis Ababa', v_city_id, 8.9944, 38.7892,
    'verified', now(), true
  )
  returning id into v_provider_id;

  insert into public.provider_services (provider_id, service_id, min_price, max_price, pricing_type)
  values (v_provider_id, v_service_id, 300, 800, 'starting_from');

  raise notice 'Seeded provider_id: %', v_provider_id;
end $$;
