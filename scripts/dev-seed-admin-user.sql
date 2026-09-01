-- DEV ONLY. Promotes an existing auth user to 'admin' role.
--
-- Unlike the phone-OTP test users (dev-seed-second-test-user.sql), manually
-- crafting an email/password auth.users row directly in SQL does NOT
-- reliably work for password-grant login — GoTrue's login path touches
-- more of its internal schema than OTP verification does (at minimum a
-- matching auth.identities row; there may be more), and it returned a
-- generic 500 "Database error querying schema" when attempted here rather
-- than a clear cause. The reliable way to create a real admin account is
-- via the Supabase Dashboard (Authentication -> Users -> Add User) or the
-- Admin API with the service-role key — both go through GoTrue's own
-- code paths instead of guessing at its internal schema.
--
-- Usage: create the user via the Dashboard first, then run this with their
-- email substituted in.
update public.users
set role = 'admin'
where email = 'REPLACE_WITH_ADMIN_EMAIL';
