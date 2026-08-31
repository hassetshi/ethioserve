-- Payments are never written directly by the mobile client. Rows are created
-- and transitioned exclusively by trusted server code (Edge Functions using
-- the service-role key, after verifying the payment provider's webhook/API
-- response) -- see PaymentService in ARCHITECTURE.md and the RLS policies in
-- 20260831000009_rls_policies.sql, which grant clients read-only access.
create table public.payments (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id),
  customer_id uuid not null references public.users(id),
  provider_id uuid not null references public.provider_profiles(id),
  amount numeric(12, 2) not null check (amount >= 0),
  platform_fee numeric(12, 2) not null default 0 check (platform_fee >= 0),
  provider_amount numeric(12, 2) not null check (provider_amount >= 0),
  currency text not null default 'ETB' check (currency = 'ETB'),
  payment_provider text,
  transaction_reference text,
  status text not null default 'pending'
    check (status in ('pending', 'processing', 'completed', 'failed', 'refunded', 'cancelled')),
  paid_at timestamptz,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_payments_booking on public.payments(booking_id);
create index idx_payments_status on public.payments(status);

create trigger trg_payments_updated_at
  before update on public.payments
  for each row execute function public.set_updated_at();

create table public.subscriptions (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  plan text not null default 'free' check (plan in ('free', 'professional', 'premium')),
  price numeric(12, 2) not null default 0 check (price >= 0),
  currency text not null default 'ETB' check (currency = 'ETB'),
  start_date date not null default current_date,
  end_date date,
  status text not null default 'active' check (status in ('active', 'expired', 'cancelled')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_subscriptions_provider on public.subscriptions(provider_id);
create index idx_subscriptions_status on public.subscriptions(status);

create trigger trg_subscriptions_updated_at
  before update on public.subscriptions
  for each row execute function public.set_updated_at();

create table public.advertisements (
  id uuid primary key default gen_random_uuid(),
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  title text not null,
  description text,
  image text,
  start_date date not null,
  end_date date not null,
  budget numeric(12, 2) check (budget >= 0),
  status text not null default 'pending'
    check (status in ('pending', 'active', 'paused', 'completed', 'rejected')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint chk_advertisement_dates check (end_date >= start_date)
);

create index idx_advertisements_provider on public.advertisements(provider_id);
create index idx_advertisements_status on public.advertisements(status);

create trigger trg_advertisements_updated_at
  before update on public.advertisements
  for each row execute function public.set_updated_at();
