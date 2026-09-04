import { useQuery, useQueryClient } from '@tanstack/react-query'
import { logAdminAction } from '../lib/audit'
import { supabase } from '../lib/supabase'

type SubscriptionRow = {
  id: string
  plan: string
  status: string
  price: number
  current_period_end: string | null
  provider_profiles: { business_name: string } | null
}

function StatusBadge({ status }: { status: string }) {
  const color =
    status === 'active'
      ? 'bg-green-100 text-green-700'
      : status === 'cancelled'
        ? 'bg-gray-200 text-gray-600'
        : status === 'pending'
          ? 'bg-yellow-100 text-yellow-700'
          : 'bg-red-100 text-red-700'
  return <span className={`rounded px-2 py-0.5 text-xs capitalize ${color}`}>{status}</span>
}

export function SubscriptionsPage() {
  const queryClient = useQueryClient()

  const { data, isLoading, error } = useQuery({
    queryKey: ['subscriptions'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('subscriptions')
        .select('id, plan, status, price, current_period_end, provider_profiles(business_name)')
        .order('created_at', { ascending: false })
      if (error) throw error
      return data as unknown as SubscriptionRow[]
    },
  })

  async function cancel(subscriptionId: string) {
    await supabase.from('subscriptions').update({ status: 'cancelled' }).eq('id', subscriptionId)
    await logAdminAction('subscription.cancelled', 'subscriptions', subscriptionId)
    queryClient.invalidateQueries({ queryKey: ['subscriptions'] })
  }

  if (isLoading) return <p>Loading...</p>
  if (error) return <p className="text-red-600">Something went wrong. Please try again.</p>

  return (
    <div>
      <h1 className="mb-4 text-xl font-semibold">Subscriptions</h1>
      <table className="w-full border-collapse text-sm">
        <thead>
          <tr className="border-b border-gray-200 text-left text-gray-500">
            <th className="py-2">Business</th>
            <th className="py-2">Plan</th>
            <th className="py-2">Price</th>
            <th className="py-2">Status</th>
            <th className="py-2">Renews / Ended</th>
            <th className="py-2" />
          </tr>
        </thead>
        <tbody>
          {data?.map((sub) => (
            <tr key={sub.id} className="border-b border-gray-100">
              <td className="py-2">{sub.provider_profiles?.business_name ?? '—'}</td>
              <td className="py-2 capitalize">{sub.plan}</td>
              <td className="py-2">${sub.price.toFixed(0)}/mo</td>
              <td className="py-2">
                <StatusBadge status={sub.status} />
              </td>
              <td className="py-2">
                {sub.current_period_end
                  ? new Date(sub.current_period_end).toLocaleDateString()
                  : '—'}
              </td>
              <td className="py-2">
                {sub.status === 'active' && (
                  <button
                    onClick={() => cancel(sub.id)}
                    className="text-xs text-red-600 hover:underline"
                  >
                    Cancel subscription
                  </button>
                )}
              </td>
            </tr>
          ))}
        </tbody>
      </table>
    </div>
  )
}
