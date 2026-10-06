import { useAdmin } from '../context/AdminContext';

export default function Analytics() {
  const { stats, districts } = useAdmin();

  return (
    <div className="space-y-8 max-w-7xl mx-auto">
      <div>
        <h2 className="text-3xl font-bold text-gray-900 tracking-tight">Platform Analytics & Regional Distribution</h2>
        <p className="text-gray-500 text-sm mt-1">
          Real-time metrics computed directly from Firestore database
        </p>
      </div>

      {/* Highlights */}
      <div className="grid grid-cols-1 md:grid-cols-3 gap-5">
        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-1">
            Farmer to Owner Ratio
          </div>
          <div className="flex items-baseline gap-2">
            <span className="text-4xl font-extrabold text-green-900">
              {stats.farmerCount}:{stats.ownerCount}
            </span>
            <span className="text-xs text-gray-500">
              ({stats.totalUsers > 0 ? Math.round((stats.farmerCount / stats.totalUsers) * 100) : 0}% Farmers)
            </span>
          </div>
          <div className="mt-4 w-full bg-gray-100 h-2 rounded-full overflow-hidden flex">
            <div
              className="bg-green-700 h-full"
              style={{
                width: `${stats.totalUsers > 0 ? (stats.farmerCount / stats.totalUsers) * 100 : 0}%`,
              }}
            />
            <div
              className="bg-amber-500 h-full"
              style={{
                width: `${stats.totalUsers > 0 ? (stats.ownerCount / stats.totalUsers) * 100 : 0}%`,
              }}
            />
          </div>
          <div className="mt-2 flex justify-between text-[11px] text-gray-500">
            <span>{stats.farmerCount} Farmers</span>
            <span>{stats.ownerCount} Owners</span>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-1">
            Total GMV Generated
          </div>
          <div className="flex items-baseline gap-2">
            <span className="text-4xl font-extrabold text-purple-900">
              ₹{stats.totalGmv.toLocaleString()}
            </span>
            <span className="text-xs font-semibold text-emerald-600 bg-emerald-50 px-2 py-0.5 rounded-full">
              {stats.totalBookings} Bookings
            </span>
          </div>
          <div className="mt-4 pt-3 border-t border-gray-50 flex items-center justify-between text-xs text-gray-500">
            <span>Avg Ticket Size:</span>
            <span className="font-bold text-gray-800">
              ₹{stats.totalBookings > 0 ? Math.round(stats.totalGmv / stats.totalBookings) : 0}
            </span>
          </div>
        </div>

        <div className="bg-white p-6 rounded-2xl border border-gray-100 shadow-sm">
          <div className="text-xs font-bold uppercase tracking-wider text-gray-400 mb-1">
            Machinery Fleet Active
          </div>
          <div className="flex items-baseline gap-2">
            <span className="text-4xl font-extrabold text-blue-900">
              {stats.activeMachines}
            </span>
            <span className="text-xs text-gray-500">of {stats.totalMachines} units</span>
          </div>
          <div className="mt-4 pt-3 border-t border-gray-50 flex items-center justify-between text-xs text-gray-500">
            <span>Deployment Rate:</span>
            <span className="font-bold text-blue-700">100% Ready</span>
          </div>
        </div>
      </div>

      {/* Regional Distribution by District */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="p-6 border-b border-gray-100">
          <h3 className="text-lg font-bold text-gray-900">Regional District Enrollment</h3>
          <p className="text-gray-500 text-xs mt-0.5">
            Geographic distribution of registered users across Tamil Nadu
          </p>
        </div>

        <div className="divide-y divide-gray-100">
          {districts.map((d) => (
            <div key={d.district} className="p-5 flex items-center justify-between">
              <div>
                <h4 className="font-bold text-gray-900 text-sm">{d.district}</h4>
                <p className="text-xs text-gray-400">Registered District</p>
              </div>
              <div className="flex items-center gap-4">
                <span className="text-sm font-bold text-gray-800">{d.count} Users</span>
                <div className="w-32 bg-gray-100 h-2 rounded-full overflow-hidden">
                  <div
                    className="bg-green-700 h-full"
                    style={{
                      width: `${stats.totalUsers > 0 ? (d.count / stats.totalUsers) * 100 : 0}%`,
                    }}
                  />
                </div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
