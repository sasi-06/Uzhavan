import { BrowserRouter, Routes, Route, NavLink } from 'react-router-dom'
import Dashboard from './pages/Dashboard'
import Listings from './pages/Listings'
import Disputes from './pages/Disputes'
import Analytics from './pages/Analytics'

const nav = [
  { to: '/', label: 'Dashboard' },
  { to: '/listings', label: 'Listings' },
  { to: '/disputes', label: 'Disputes' },
  { to: '/analytics', label: 'Analytics' },
]

export default function App() {
  return (
    <BrowserRouter>
      <div className="min-h-screen flex">
        <aside className="w-64 bg-white border-r border-gray-200 p-6">
          <h1 className="text-2xl font-bold text-green-800 mb-1">Uzhavan</h1>
          <p className="text-sm text-gray-500 mb-8">Admin Console</p>
          <nav className="space-y-2">
            {nav.map((item) => (
              <NavLink
                key={item.to}
                to={item.to}
                end={item.to === '/'}
                className={({ isActive }) =>
                  `block px-4 py-3 rounded-lg text-base font-medium ${
                    isActive ? 'bg-green-100 text-green-800' : 'text-gray-600 hover:bg-gray-50'
                  }`
                }
              >
                {item.label}
              </NavLink>
            ))}
          </nav>
        </aside>
        <main className="flex-1 p-8">
          <Routes>
            <Route path="/" element={<Dashboard />} />
            <Route path="/listings" element={<Listings />} />
            <Route path="/disputes" element={<Disputes />} />
            <Route path="/analytics" element={<Analytics />} />
          </Routes>
        </main>
      </div>
    </BrowserRouter>
  )
}
