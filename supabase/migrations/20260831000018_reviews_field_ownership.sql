-- The Phase 1 `reviews_provider_respond` RLS policy lets a provider UPDATE
-- their own review row with no column restriction — meaning a provider
-- could currently overwrite the customer's rating or comment, not just add
-- a response. RLS alone can't express "this actor may only touch this one
-- column" (Postgres RLS is row-level, not column-level), so — same pattern
-- as the booking actor-authorization fix in Phase 6 — a trigger enforces it.
create or replace function public.guard_review_field_ownership()
returns trigger
language plpgsql
as $$
declare
  is_customer boolean;
  is_provider boolean;
begin
  if public.is_admin() then
    return new;
  end if;

  is_customer := (auth.uid() = new.customer_id);
  is_provider := public.owns_provider_profile(new.provider_id);

  if is_provider and not is_customer then
    if new.rating is distinct from old.rating
       or new.comment is distinct from old.comment
       or new.customer_id is distinct from old.customer_id
       or new.booking_id is distinct from old.booking_id
       or new.provider_id is distinct from old.provider_id then
      raise exception 'Providers may only update their response to a review';
    end if;
  elsif is_customer then
    if new.provider_response is distinct from old.provider_response then
      raise exception 'Only the provider may set a response to a review';
    end if;
  else
    raise exception 'Not authorized to update this review';
  end if;

  return new;
end;
$$;

create trigger trg_reviews_guard_field_ownership
  before update on public.reviews
  for each row execute function public.guard_review_field_ownership();
