import { useQuery } from '@tanstack/react-query'
import { supabase } from '../lib/supabase'

function useCount(key: string, table: string, eq?: [string, string]) {
  return useQuery({
    queryKey: ['count', key],
    queryFn: async () => {
      let query = supabase.from(table).select('*', { count: 'exact', head: true })
      if (eq) query = query.eq(eq[0], eq[1])
      const { count, error } = await query
      if (error) throw error
      return count ?? 0
    },
  })
}

function StatCard({ label, value, loading }: { label: string; value?: number; loading: boolean }) {
  return (
    <div className="rounded-lg border border-gray-200 p-4">
      <p className="text-sm text-gray-500">{label}</p>
      <p className="text-2xl font-semibold">{loading ? '…' : value}</p>
    </div>
  )
}

export function DashboardPage() {
  const customers = useCount('customers', 'users', ['role', 'customer'])
  const providers = useCount('providers', 'users', ['role', 'provider'])
  const pendingVerifications = useCount('pending-verifications', 'provider_profiles', [
    'verification_status',
    'pending',
  ])
  const bookings = useCount('bookings', 'bookings')

  return (
    <div>
      <h1 className="mb-4 text-xl font-semibold">Dashboard</h1>
      <div className="grid grid-cols-2 gap-4 sm:grid-cols-4">
        <StatCard label="Customers" value={customers.data} loading={customers.isLoading} />
        <StatCard label="Providers" value={providers.data} loading={providers.isLoading} />
        <StatCard
          label="Pending verifications"
          value={pendingVerifications.data}
          loading={pendingVerifications.isLoading}
        />
        <StatCard label="Total bookings" value={bookings.data} loading={bookings.isLoading} />
      </div>
    </div>
  )
}
