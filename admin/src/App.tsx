import { BrowserRouter, Routes, Route, NavLink } from 'react-router-dom';
import { AdminProvider, useAdmin } from './context/AdminContext';
import Dashboard from './pages/Dashboard';
import Listings from './pages/Listings';
import Disputes from './pages/Disputes';
import Analytics from './pages/Analytics';

function NavigationSidebar() {
  const { stats } = useAdmin();

  const nav = [
    { to: '/', label: 'Dashboard', badge: null, icon: '📊' },
    {
      to: '/listings',
      label: 'Listings',
      badge: stats.totalMachines > 0 ? stats.totalMachines : null,
      badgeColor: 'bg-green-100 text-green-800',
      icon: '🚜',
    },
    {
      to: '/disputes',
      label: 'Disputes',
      badge: null,
      icon: '⚖️',
    },
    { to: '/analytics', label: 'Analytics', badge: null, icon: '📈' },
  ];

  return (
    <aside className="w-64 bg-white border-r border-gray-200 p-6 flex flex-col justify-between shrink-0 min-h-screen">
      <div>
        <div className="flex items-center gap-2.5 mb-1">
          <span className="text-2xl">🌾</span>
          <h1 className="text-2xl font-extrabold text-green-900 tracking-tight">Uzhavan</h1>
        </div>
        <p className="text-xs font-semibold text-gray-400 mb-8 uppercase tracking-wider">
          Live Admin Console
        </p>

        <nav className="space-y-1.5">
          {nav.map((item) => (
            <NavLink
              key={item.to}
              to={item.to}
              end={item.to === '/'}
              className={({ isActive }) =>
                `flex items-center justify-between px-4 py-3 rounded-xl text-sm font-semibold transition-all ${
                  isActive
                    ? 'bg-green-800 text-white shadow-sm'
                    : 'text-gray-600 hover:bg-gray-50 hover:text-gray-900'
                }`
              }
            >
              {({ isActive }) => (
                <>
                  <div className="flex items-center gap-3">
                    <span className="text-base">{item.icon}</span>
                    <span>{item.label}</span>
                  </div>
                  {item.badge !== null && item.badge !== undefined && (
                    <span
                      className={`text-[11px] font-bold px-2 py-0.5 rounded-full ${
                        isActive ? 'bg-white/20 text-white' : item.badgeColor
                      }`}
                    >
                      {item.badge}
                    </span>
                  )}
                </>
              )}
            </NavLink>
          ))}
        </nav>
      </div>

      {/* Admin Profile Box */}
      <div className="pt-6 border-t border-gray-100">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-full bg-green-100 text-green-800 font-bold flex items-center justify-center text-sm">
            TN
          </div>
          <div className="overflow-hidden">
            <div className="text-xs font-bold text-gray-900 truncate">TN Agri Command</div>
            <div className="text-[11px] text-gray-400 truncate">Live Database: uzhavan-69849</div>
          </div>
        </div>
      </div>
    </aside>
  );
}

export default function App() {
  return (
    <AdminProvider>
      <BrowserRouter>
        <div className="min-h-screen flex bg-[#f8f7f4]">
          <NavigationSidebar />
          <main className="flex-1 p-8 overflow-y-auto">
            <Routes>
              <Route path="/" element={<Dashboard />} />
              <Route path="/listings" element={<Listings />} />
              <Route path="/disputes" element={<Disputes />} />
              <Route path="/analytics" element={<Analytics />} />
            </Routes>
          </main>
        </div>
      </BrowserRouter>
    </AdminProvider>
  );
}
