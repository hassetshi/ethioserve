-- Device tokens for push delivery (spec section 21). Kept as its own table
-- (not a column on users) since a user may have multiple devices.
create table public.device_tokens (
  id uuid primary key default gen_random_uuid(),
  user_id uuid not null references public.users(id) on delete cascade,
  token text not null unique,
  platform text not null check (platform in ('android', 'ios', 'web')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now()
);

create index idx_device_tokens_user on public.device_tokens(user_id);

alter table public.device_tokens enable row level security;

create policy device_tokens_manage_own on public.device_tokens
  for all using (user_id = auth.uid()) with check (user_id = auth.uid());

create trigger trg_device_tokens_updated_at
  before update on public.device_tokens
  for each row execute function public.set_updated_at();

-- Notification rows are generated server-side from booking events, never
-- by the client — this is what spec section 21's "use a notification
-- abstraction" is for on the client side, but the *decision* to notify
-- someone belongs here, so it happens consistently regardless of which
-- client (or Edge Function, later) touched the booking.
create or replace function public.notify_new_booking()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_provider_user_id uuid;
begin
  select user_id into v_provider_user_id
  from public.provider_profiles where id = new.provider_id;

  insert into public.notifications (user_id, title, body, notification_type, reference_id)
  values (
    v_provider_user_id,
    'New booking request',
    'You have a new booking request.',
    'booking_requested',
    new.id
  );

  return new;
end;
$$;

create trigger trg_bookings_notify_new_booking
  after insert on public.bookings
  for each row execute function public.notify_new_booking();

create or replace function public.notify_booking_status_change()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_provider_user_id uuid;
  v_title text;
  v_body text;
  v_notify_user_id uuid;
begin
  if new.status is distinct from old.status then
    select user_id into v_provider_user_id
    from public.provider_profiles where id = new.provider_id;

    case new.status
      when 'accepted' then
        v_notify_user_id := new.customer_id;
        v_title := 'Booking accepted';
        v_body := 'Your booking request was accepted.';
      when 'declined' then
        v_notify_user_id := new.customer_id;
        v_title := 'Booking declined';
        v_body := 'Your booking request was declined.';
      when 'on_the_way' then
        v_notify_user_id := new.customer_id;
        v_title := 'Provider is on the way';
        v_body := 'Your provider is on the way to your address.';
      when 'completed' then
        v_notify_user_id := new.customer_id;
        v_title := 'Booking completed';
        v_body := 'Your booking is complete. Leave a review to let others know how it went.';
      when 'cancelled' then
        -- Notify whichever participant did NOT make the change.
        v_notify_user_id := case
          when auth.uid() = new.customer_id then v_provider_user_id
          else new.customer_id
        end;
        v_title := 'Booking cancelled';
        v_body := 'A booking was cancelled.';
      else
        v_notify_user_id := null;
    end case;

    if v_notify_user_id is not null then
      insert into public.notifications (user_id, title, body, notification_type, reference_id)
      values (v_notify_user_id, v_title, v_body, 'booking_status_changed', new.id);
    end if;
  end if;

  return new;
end;
$$;

create trigger trg_bookings_notify_status_change
  after update on public.bookings
  for each row execute function public.notify_booking_status_change();

-- Live unread-count badge in the app.
alter publication supabase_realtime add table public.notifications;
