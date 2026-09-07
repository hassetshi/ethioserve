-- Phase 16: admin-web has no way to write to audit_logs today. The table's
-- own RLS deliberately has no client insert policy (see
-- 20260831000008_rls_policies.sql's comment: "written only by SECURITY
-- DEFINER trigger functions and backend/Edge Functions using the
-- service-role key") so that a compromised admin session can't tamper with
-- its own audit trail via a direct table write. This RPC is the sanctioned
-- path: it re-checks is_admin() itself rather than trusting the caller, and
-- always stamps user_id from auth.uid() rather than trusting a client-supplied
-- value.
--
-- Note: `grant execute ... to authenticated` below does NOT revoke anon's
-- access - Postgres grants EXECUTE to PUBLIC by default on function
-- creation, and every role implicitly includes PUBLIC. Verified live: an
-- anon call reaches the function body and is rejected by the is_admin()
-- check (P0001), not by a permission-denied error from the grant system.
-- That's an acceptable, intentional defense-in-depth layer, not the actual
-- boundary - same pattern as every other role-gated RPC in this schema
-- (e.g. register_as_provider).
create or replace function public.log_admin_action(
  p_action text,
  p_entity_type text,
  p_entity_id uuid default null,
  p_metadata jsonb default null
)
returns uuid
language plpgsql
security definer
set search_path = public
as $$
declare
  v_log_id uuid;
begin
  if not public.is_admin() then
    raise exception 'Only admins may write audit log entries';
  end if;

  insert into public.audit_logs (user_id, action, entity_type, entity_id, metadata)
  values (auth.uid(), p_action, p_entity_type, p_entity_id, p_metadata)
  returning id into v_log_id;

  return v_log_id;
end;
$$;

grant execute on function public.log_admin_action(text, text, uuid, jsonb) to authenticated;
