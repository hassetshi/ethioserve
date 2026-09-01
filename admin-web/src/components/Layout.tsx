import { NavLink, Outlet } from 'react-router-dom'
import { useAuth } from '../context/auth-context'

const NAV_ITEMS = [
  { to: '/', label: 'Dashboard', end: true },
  { to: '/users', label: 'Users' },
  { to: '/providers', label: 'Providers' },
  { to: '/categories', label: 'Categories' },
  { to: '/services', label: 'Services' },
  { to: '/bookings', label: 'Bookings' },
]

export function Layout() {
  const { signOut } = useAuth()

  return (
    <div className="flex h-screen">
      <aside className="w-56 shrink-0 border-r border-gray-200 bg-gray-50 p-4">
        <h1 className="mb-6 text-lg font-semibold">EthioServe Admin</h1>
        <nav className="flex flex-col gap-1">
          {NAV_ITEMS.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.end}
              className={({ isActive }) =>
                `rounded px-3 py-2 text-sm ${
                  isActive ? 'bg-gray-900 text-white' : 'text-gray-700 hover:bg-gray-200'
                }`
              }
            >
              {item.label}
            </NavLink>
          ))}
        </nav>
        <button
          onClick={signOut}
          className="mt-6 w-full rounded border border-gray-300 px-3 py-2 text-sm text-gray-700 hover:bg-gray-100"
        >
          Sign out
        </button>
      </aside>
      <main className="flex-1 overflow-auto p-6">
        <Outlet />
      </main>
    </div>
  )
}
