-- =============================================================================
-- Role/ownership helper functions
--
-- SECURITY DEFINER is required here: a policy on, say, `bookings` that calls
-- is_admin() must be able to read the caller's own row in `public.users`
-- regardless of the RLS state of that table at evaluation time, without
-- granting the caller any broader access. Each function is narrowly scoped
-- to a single boolean/exists check and search_path is pinned to prevent
-- hijacking via a malicious search_path.
-- =============================================================================

create or replace function public.is_admin()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users where id = auth.uid() and role = 'admin'
  );
$$;

create or replace function public.is_provider()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.users where id = auth.uid() and role = 'provider'
  );
$$;

create or replace function public.owns_provider_profile(p_provider_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.provider_profiles
    where id = p_provider_id and user_id = auth.uid()
  );
$$;

create or replace function public.is_booking_participant(p_booking_id uuid)
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select exists (
    select 1 from public.bookings b
    left join public.provider_profiles pp on pp.id = b.provider_id
    where b.id = p_booking_id
      and (b.customer_id = auth.uid() or pp.user_id = auth.uid())
  );
$$;

grant execute on function public.is_admin() to authenticated;
grant execute on function public.is_provider() to authenticated;
grant execute on function public.owns_provider_profile(uuid) to authenticated;
grant execute on function public.is_booking_participant(uuid) to authenticated;

-- Attach the admin-fields guard defined in the previous migration now that
-- is_admin() exists.
create trigger trg_provider_profiles_guard_admin_fields
  before update on public.provider_profiles
  for each row execute function public.guard_provider_profile_admin_fields();

-- =============================================================================
-- Enable RLS everywhere. Nothing is readable/writable by default; every
-- table below gets an explicit allow-list of policies.
-- =============================================================================
alter table public.users enable row level security;
alter table public.profiles enable row level security;
alter table public.provider_profiles enable row level security;
alter table public.categories enable row level security;
alter table public.services enable row level security;
alter table public.provider_services enable row level security;
alter table public.provider_availability enable row level security;
alter table public.provider_photos enable row level security;
alter table public.provider_documents enable row level security;
alter table public.bookings enable row level security;
alter table public.booking_status_history enable row level security;
alter table public.reviews enable row level security;
alter table public.messages enable row level security;
alter table public.notifications enable row level security;
alter table public.favorites enable row level security;
alter table public.payments enable row level security;
alter table public.subscriptions enable row level security;
alter table public.advertisements enable row level security;
alter table public.disputes enable row level security;
alter table public.audit_logs enable row level security;
alter table public.cities enable row level security;
alter table public.languages enable row level security;
alter table public.platform_settings enable row level security;

-- ---------------------------------------------------------------- users ----
create policy users_select_own on public.users
  for select using (id = auth.uid() or public.is_admin());

create policy users_update_own on public.users
  for update using (id = auth.uid() or public.is_admin())
  with check (
    id = auth.uid() and role = (select role from public.users where id = auth.uid())
    or public.is_admin()
  );

create policy users_admin_all on public.users
  for all using (public.is_admin()) with check (public.is_admin());

-- -------------------------------------------------------------- profiles ---
create policy profiles_select_own on public.profiles
  for select using (user_id = auth.uid() or public.is_admin());

create policy profiles_select_public_provider on public.profiles
  for select using (
    exists (
      select 1 from public.provider_profiles pp
      where pp.user_id = profiles.user_id and pp.is_active
    )
  );

create policy profiles_write_own on public.profiles
  for insert with check (user_id = auth.uid());

create policy profiles_update_own on public.profiles
  for update using (user_id = auth.uid() or public.is_admin());

-- ----------------------------------------------------- provider_profiles ---
create policy provider_profiles_select_public on public.provider_profiles
  for select using (is_active or user_id = auth.uid() or public.is_admin());

create policy provider_profiles_insert_own on public.provider_profiles
  for insert with check (user_id = auth.uid());

create policy provider_profiles_update_own on public.provider_profiles
  for update using (user_id = auth.uid() or public.is_admin());

create policy provider_profiles_admin_all on public.provider_profiles
  for all using (public.is_admin()) with check (public.is_admin());

-- ------------------------------------------------- categories / services ---
create policy categories_select_active on public.categories
  for select using (is_active or public.is_admin());

create policy categories_admin_write on public.categories
  for insert with check (public.is_admin());
create policy categories_admin_update on public.categories
  for update using (public.is_admin());
create policy categories_admin_delete on public.categories
  for delete using (public.is_admin());

create policy services_select_active on public.services
  for select using (is_active or public.is_admin());
create policy services_admin_write on public.services
  for insert with check (public.is_admin());
create policy services_admin_update on public.services
  for update using (public.is_admin());
create policy services_admin_delete on public.services
  for delete using (public.is_admin());

-- ------------------------------------------------------- cities/languages --
create policy cities_select_active on public.cities
  for select using (is_active or public.is_admin());
create policy cities_admin_write on public.cities
  for all using (public.is_admin()) with check (public.is_admin());

create policy languages_select_active on public.languages
  for select using (is_active or public.is_admin());
create policy languages_admin_write on public.languages
  for all using (public.is_admin()) with check (public.is_admin());

-- ------------------------------------------------------- platform_settings-
create policy platform_settings_admin_only on public.platform_settings
  for all using (public.is_admin()) with check (public.is_admin());

-- ----------------------------------------------------- provider_services ---
create policy provider_services_select_public on public.provider_services
  for select using (
    exists (select 1 from public.provider_profiles p where p.id = provider_id and p.is_active)
    or public.owns_provider_profile(provider_id)
    or public.is_admin()
  );

create policy provider_services_manage_own on public.provider_services
  for all
  using (public.owns_provider_profile(provider_id) or public.is_admin())
  with check (public.owns_provider_profile(provider_id) or public.is_admin());

-- ------------------------------------------------- provider_availability ---
create policy provider_availability_select_public on public.provider_availability
  for select using (
    exists (select 1 from public.provider_profiles p where p.id = provider_id and p.is_active)
    or public.owns_provider_profile(provider_id)
    or public.is_admin()
  );

create policy provider_availability_manage_own on public.provider_availability
  for all
  using (public.owns_provider_profile(provider_id) or public.is_admin())
  with check (public.owns_provider_profile(provider_id) or public.is_admin());

-- ------------------------------------------------------- provider_photos ---
create policy provider_photos_select_public on public.provider_photos
  for select using (
    exists (select 1 from public.provider_profiles p where p.id = provider_id and p.is_active)
    or public.owns_provider_profile(provider_id)
    or public.is_admin()
  );

create policy provider_photos_manage_own on public.provider_photos
  for all
  using (public.owns_provider_profile(provider_id) or public.is_admin())
  with check (public.owns_provider_profile(provider_id) or public.is_admin());

-- ----------------------------------------------------- provider_documents -
-- Sensitive: only the owning provider (upload/view own) and admins
-- (review/verify) may ever see these rows. Never publicly readable.
create policy provider_documents_select_owner_admin on public.provider_documents
  for select using (public.owns_provider_profile(provider_id) or public.is_admin());

create policy provider_documents_insert_owner on public.provider_documents
  for insert with check (public.owns_provider_profile(provider_id));

create policy provider_documents_admin_review on public.provider_documents
  for update using (public.is_admin()) with check (public.is_admin());

-- ------------------------------------------------------------- bookings ---
create policy bookings_select_participants on public.bookings
  for select using (
    customer_id = auth.uid()
    or public.owns_provider_profile(provider_id)
    or public.is_admin()
  );

create policy bookings_insert_customer on public.bookings
  for insert with check (customer_id = auth.uid());

-- Column-level restriction (e.g. "provider can only move status forward")
-- is enforced by trg_bookings_validate_status; this policy only gates WHO
-- may attempt an update at all.
create policy bookings_update_participants on public.bookings
  for update using (
    customer_id = auth.uid()
    or public.owns_provider_profile(provider_id)
    or public.is_admin()
  );

-- ---------------------------------------------------- booking_status_hist -
create policy booking_status_history_select_participants on public.booking_status_history
  for select using (public.is_booking_participant(booking_id) or public.is_admin());

-- No insert/update/delete policy: rows are written only by the
-- security-invoker trigger functions above, which run as the same
-- transaction as the (already-authorized) booking update/insert.

-- -------------------------------------------------------------- reviews ---
create policy reviews_select_all on public.reviews
  for select using (true);

create policy reviews_insert_customer_completed on public.reviews
  for insert with check (
    customer_id = auth.uid()
    and exists (
      select 1 from public.bookings b
      where b.id = booking_id and b.customer_id = auth.uid() and b.status = 'completed'
    )
  );

create policy reviews_update_own on public.reviews
  for update using (customer_id = auth.uid() or public.is_admin());

create policy reviews_provider_respond on public.reviews
  for update using (public.owns_provider_profile(provider_id))
  with check (public.owns_provider_profile(provider_id));

-- ------------------------------------------------------------- messages ---
create policy messages_select_participants on public.messages
  for select using (sender_id = auth.uid() or receiver_id = auth.uid() or public.is_admin());

create policy messages_insert_participants on public.messages
  for insert with check (
    sender_id = auth.uid() and public.is_booking_participant(booking_id)
  );

create policy messages_update_receiver_mark_read on public.messages
  for update using (receiver_id = auth.uid())
  with check (receiver_id = auth.uid());

-- --------------------------------------------------------- notifications -
create policy notifications_select_own on public.notifications
  for select using (user_id = auth.uid() or public.is_admin());

create policy notifications_update_own on public.notifications
  for update using (user_id = auth.uid())
  with check (user_id = auth.uid());

-- ------------------------------------------------------------ favorites --
create policy favorites_manage_own on public.favorites
  for all using (customer_id = auth.uid()) with check (customer_id = auth.uid());

-- ------------------------------------------------------------- payments --
-- Read-only for clients. All writes happen via Edge Functions using the
-- service-role key (which bypasses RLS entirely), never from the app.
create policy payments_select_participants on public.payments
  for select using (
    customer_id = auth.uid()
    or public.owns_provider_profile(provider_id)
    or public.is_admin()
  );

-- --------------------------------------------------------- subscriptions -
create policy subscriptions_select_own on public.subscriptions
  for select using (public.owns_provider_profile(provider_id) or public.is_admin());

create policy subscriptions_admin_write on public.subscriptions
  for all using (public.is_admin()) with check (public.is_admin());

-- ------------------------------------------------------- advertisements --
create policy advertisements_select_own_or_active on public.advertisements
  for select using (
    status = 'active' or public.owns_provider_profile(provider_id) or public.is_admin()
  );

create policy advertisements_manage_own on public.advertisements
  for insert with check (public.owns_provider_profile(provider_id));

create policy advertisements_update_own on public.advertisements
  for update using (public.owns_provider_profile(provider_id) or public.is_admin());

-- --------------------------------------------------------------disputes --
create policy disputes_select_participants on public.disputes
  for select using (
    customer_id = auth.uid()
    or public.owns_provider_profile(provider_id)
    or public.is_admin()
  );

create policy disputes_insert_participants on public.disputes
  for insert with check (
    (customer_id = auth.uid() or public.owns_provider_profile(provider_id))
    and public.is_booking_participant(booking_id)
  );

create policy disputes_admin_resolve on public.disputes
  for update using (public.is_admin()) with check (public.is_admin());

-- ------------------------------------------------------------audit_logs --
create policy audit_logs_admin_only on public.audit_logs
  for select using (public.is_admin());

-- No client insert/update/delete policy: written only by SECURITY DEFINER
-- trigger functions and backend/Edge Functions using the service-role key.
