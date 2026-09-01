import { useQuery } from '@tanstack/react-query'
import { useState } from 'react'
import { supabase } from '../lib/supabase'

type BookingRow = {
  id: string
  status: string
  scheduled_date: string
  scheduled_time: string
  provider_profiles: { business_name: string } | null
  services: { name_en: string } | null
}

const STATUSES = [
  'requested',
  'accepted',
  'on_the_way',
  'in_progress',
  'completed',
  'declined',
  'cancelled',
]

export function BookingsPage() {
  const [statusFilter, setStatusFilter] = useState('')

  const { data, isLoading, error } = useQuery({
    queryKey: ['bookings-admin', statusFilter],
    queryFn: async () => {
      let query = supabase
        .from('bookings')
        .select('id, status, scheduled_date, scheduled_time, provider_profiles(business_name), services(name_en)')
        .order('created_at', { ascending: false })
        .limit(100)
      if (statusFilter) query = query.eq('status', statusFilter)
      const { data, error } = await query
      if (error) throw error
      return data as unknown as BookingRow[]
    },
  })

  if (error) return <p className="text-red-600">Something went wrong. Please try again.</p>

  return (
    <div>
      <h1 className="mb-4 text-xl font-semibold">Bookings</h1>

      <select
        value={statusFilter}
        onChange={(e) => setStatusFilter(e.target.value)}
        className="mb-4 rounded border border-gray-300 px-3 py-1.5 text-sm"
      >
        <option value="">All statuses</option>
        {STATUSES.map((status) => (
          <option key={status} value={status}>
            {status}
          </option>
        ))}
      </select>

      {isLoading ? (
        <p>Loading...</p>
      ) : (
        <table className="w-full border-collapse text-sm">
          <thead>
            <tr className="border-b border-gray-200 text-left text-gray-500">
              <th className="py-2">Provider</th>
              <th className="py-2">Service</th>
              <th className="py-2">Scheduled</th>
              <th className="py-2">Status</th>
            </tr>
          </thead>
          <tbody>
            {data?.map((booking) => (
              <tr key={booking.id} className="border-b border-gray-100">
                <td className="py-2">{booking.provider_profiles?.business_name ?? '—'}</td>
                <td className="py-2">{booking.services?.name_en ?? '—'}</td>
                <td className="py-2">
                  {booking.scheduled_date} {booking.scheduled_time.substring(0, 5)}
                </td>
                <td className="py-2 capitalize">{booking.status.replaceAll('_', ' ')}</td>
              </tr>
            ))}
          </tbody>
        </table>
      )}
    </div>
  )
}
