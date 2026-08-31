-- Core booking record.
create table public.bookings (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.users(id),
  provider_id uuid not null references public.provider_profiles(id),
  service_id uuid not null references public.services(id),
  scheduled_date date not null,
  scheduled_time time not null,
  address text not null,
  latitude double precision,
  longitude double precision,
  description text,
  customer_notes text,
  provider_notes text,
  estimated_price numeric(12, 2) check (estimated_price >= 0),
  final_price numeric(12, 2) check (final_price >= 0),
  status text not null default 'requested'
    check (status in ('requested', 'accepted', 'on_the_way', 'in_progress', 'completed', 'declined', 'cancelled')),
  cancellation_reason text,
  completed_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_bookings_customer on public.bookings(customer_id);
create index idx_bookings_provider on public.bookings(provider_id);
create index idx_bookings_status on public.bookings(status);
create index idx_bookings_scheduled_date on public.bookings(scheduled_date);

create trigger trg_bookings_updated_at
  before update on public.bookings
  for each row execute function public.set_updated_at();

-- Immutable log of every status change, for support/dispute investigation.
create table public.booking_status_history (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  old_status text,
  new_status text not null,
  changed_by uuid references public.users(id),
  created_at timestamptz not null default now()
);

create index idx_booking_status_history_booking on public.booking_status_history(booking_id);

-- Server-side enforcement of the booking state machine (spec section 9/19):
--   requested   -> accepted | declined | cancelled
--   accepted    -> on_the_way | cancelled
--   on_the_way  -> in_progress | cancelled
--   in_progress -> completed | cancelled
--   completed / declined / cancelled are terminal.
-- The mobile/admin apps never write status transitions directly against
-- this invariant; this trigger is the single source of truth for it.
create or replace function public.validate_booking_status_transition()
returns trigger
language plpgsql
as $$
declare
  allowed_next text[];
begin
  if tg_op = 'UPDATE' and new.status is distinct from old.status then
    allowed_next := case old.status
      when 'requested' then array['accepted', 'declined', 'cancelled']
      when 'accepted' then array['on_the_way', 'cancelled']
      when 'on_the_way' then array['in_progress', 'cancelled']
      when 'in_progress' then array['completed', 'cancelled']
      else array[]::text[]
    end;

    if not (new.status = any (allowed_next)) then
      raise exception 'Invalid booking status transition: % -> %', old.status, new.status;
    end if;

    if new.status = 'completed' then
      new.completed_at = now();
    end if;

    insert into public.booking_status_history (booking_id, old_status, new_status, changed_by)
    values (new.id, old.status, new.status, auth.uid());
  end if;

  return new;
end;
$$;

create trigger trg_bookings_validate_status
  before update on public.bookings
  for each row execute function public.validate_booking_status_transition();

-- Record the initial 'requested' state too, so booking_status_history is a
-- complete timeline from creation, not just from the first transition.
create or replace function public.log_booking_initial_status()
returns trigger
language plpgsql
as $$
begin
  insert into public.booking_status_history (booking_id, old_status, new_status, changed_by)
  values (new.id, null, new.status, auth.uid());
  return new;
end;
$$;

create trigger trg_bookings_log_initial_status
  after insert on public.bookings
  for each row execute function public.log_booking_initial_status();
