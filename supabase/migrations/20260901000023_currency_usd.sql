-- Product pivot: initial market is Ethiopian-American businesses/customers
-- in the US (not Ethiopia itself), so payments need to be in USD. The
-- original CHECK constraints hard-locked currency to 'ETB' at the DB layer
-- (supabase/migrations/20260831000006_payments_subscriptions_ads.sql), which
-- is exactly the kind of assumption that's cheap to fix now and expensive to
-- discover in production. Constraint names are looked up dynamically rather
-- than assumed, since they were never explicitly named in the original
-- migration (Postgres auto-generates names for inline column checks).
do $$
declare
  con record;
begin
  for con in
    select conname from pg_constraint
    where conrelid = 'public.payments'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%currency%ETB%'
  loop
    execute format('alter table public.payments drop constraint %I', con.conname);
  end loop;

  for con in
    select conname from pg_constraint
    where conrelid = 'public.subscriptions'::regclass
      and contype = 'c'
      and pg_get_constraintdef(oid) ilike '%currency%ETB%'
  loop
    execute format('alter table public.subscriptions drop constraint %I', con.conname);
  end loop;
end $$;

-- Convert any existing ETB rows before the new constraint forbids them.
-- Values are amount-agnostic (calculate_commission does plain numeric math
-- regardless of currency label) so this only changes the label, not the
-- amounts - acceptable for a pre-launch pivot with no real payment history.
update public.payments set currency = 'USD' where currency = 'ETB';
update public.subscriptions set currency = 'USD' where currency = 'ETB';

alter table public.payments alter column currency set default 'USD';
alter table public.payments add constraint payments_currency_check check (currency = 'USD');

alter table public.subscriptions alter column currency set default 'USD';
alter table public.subscriptions add constraint subscriptions_currency_check check (currency = 'USD');

-- record_cash_payment() hard-coded the 'ETB' literal directly in its INSERT.
create or replace function public.record_cash_payment(p_booking_id uuid)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_booking public.bookings;
  v_platform_fee numeric;
  v_provider_amount numeric;
  v_payment_id uuid;
begin
  select * into v_booking from public.bookings where id = p_booking_id;

  if v_booking is null then
    raise exception 'Booking % does not exist', p_booking_id;
  end if;

  if not public.owns_provider_profile(v_booking.provider_id) then
    raise exception 'Only the assigned provider may record a cash payment for this booking';
  end if;

  if v_booking.status <> 'completed' then
    raise exception 'Only completed bookings can be marked as paid';
  end if;

  if v_booking.final_price is null then
    raise exception 'This booking has no final price set yet';
  end if;

  if exists (select 1 from public.payments where booking_id = p_booking_id) then
    raise exception 'This booking already has a payment record';
  end if;

  select platform_fee, provider_amount
    into v_platform_fee, v_provider_amount
    from public.calculate_commission(v_booking.final_price);

  insert into public.payments (
    booking_id, customer_id, provider_id, amount, platform_fee, provider_amount,
    currency, payment_provider, status, paid_at
  ) values (
    p_booking_id, v_booking.customer_id, v_booking.provider_id, v_booking.final_price,
    v_platform_fee, v_provider_amount, 'USD', 'cash', 'completed', now()
  )
  returning id into v_payment_id;

  return v_payment_id;
end;
$$;

grant execute on function public.record_cash_payment(uuid) to authenticated;
