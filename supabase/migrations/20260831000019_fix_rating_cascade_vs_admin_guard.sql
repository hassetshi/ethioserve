-- Bug found via live testing while building Phase 9: a customer submitting
-- a review (a perfectly legitimate, RLS-validated action) cascades into
-- recalculate_provider_rating(), which UPDATEs provider_profiles.rating —
-- and that UPDATE was being rejected by guard_provider_profile_admin_fields()
-- (Phase 1), because that guard checks is_admin() against the CURRENT
-- auth.uid(), which during a customer's request is the customer, not an
-- admin. The guard can't tell "a customer directly editing their own
-- provider_profiles row" apart from "a trusted system trigger cascading an
-- update as a side effect of a totally different, already-validated action."
--
-- Fix: make the cascade run as a SECURITY DEFINER function (so Postgres's
-- `current_user` becomes the function owner during the cascade, while
-- `session_user` stays 'authenticated' throughout — these two only diverge
-- inside an elevated/SECURITY DEFINER context), and let the guard trust any
-- update happening in such a context.
create or replace function public.recalculate_provider_rating()
returns trigger
language plpgsql
security definer
set search_path = public
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

create or replace function public.guard_provider_profile_admin_fields()
returns trigger
language plpgsql
as $$
begin
  if (new.verification_status is distinct from old.verification_status
      or new.verification_date is distinct from old.verification_date
      or new.rating is distinct from old.rating
      or new.review_count is distinct from old.review_count)
     and not public.is_admin()
     and current_user = session_user then
    raise exception 'Only administrators may change verification status or rating fields';
  end if;
  return new;
end;
$$;
