-- DEV/TEST DATA ONLY. Never run against staging or production.
-- Creates a second identity (a customer) directly in auth.users, bypassing
-- the normal signup flow, purely so the trigger-level actor-authorization
-- checks (customer vs. provider) can be verified with two distinct real
-- identities instead of one. This is not how real users are ever created —
-- production/staging users always go through Supabase Auth (OTP).
insert into auth.users (
  instance_id, id, aud, role, phone, phone_confirmed_at,
  raw_app_meta_data, raw_user_meta_data, created_at, updated_at
) values (
  '00000000-0000-0000-0000-000000000000',
  gen_random_uuid(),
  'authenticated',
  'authenticated',
  '251922345678',
  now(),
  '{"provider":"phone","providers":["phone"]}',
  '{}',
  now(),
  now()
)
on conflict (phone) do nothing;
