-- 20260831000019's fix was wrong: it assumed `current_user` diverges from
-- `session_user` specifically during SECURITY DEFINER execution, but under
-- Supabase's actual PostgREST connection model (a fixed `authenticator`
-- login role, with `SET LOCAL ROLE authenticated` — or anon/service_role —
-- issued per request), `session_user` is *always* `authenticator`, so
-- `current_user <> session_user` is true for every ordinary authenticated
-- request too, not just SECURITY DEFINER cascades. That would have made the
-- admin-fields guard never fire at all for real client requests — the
-- opposite of the previous bug, and worse. Caught this by reasoning through
-- the actual connection model rather than re-testing against this
-- migration's own direct superuser connection, which can't distinguish the
-- two cases either way (verified: session_user is 'postgres' either way
-- here, so the previous fix appeared to still fail in dev-db testing, which
-- is what prompted this correction).
--
-- Proper fix: an explicit, transaction-local flag that the trusted cascade
-- sets immediately before its update and clears immediately after. No
-- reliance on role-switching semantics at all.
create or replace function public.recalculate_provider_rating()
returns trigger
language plpgsql
security definer
set search_path = public
as $$
declare
  v_provider_id uuid := coalesce(new.provider_id, old.provider_id);
begin
  perform set_config('app.internal_rating_update', 'true', true);

  update public.provider_profiles p
  set rating = coalesce((select round(avg(r.rating)::numeric, 2) from public.reviews r where r.provider_id = v_provider_id), 0),
      review_count = (select count(*) from public.reviews r where r.provider_id = v_provider_id)
  where p.id = v_provider_id;

  perform set_config('app.internal_rating_update', 'false', true);
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
     and coalesce(current_setting('app.internal_rating_update', true), 'false') <> 'true' then
    raise exception 'Only administrators may change verification status or rating fields';
  end if;
  return new;
end;
$$;
