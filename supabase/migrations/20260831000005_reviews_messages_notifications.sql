-- One review per booking. The trigger below is the authoritative check that
-- only the customer of a COMPLETED booking may create it; RLS adds a second,
-- coarser layer on top (defense in depth), see 20260831000009_rls_policies.sql.
create table public.reviews (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null unique references public.bookings(id) on delete cascade,
  customer_id uuid not null references public.users(id),
  provider_id uuid not null references public.provider_profiles(id),
  rating smallint not null check (rating between 1 and 5),
  comment text,
  provider_response text,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_reviews_provider on public.reviews(provider_id);

create trigger trg_reviews_updated_at
  before update on public.reviews
  for each row execute function public.set_updated_at();

create or replace function public.validate_review_eligibility()
returns trigger
language plpgsql
as $$
declare
  v_booking public.bookings;
begin
  select * into v_booking from public.bookings where id = new.booking_id;

  if v_booking is null then
    raise exception 'Booking % does not exist', new.booking_id;
  end if;

  if v_booking.status <> 'completed' then
    raise exception 'Only completed bookings may be reviewed';
  end if;

  if v_booking.customer_id <> new.customer_id or v_booking.provider_id <> new.provider_id then
    raise exception 'Review customer/provider must match the booking';
  end if;

  return new;
end;
$$;

create trigger trg_reviews_validate_eligibility
  before insert on public.reviews
  for each row execute function public.validate_review_eligibility();

-- Keep provider_profiles.rating / review_count in sync with reviews so
-- search/sort never has to aggregate reviews at query time.
create or replace function public.recalculate_provider_rating()
returns trigger
language plpgsql
as $$
declare
  v_provider_id uuid := coalesce(new.provider_id, old.provider_id);
begin
  update public.provider_profiles p
  set rating = coalesce((select round(avg(r.rating)::numeric, 2) from public.reviews r where r.provider_id = v_provider_id), 0),
      review_count = (select count(*) from public.reviews r where r.provider_id = v_provider_id)
  where p.id = v_provider_id;
  return null;
end;
$$;

create trigger trg_reviews_recalculate_rating
  after insert or update or delete on public.reviews
  for each row execute function public.recalculate_provider_rating();

-- Chat, scoped to a booking. sender/receiver must be the booking's customer
-- and provider (enforced by RLS, since it needs a cross-table check).
create table public.messages (
  id uuid primary key default gen_random_uuid(),
  booking_id uuid not null references public.bookings(id) on delete cascade,
  sender_id uuid not null references public.users(id),
  receiver_id uuid not null references public.users(id),
  message text,
  message_type text not null default 'text' check (message_type in ('text', 'image')),
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_messages_booking on public.messages(booking_id);
create index idx_messages_receiver_unread on public.messages(receiver_id, is_read);

create table public.notifications (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  title text not null,
  body text not null,
  notification_type text not null,
  reference_id uuid,
  is_read boolean not null default false,
  created_at timestamptz not null default now()
);

create index idx_notifications_user_unread on public.notifications(user_id, is_read);

create table public.favorites (
  id uuid primary key default gen_random_uuid(),
  customer_id uuid not null references public.users(id) on delete cascade,
  provider_id uuid not null references public.provider_profiles(id) on delete cascade,
  created_at timestamptz not null default now(),
  constraint uq_favorite unique (customer_id, provider_id)
);

create index idx_favorites_customer on public.favorites(customer_id);
