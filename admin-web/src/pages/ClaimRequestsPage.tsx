import { useQuery, useQueryClient } from '@tanstack/react-query'
import { logAdminAction } from '../lib/audit'
import { supabase } from '../lib/supabase'

type ClaimRequestRow = {
  id: string
  status: string
  created_at: string
  rejection_reason: string | null
  provider_profiles: { business_name: string } | null
  users: { phone: string | null; email: string | null } | null
}

function StatusBadge({ status }: { status: string }) {
  const color =
    status === 'approved'
      ? 'bg-green-100 text-green-700'
      : status === 'rejected'
        ? 'bg-red-100 text-red-700'
        : 'bg-yellow-100 text-yellow-700'
  return <span className={`rounded px-2 py-0.5 text-xs capitalize ${color}`}>{status}</span>
}

export function ClaimRequestsPage() {
  const queryClient = useQueryClient()

  const { data, isLoading, error } = useQuery({
    queryKey: ['claim-requests'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('provider_claim_requests')
        .select(
          'id, status, created_at, rejection_reason, provider_profiles(business_name), users:requester_user_id(phone, email)',
        )
        .order('created_at', { ascending: false })
      if (error) throw error
      return data as unknown as ClaimRequestRow[]
    },
  })

  async function approve(claimId: string) {
    const { error } = await supabase.rpc('approve_provider_claim', { p_claim_id: claimId })
    if (error) {
      window.alert(error.message)
      return
    }
    await logAdminAction('claim.approved', 'provider_claim_requests', claimId)
    queryClient.invalidateQueries({ queryKey: ['claim-requests'] })
  }

  async function reject(claimId: string) {
    const reason = window.prompt('Reason for rejecting this claim (optional):') ?? undefined
    const { error } = await supabase.rpc('reject_provider_claim', {
      p_claim_id: claimId,
      p_reason: reason || null,
    })
    if (error) {
      window.alert(error.message)
      return
    }
    await logAdminAction('claim.rejected', 'provider_claim_requests', claimId)
    queryClient.invalidateQueries({ queryKey: ['claim-requests'] })
  }

  if (isLoading) return <p>Loading...</p>
  if (error) return <p className="text-red-600">Something went wrong. Please try again.</p>

  return (
    <div>
      <h1 className="mb-4 text-xl font-semibold">Claim requests</h1>
      <table className="w-full border-collapse text-sm">
        <thead>
          <tr className="border-b border-gray-200 text-left text-gray-500">
            <th className="py-2">Business</th>
            <th className="py-2">Requester</th>
            <th className="py-2">Requested</th>
            <th className="py-2">Status</th>
            <th className="py-2" />
          </tr>
        </thead>
        <tbody>
          {data?.map((claim) => (
            <tr key={claim.id} className="border-b border-gray-100">
              <td className="py-2">{claim.provider_profiles?.business_name ?? '—'}</td>
              <td className="py-2">{claim.users?.phone ?? claim.users?.email ?? '—'}</td>
              <td className="py-2">{new Date(claim.created_at).toLocaleDateString()}</td>
              <td className="py-2">
                <StatusBadge status={claim.status} />
                {claim.status === 'rejected' && claim.rejection_reason && (
                  <p className="mt-1 text-xs text-gray-500">{claim.rejection_reason}</p>
                )}
              </td>
              <td className="py-2">
                {claim.status === 'pending' && (
                  <div className="flex gap-2">
                    <button
                      onClick={() => approve(claim.id)}
                      className="rounded bg-green-600 px-3 py-1.5 text-xs text-white"
                    >
                      Approve
                    </button>
                    <button
                      onClick={() => reject(claim.id)}
                      className="rounded bg-red-600 px-3 py-1.5 text-xs text-white"
                    >
                      Reject
                    </button>
                  </div>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
