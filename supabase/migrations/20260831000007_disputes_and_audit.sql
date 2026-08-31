create table public.disputes (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id),
  customer_id uuid not null references public.users(id),
  provider_id uuid not null references public.provider_profiles(id),
  reason text not null,
  description text,
  status text not null default 'open' check (status in ('open', 'under_review', 'resolved', 'rejected')),
  resolution text,
  resolved_by uuid references public.users(id),
  resolved_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_disputes_booking on public.disputes(booking_id);
create index idx_disputes_status on public.disputes(status);

create trigger trg_disputes_updated_at
  before update on public.disputes
  for each row execute function public.set_updated_at();

-- Append-only. Written by triggers/backend functions, never edited by users.
create table public.audit_logs (
  id uuid primary key default gen_random_uuid(),
  user_id uuid references public.users(id),
  action text not null,
  entity_type text not null,
  entity_id uuid,
  metadata jsonb,
  created_at timestamptz not null default now()
);

create index idx_audit_logs_entity on public.audit_logs(entity_type, entity_id);
create index idx_audit_logs_user on public.audit_logs(user_id);
create index idx_audit_logs_created_at on public.audit_logs(created_at);
