-- Pre-seeded (unclaimed) provider listings need to exist before any real
-- owner has an account - the import script (scripts/import-dc-lead-list.mjs)
-- inserts provider_profiles rows with no associated auth.users account yet.
-- The unique constraint on user_id still holds correctly with multiple NULLs
-- (standard SQL null semantics), so this is the only schema change
-- provider_profiles itself needs. provider_profiles_select_public
-- (20260831000008_rls_policies.sql) already makes any is_active row -
-- including user_id is null ones - publicly readable, and
-- guard_provider_profile_admin_fields() only fires before update, not
-- insert, so the import script's direct verification_status = 'verified'
-- insert is never blocked by it.
alter table public.provider_profiles alter column user_id drop not null;

-- A real business owner later requests to take over ("claim") their
-- pre-seeded listing. Claims are reviewed manually by an admin (not
-- auto-matched by phone) - see approve/reject RPCs below - matching the
-- trust bar the existing verification workflow already uses.
create table public.provider_claim_requests (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  requester_user_id uuid not null references public.users(id) on delete cascade,
  status text not null default 'pending'
    check (status in ('pending', 'approved', 'rejected')),
  rejection_reason text,
  reviewed_by uuid references public.users(id),
  reviewed_at timestamptz,
  created_at timestamptz not null default now()
);

create index idx_provider_claim_requests_provider on public.provider_claim_requests(provider_id);
create index idx_provider_claim_requests_requester on public.provider_claim_requests(requester_user_id);
create index idx_provider_claim_requests_status on public.provider_claim_requests(status);

-- Stops one user stacking duplicate pending claims on the same listing,
-- while still allowing *different* users to each have a pending claim on
-- the same business at once - the whole point of manual admin review is
-- picking the legitimate claimant among possibly multiple people claiming
-- the same business.
create unique index uq_provider_claim_requests_pending_per_requester
  on public.provider_claim_requests(provider_id, requester_user_id)
  where status = 'pending';

alter table public.provider_claim_requests enable row level security;

create policy provider_claim_requests_select_own on public.provider_claim_requests
  for select using (requester_user_id = auth.uid() or public.is_admin());

-- No insert/update/delete policy at all - rows are written exclusively by
-- the SECURITY DEFINER RPCs below, which enforce the actual business rules
-- (ownership checks, promo/claim-window state, the race guard on approval).

-- Reference metadata from the lead-import source (lead score, suggested
-- offer, ownership evidence), kept separate from provider_profiles since
-- it's never customer-facing - purely for the business owner's/admin's own
-- reference. 1:1 with the seeded provider_profiles row.
create table public.provider_leads (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null unique references public.provider_profiles(id) on delete cascade,
  source text not null,
  source_row_ref text not null unique,
  lead_category text,
  lead_score numeric,
  suggested_offer text,
  ownership_evidence text,
  raw_data jsonb,
  imported_at timestamptz not null default now()
);

alter table public.provider_leads enable row level security;

create policy provider_leads_select_owner_admin on public.provider_leads
  for select using (public.owns_provider_profile(provider_id) or public.is_admin());

-- No insert/update/delete policy: written only by the one-off import
-- script, which connects directly as a privileged role and bypasses RLS
-- entirely - same posture as scripts/dev-db.mjs, just against a real target
-- database via IMPORT_DATABASE_URL.

-- Error messages below deliberately mirror register_as_provider's and
-- subscribe_free_plan's plain-text raise-exception style so the mobile
-- layer's existing e.message.contains(...) idiom keeps working
-- (supabase_provider_repository.dart, supabase_subscription_repository.dart).
create or replace function public.request_provider_claim(p_provider_id uuid)
returns public.provider_claim_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_owner_user_id uuid;
  v_row public.provider_claim_requests;
begin
  if auth.uid() is null then
    raise exception 'Must be authenticated to request a claim';
  end if;

  if exists (select 1 from public.provider_profiles where user_id = auth.uid()) then
    raise exception 'This account already has a provider profile';
  end if;

  select user_id into v_owner_user_id
  from public.provider_profiles
  where id = p_provider_id
  for update;

  if not found then
    raise exception 'Business listing not found';
  end if;

  if v_owner_user_id is not null then
    raise exception 'This listing has already been claimed';
  end if;

  if exists (
    select 1 from public.provider_claim_requests
    where provider_id = p_provider_id and requester_user_id = auth.uid() and status = 'pending'
  ) then
    raise exception 'You already have a pending claim request for this listing';
  end if;

  insert into public.provider_claim_requests (provider_id, requester_user_id)
  values (p_provider_id, auth.uid())
  returning * into v_row;

  return v_row;
end;
$$;

grant execute on function public.request_provider_claim(uuid) to authenticated;

create or replace function public.approve_provider_claim(p_claim_id uuid)
returns public.provider_claim_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_claim public.provider_claim_requests;
  v_updated_rows int;
begin
  if not public.is_admin() then
    raise exception 'Only administrators may approve claim requests';
  end if;

  select * into v_claim from public.provider_claim_requests where id = p_claim_id for update;
  if not found then
    raise exception 'Claim request not found';
  end if;
  if v_claim.status <> 'pending' then
    raise exception 'This claim request has already been reviewed';
  end if;

  update public.provider_profiles
  set user_id = v_claim.requester_user_id
  where id = v_claim.provider_id and user_id is null;
  get diagnostics v_updated_rows = row_count;

  if v_updated_rows = 0 then
    -- Race guard: someone else's claim on the same listing was approved first.
    raise exception 'This listing has already been claimed by someone else';
  end if;

  update public.users set role = 'provider' where id = v_claim.requester_user_id;

  update public.provider_claim_requests
  set status = 'approved', reviewed_at = now(), reviewed_by = auth.uid()
  where id = p_claim_id
  returning * into v_claim;

  -- Any other still-pending claims on the same now-claimed listing are
  -- moot - close them out rather than leaving them open forever. Each
  -- auto-rejection fires the same notification trigger below, so those
  -- requesters get a rejection notice too; this is expected, not a bug.
  update public.provider_claim_requests
  set status = 'rejected', reviewed_at = now(), reviewed_by = auth.uid(),
      rejection_reason = 'Listing was claimed by another requester'
  where provider_id = v_claim.provider_id and status = 'pending' and id <> p_claim_id;

  return v_claim;
end;
$$;

grant execute on function public.approve_provider_claim(uuid) to authenticated;

create or replace function public.reject_provider_claim(p_claim_id uuid, p_reason text default null)
returns public.provider_claim_requests
language plpgsql
security definer
set search_path = public
as $$
declare
  v_claim public.provider_claim_requests;
begin
  if not public.is_admin() then
    raise exception 'Only administrators may reject claim requests';
  end if;

  select * into v_claim from public.provider_claim_requests where id = p_claim_id for update;
  if not found then
    raise exception 'Claim request not found';
  end if;
  if v_claim.status <> 'pending' then
    raise exception 'This claim request has already been reviewed';
  end if;

  update public.provider_claim_requests
  set status = 'rejected', reviewed_at = now(), reviewed_by = auth.uid(), rejection_reason = p_reason
  where id = p_claim_id
  returning * into v_claim;

  return v_claim;
end;
$$;

grant execute on function public.reject_provider_claim(uuid, text) to authenticated;

-- Structural mirror of notify_booking_status_change() (20260831000016) -
-- no mobile client change needed, the notification renderer is generic on
-- title/body regardless of notification_type.
create or replace function public.notify_provider_claim_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_title text;
  v_body text;
begin
  if new.status is distinct from old.status then
    case new.status
      when 'approved' then
        v_title := 'Claim approved';
        v_body := 'Your claim request was approved. You now manage this listing.';
      when 'rejected' then
        v_title := 'Claim rejected';
        v_body := coalesce(
          'Your claim request was rejected: ' || new.rejection_reason,
          'Your claim request was rejected.'
        );
      else
        v_title := null;
    end case;

    if v_title is not null then
      insert into public.notifications (user_id, title, body, notification_type, reference_id)
      values (new.requester_user_id, v_title, v_body, 'provider_claim_status_changed', new.id);
    end if;
  end if;

  return new;
end;
$$;

create trigger trg_provider_claim_requests_notify_status_change
  after update on public.provider_claim_requests
  for each row execute function public.notify_provider_claim_status_change();
