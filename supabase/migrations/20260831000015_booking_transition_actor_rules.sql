-- The original trigger (20260831000004) validated which status VALUES are
-- reachable from which, but not WHO may make a given transition. As written,
-- a customer could set their own booking straight to 'accepted' — only the
-- assigned provider should be able to do that. This replaces the same
-- trigger function with actor-role checks added; the existing trigger
-- attachment doesn't need to change since it already points at this
-- function by name.
create or replace function public.validate_booking_status_transition()
returns trigger
language plpgsql
as $$
declare
  allowed_next text[];
  is_customer boolean;
  is_provider boolean;
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

    is_customer := (auth.uid() = new.customer_id);
    is_provider := public.owns_provider_profile(new.provider_id);

    -- Admins (Phase 10, dispute resolution) may force any transition.
    if not public.is_admin() then
      if new.status in ('accepted', 'declined', 'on_the_way', 'in_progress', 'completed')
         and not is_provider then
        raise exception 'Only the assigned provider may set status to %', new.status;
      end if;

      if new.status = 'cancelled' and not (is_customer or is_provider) then
        raise exception 'Only a participant in this booking may cancel it';
      end if;
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

-- Live status updates for the customer's Booking Tracking screen.
alter publication supabase_realtime add table public.bookings;
