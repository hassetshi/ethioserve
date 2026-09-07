-- Commission is data (platform_settings.booking_commission_rate), never a
-- hard-coded constant (spec section 23: "Do not hard-code 10%"). Centralizing
-- the split calculation here means every payment path (cash now, a real
-- digital provider later) computes it identically.
create or replace function public.calculate_commission(p_amount numeric)
returns table (platform_fee numeric, provider_amount numeric)
language sql
stable
as $$
  select
    round(p_amount * rate, 2) as platform_fee,
    round(p_amount * (1 - rate), 2) as provider_amount
  from (
    select coalesce(
      (select (value #>> '{}')::numeric from public.platform_settings where key = 'booking_commission_rate'),
      0.10
    ) as rate
  ) r;
$$;

-- At most one payment record per booking.
alter table public.payments add constraint uq_payments_booking unique (booking_id);

-- Cash is a real, working payment path today (spec section 20: "Architecture
-- must support: Cash, Digital payment, Platform commission" — cash needs no
-- external provider to be genuinely functional, unlike digital payment
-- which is architecture-only until a provider is configured). Only the
-- assigned provider may record having been paid in cash, and only for a
-- completed booking — the amount and commission split are computed
-- server-side from the booking's final_price, never taken from the client.
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
    v_platform_fee, v_provider_amount, 'ETB', 'cash', 'completed', now()
  )
  returning id into v_payment_id;

  return v_payment_id;
end;
$$;

grant execute on function public.record_cash_payment(uuid) to authenticated;
grant execute on function public.calculate_commission(numeric) to authenticated;
