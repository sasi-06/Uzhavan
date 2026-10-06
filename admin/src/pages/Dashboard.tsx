import { useAdmin } from '../context/AdminContext';
import { Link } from 'react-router-dom';

export default function Dashboard() {
  const { stats, bookings, users, isLoading, error, refreshData, approveUserKyc } = useAdmin();

  return (
    <div className="space-y-8 max-w-7xl mx-auto">
      {/* Header & Live Database Indicator */}
      <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-4 bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
        <div>
          <h2 className="text-3xl font-bold text-gray-900 tracking-tight">Uzhavan Ops Dashboard</h2>
          <p className="text-gray-500 text-sm mt-1">
            Connected to Live Database: <span className="font-mono font-semibold text-emerald-700">uzhavan-69849 (Firestore & NestJS API)</span>
          </p>
        </div>
        <div className="flex items-center gap-3">
          <span className="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-full text-xs font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
            <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
            Live Firestore Data
          </span>
          <button
            onClick={() => refreshData()}
            disabled={isLoading}
            className="px-4 py-2 text-xs font-semibold rounded-lg bg-gray-100 text-gray-700 hover:bg-gray-200 transition-colors flex items-center gap-1.5"
          >
            <svg
              className={`w-3.5 h-3.5 ${isLoading ? 'animate-spin' : ''}`}
              fill="none"
              stroke="currentColor"
              viewBox="0 0 24 24"
            >
              <path
                strokeLinecap="round"
                strokeLinejoin="round"
                strokeWidth="2"
                d="M4 4v5h.582m15.356 2A8.001 8.001 0 004.582 9m0 0H9m11 11v-5h-.581m0 0a8.003 8.003 0 01-15.357-2m15.357 2H15"
              />
            </svg>
            Refresh Live Data
          </button>
        </div>
      </div>

      {error && (
        <div className="p-4 bg-rose-50 border border-rose-200 rounded-xl text-rose-800 text-sm flex items-center gap-3">
          <span>⚠️</span>
          <span>{error}</span>
        </div>
      )}

      {/* KPI Stats from Database */}
      <div className="grid grid-cols-1 sm:grid-cols-2 xl:grid-cols-4 gap-5">
        {/* Active Machinery Listings */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:border-green-200 transition-all">
          <div className="flex items-center justify-between mb-4">
            <span className="text-xs font-bold uppercase tracking-wider text-gray-500">Live Machines</span>
            <span className="p-2 bg-green-50 rounded-xl text-green-700 font-bold text-lg">🚜</span>
          </div>
          <div className="flex items-baseline gap-2">
            <span className="text-4xl font-extrabold text-green-900">{stats.activeMachines}</span>
            <span className="text-xs font-medium text-emerald-700 bg-emerald-50 px-2 py-0.5 rounded-full">
              {stats.totalMachines} in registry
            </span>
          </div>
          <div className="mt-4 pt-3 border-t border-gray-50 flex items-center justify-between text-xs text-gray-500">
            <span>Tractor, Seeder, Harvester</span>
            <Link to="/listings" className="text-green-700 font-semibold hover:underline">
              Inspect fleet →
            </Link>
          </div>
        </div>

        {/* Registered Users */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:border-blue-200 transition-all">
          <div className="flex items-center justify-between mb-4">
            <span className="text-xs font-bold uppercase tracking-wider text-gray-500">Registered Users</span>
            <span className="p-2 bg-blue-50 rounded-xl text-blue-700 font-bold text-lg">👥</span>
          </div>
          <div className="flex items-baseline gap-2">
            <span className="text-4xl font-extrabold text-blue-900">{stats.totalUsers}</span>
            <span className="text-xs font-medium text-blue-700 bg-blue-50 px-2 py-0.5 rounded-full">
              {stats.farmerCount} Farmers / {stats.ownerCount} Owners
            </span>
          </div>
          <div className="mt-4 pt-3 border-t border-gray-50 flex items-center justify-between text-xs text-gray-500">
            <span>Live Firestore Profiles</span>
            <span className="text-blue-700 font-medium">Tamil Nadu</span>
          </div>
        </div>

        {/* Pending KYC Approvals */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:border-amber-200 transition-all">
          <div className="flex items-center justify-between mb-4">
            <span className="text-xs font-bold uppercase tracking-wider text-gray-500">Pending User KYC</span>
            <span className="p-2 bg-amber-50 rounded-xl text-amber-700 font-bold text-lg">📑</span>
          </div>
          <div className="flex items-baseline gap-2">
            <span className="text-4xl font-extrabold text-amber-600">{stats.pendingKycUsers}</span>
            <span className="text-xs font-medium text-amber-800 bg-amber-50 px-2 py-0.5 rounded-full">
              Verification pending
            </span>
          </div>
          <div className="mt-4 pt-3 border-t border-gray-50 flex items-center justify-between text-xs text-gray-500">
            <span>Aadhaar / Land Records</span>
            <span className="text-amber-700 font-medium">In Queue</span>
          </div>
        </div>

        {/* Total Bookings & GMV */}
        <div className="bg-white rounded-2xl p-6 shadow-sm border border-gray-100 hover:border-purple-200 transition-all">
          <div className="flex items-center justify-between mb-4">
            <span className="text-xs font-bold uppercase tracking-wider text-gray-500">Total Bookings & GMV</span>
            <span className="p-2 bg-purple-50 rounded-xl text-purple-700 font-bold text-lg">💰</span>
          </div>
          <div className="flex items-baseline gap-2">
            <span className="text-4xl font-extrabold text-purple-900">₹{stats.totalGmv.toLocaleString()}</span>
            <span className="text-xs font-medium text-purple-700 bg-purple-50 px-2 py-0.5 rounded-full">
              {stats.totalBookings} Dispatches
            </span>
          </div>
          <div className="mt-4 pt-3 border-t border-gray-50 flex items-center justify-between text-xs text-gray-500">
            <span>Rental Transactions</span>
            <span className="text-purple-700 font-semibold">100% Confirmed</span>
          </div>
        </div>
      </div>

      {/* Live Dispatches Table from Firestore */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="p-6 border-b border-gray-100 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h3 className="text-lg font-bold text-gray-900">Live Booking Dispatches (Firestore: bookings)</h3>
            <p className="text-gray-500 text-xs mt-0.5">Original rental records with matched farmers and machine owners</p>
          </div>
          <span className="text-xs font-semibold text-gray-600 bg-gray-50 px-3 py-1.5 rounded-lg border border-gray-100">
            {bookings.length} Records in Database
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50/75 border-b border-gray-100 text-[11px] font-bold text-gray-500 uppercase tracking-wider">
                <th className="py-3 px-6">Doc ID</th>
                <th className="py-3 px-6">Farmer (Renter)</th>
                <th className="py-3 px-6">Equipment & Owner</th>
                <th className="py-3 px-6">Dates</th>
                <th className="py-3 px-6">Operator</th>
                <th className="py-3 px-6">Total Tariff</th>
                <th className="py-3 px-6">Status</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 text-sm">
              {bookings.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-8 text-center text-gray-400">
                    No bookings found in database.
                  </td>
                </tr>
              ) : (
                bookings.map((b) => (
                  <tr key={b.id} className="hover:bg-gray-50/50 transition-colors">
                    <td className="py-4 px-6 font-mono text-xs font-semibold text-gray-700">
                      {b.id.slice(0, 10)}...
                    </td>
                    <td className="py-4 px-6">
                      <div className="font-bold text-gray-900">{b.farmerName}</div>
                      <div className="text-xs text-gray-500 font-mono">{b.farmerPhone}</div>
                      {b.renter?.village && (
                        <div className="text-[11px] text-gray-400">
                          {b.renter.village}, {b.renter.district}
                        </div>
                      )}
                    </td>
                    <td className="py-4 px-6">
                      <div className="font-semibold text-gray-900">{b.machineModel}</div>
                      <div className="text-xs text-gray-500">
                        Owner: <span className="font-medium text-gray-700">{b.ownerName}</span> ({b.ownerPhone})
                      </div>
                    </td>
                    <td className="py-4 px-6 text-xs text-gray-600">
                      <div>{b.startDate ? b.startDate.slice(0, 10) : '—'}</div>
                      <div className="text-gray-400">to {b.endDate ? b.endDate.slice(0, 10) : '—'}</div>
                    </td>
                    <td className="py-4 px-6 text-xs">
                      <span className="px-2 py-0.5 rounded text-[11px] font-medium bg-gray-100 text-gray-700">
                        {b.operatorIncluded ? 'Included' : 'Self-Drive'}
                      </span>
                    </td>
                    <td className="py-4 px-6">
                      <div className="font-extrabold text-emerald-800">
                        ₹{b.totalAmount.toLocaleString()}
                      </div>
                    </td>
                    <td className="py-4 px-6">
                      <span className="inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold bg-emerald-50 text-emerald-700 border border-emerald-200">
                        {b.status}
                      </span>
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>

      {/* Registered Users from Firestore */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="p-6 border-b border-gray-100 flex flex-col sm:flex-row sm:items-center justify-between gap-4">
          <div>
            <h3 className="text-lg font-bold text-gray-900">User Directory (Firestore: users)</h3>
            <p className="text-gray-500 text-xs mt-0.5">Real farmer and machinery owner profiles stored in database</p>
          </div>
          <span className="text-xs font-semibold text-gray-600 bg-gray-50 px-3 py-1.5 rounded-lg border border-gray-100">
            {users.length} Users Enrolled
          </span>
        </div>

        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50/75 border-b border-gray-100 text-[11px] font-bold text-gray-500 uppercase tracking-wider">
                <th className="py-3 px-6">Name</th>
                <th className="py-3 px-6">Phone Number</th>
                <th className="py-3 px-6">Role</th>
                <th className="py-3 px-6">Location</th>
                <th className="py-3 px-6">Language</th>
                <th className="py-3 px-6">KYC Status</th>
                <th className="py-3 px-6 text-right">Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 text-sm">
              {users.map((u) => (
                <tr key={u.id} className="hover:bg-gray-50/50 transition-colors">
                  <td className="py-4 px-6 font-bold text-gray-900">{u.name}</td>
                  <td className="py-4 px-6 font-mono text-xs text-gray-600">{u.phone}</td>
                  <td className="py-4 px-6">
                    <span
                      className={`inline-flex px-2 py-0.5 rounded text-xs font-bold uppercase tracking-wider ${
                        u.role === 'owner'
                          ? 'bg-amber-100 text-amber-800'
                          : 'bg-green-100 text-green-800'
                      }`}
                    >
                      {u.role}
                    </span>
                  </td>
                  <td className="py-4 px-6 text-xs text-gray-600">
                    {u.village ? `${u.village}, ` : ''}{u.district || 'Tamil Nadu'}
                  </td>
                  <td className="py-4 px-6 text-xs text-gray-600 uppercase font-bold">
                    {u.preferredLanguage || 'ta'}
                  </td>
                  <td className="py-4 px-6">
                    <span
                      className={`inline-flex items-center px-2 py-0.5 rounded-full text-xs font-semibold ${
                        u.kycStatus === 'approved'
                          ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                          : 'bg-amber-50 text-amber-700 border border-amber-200'
                      }`}
                    >
                      {u.kycStatus || 'pending'}
                    </span>
                  </td>
                  <td className="py-4 px-6 text-right">
                    {u.kycStatus !== 'approved' && (
                      <button
                        onClick={() => approveUserKyc(u.id)}
                        className="px-3 py-1 bg-green-700 hover:bg-green-800 text-white rounded-lg text-xs font-semibold shadow-sm transition-colors"
                      >
                        Approve KYC
                      </button>
                    )}
                  </td>
                </tr>
              ))}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
