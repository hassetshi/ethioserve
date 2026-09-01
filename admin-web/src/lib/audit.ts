import { supabase } from './supabase'

// Writes to audit_logs via the log_admin_action RPC (see
// supabase/migrations/20260901000022_admin_audit_log_rpc.sql) — audit_logs
// itself has no client insert policy, by design, so this RPC is the only
// path available to admin-web. Best-effort: a logging failure shouldn't
// block the admin action that already succeeded, so failures are reported
// to the console rather than surfaced in the UI or re-thrown.
export async function logAdminAction(
  action: string,
  entityType: string,
  entityId?: string,
  metadata?: Record<string, unknown>,
) {
  const { error } = await supabase.rpc('log_admin_action', {
    p_action: action,
    p_entity_type: entityType,
    p_entity_id: entityId ?? null,
    p_metadata: metadata ?? null,
  })
  if (error) {
    console.error('Failed to write audit log entry', { action, entityType, entityId, error })
  }
}
