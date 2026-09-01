import { useQuery, useQueryClient } from '@tanstack/react-query'
import { supabase } from '../lib/supabase'

type UserRow = {
  id: string
  phone: string | null
  email: string | null
  role: string
  is_active: boolean
  created_at: string
  profiles: { first_name: string | null; last_name: string | null }[] | null
}

export function UsersPage() {
  const queryClient = useQueryClient()

  const { data, isLoading, error } = useQuery({
    queryKey: ['users'],
    queryFn: async () => {
      const { data, error } = await supabase
        .from('users')
        .select('id, phone, email, role, is_active, created_at, profiles(first_name, last_name)')
        .order('created_at', { ascending: false })
      if (error) throw error
      return data as UserRow[]
    },
  })

  async function toggleActive(user: UserRow) {
    await supabase.from('users').update({ is_active: !user.is_active }).eq('id', user.id)
    queryClient.invalidateQueries({ queryKey: ['users'] })
  }

  if (isLoading) return <p>Loading...</p>
  if (error) return <p className="text-red-600">Something went wrong. Please try again.</p>

  return (
    <div>
      <h1 className="mb-4 text-xl font-semibold">Users</h1>
      <table className="w-full border-collapse text-sm">
        <thead>
          <tr className="border-b border-gray-200 text-left text-gray-500">
            <th className="py-2">Name</th>
            <th className="py-2">Contact</th>
            <th className="py-2">Role</th>
            <th className="py-2">Status</th>
            <th className="py-2" />
          </tr>
        </thead>
        <tbody>
          {data?.map((user) => {
            const profile = user.profiles?.[0]
            const name = profile ? `${profile.first_name ?? ''} ${profile.last_name ?? ''}`.trim() : ''
            return (
              <tr key={user.id} className="border-b border-gray-100">
                <td className="py-2">{name || '—'}</td>
                <td className="py-2">{user.phone ?? user.email ?? '—'}</td>
                <td className="py-2 capitalize">{user.role}</td>
                <td className="py-2">
                  <span
                    className={`rounded px-2 py-0.5 text-xs ${
                      user.is_active ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-500'
                    }`}
                  >
                    {user.is_active ? 'Active' : 'Deactivated'}
                  </span>
                </td>
                <td className="py-2">
                  <button
                    onClick={() => toggleActive(user)}
                    className="text-xs text-blue-600 hover:underline"
                  >
                    {user.is_active ? 'Deactivate' : 'Reactivate'}
                  </button>
                </td>
              </tr>
            )
          })}
        </tbody>
      </table>
    </div>
  )
}
