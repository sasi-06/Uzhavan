import { useState } from 'react';
import { useAdmin } from '../context/AdminContext';

export default function Listings() {
  const { machines, approveMachine, rejectMachine, isLoading } = useAdmin();
  const [searchTerm, setSearchTerm] = useState('');

  const filteredMachines = machines.filter((m) => {
    const q = searchTerm.toLowerCase();
    return (
      (m.model && m.model.toLowerCase().includes(q)) ||
      (m.type && m.type.toLowerCase().includes(q)) ||
      (m.ownerName && m.ownerName.toLowerCase().includes(q)) ||
      (m.district && m.district.toLowerCase().includes(q))
    );
  });

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      {/* Header */}
      <div className="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-4">
        <div>
          <h2 className="text-3xl font-bold text-gray-900 tracking-tight">Machine Listings (Firestore)</h2>
          <p className="text-gray-500 text-sm mt-1">
            Real farm machinery registered by owners in the database ({machines.length} total)
          </p>
        </div>
        <div className="flex items-center gap-2">
          <span className="text-xs bg-emerald-50 text-emerald-800 font-semibold px-3 py-1.5 rounded-full border border-emerald-200">
            {machines.filter((m) => m.status === 'active' || m.status === 'ACTIVE').length} Active
          </span>
        </div>
      </div>

      {/* Search Input */}
      <div className="bg-white p-4 rounded-2xl border border-gray-100 shadow-sm flex items-center gap-3">
        <svg
          className="w-4 h-4 text-gray-400 ml-2"
          fill="none"
          stroke="currentColor"
          viewBox="0 0 24 24"
        >
          <path
            strokeLinecap="round"
            strokeLinejoin="round"
            strokeWidth="2"
            d="M21 21l-6-6m2-5a7 7 0 11-14 0 7 7 0 0114 0z"
          />
        </svg>
        <input
          type="text"
          placeholder="Search by equipment model, owner name, category, or district..."
          value={searchTerm}
          onChange={(e) => setSearchTerm(e.target.value)}
          className="w-full text-sm bg-transparent border-none focus:outline-none text-gray-800"
        />
      </div>

      {/* Machine Table */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="overflow-x-auto">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-gray-50/75 border-b border-gray-100 text-[11px] font-bold text-gray-500 uppercase tracking-wider">
                <th className="py-3 px-6">Machinery Spec</th>
                <th className="py-3 px-6">Category</th>
                <th className="py-3 px-6">Owner & Contact</th>
                <th className="py-3 px-6">Location</th>
                <th className="py-3 px-6">Tariff Rate</th>
                <th className="py-3 px-6">Status</th>
                <th className="py-3 px-6 text-right">Database Action</th>
              </tr>
            </thead>
            <tbody className="divide-y divide-gray-100 text-sm">
              {filteredMachines.length === 0 ? (
                <tr>
                  <td colSpan={7} className="py-12 text-center text-gray-400">
                    {isLoading ? 'Loading from Firestore...' : 'No matching machines found.'}
                  </td>
                </tr>
              ) : (
                filteredMachines.map((m) => (
                  <tr key={m.id} className="hover:bg-gray-50/50 transition-colors">
                    <td className="py-4 px-6">
                      <div className="font-bold text-gray-900 text-base">{m.model || m.type}</div>
                      <div className="text-xs font-mono text-gray-400">ID: {m.id}</div>
                      {m.serviceRadiusKm && (
                        <div className="text-xs text-gray-500 mt-0.5">
                          Radius: {m.serviceRadiusKm} km
                        </div>
                      )}
                    </td>

                    <td className="py-4 px-6">
                      <span className="px-2.5 py-1 bg-green-50 text-green-800 rounded-lg text-xs font-bold uppercase tracking-wider">
                        {m.type}
                      </span>
                    </td>

                    <td className="py-4 px-6">
                      <div className="font-bold text-gray-900">{m.ownerName}</div>
                      <div className="text-xs font-mono text-gray-500">{m.ownerPhone}</div>
                      {m.owner?.role && (
                        <div className="text-[11px] text-gray-400 uppercase font-semibold">
                          {m.owner.role} • {m.owner.preferredLanguage || 'ta'}
                        </div>
                      )}
                    </td>

                    <td className="py-4 px-6 text-xs text-gray-700">
                      <div className="font-semibold text-gray-900">{m.village || 'Tamil Nadu'}</div>
                      <div className="text-gray-500">{m.district || 'Thoothukudi'}</div>
                      {m.latitude && m.longitude && (
                        <div className="font-mono text-[10px] text-gray-400">
                          {Number(m.latitude).toFixed(3)}, {Number(m.longitude).toFixed(3)}
                        </div>
                      )}
                    </td>

                    <td className="py-4 px-6">
                      <div className="font-extrabold text-emerald-800 text-base">
                        ₹{m.pricePerHour ? `${m.pricePerHour}/hr` : '—'}
                      </div>
                      <div className="text-xs text-gray-500">
                        {m.operatorIncluded ? 'Operator Included' : 'Driver not included'}
                      </div>
                    </td>

                    <td className="py-4 px-6">
                      <span
                        className={`inline-flex items-center px-2.5 py-1 rounded-full text-xs font-bold ${
                          m.status === 'active' || m.status === 'ACTIVE'
                            ? 'bg-emerald-50 text-emerald-700 border border-emerald-200'
                            : 'bg-rose-50 text-rose-700 border border-rose-200'
                        }`}
                      >
                        {m.status}
                      </span>
                    </td>

                    <td className="py-4 px-6 text-right">
                      {m.status !== 'active' && m.status !== 'ACTIVE' ? (
                        <button
                          onClick={() => approveMachine(m.id)}
                          className="px-3 py-1.5 bg-green-700 hover:bg-green-800 text-white rounded-lg text-xs font-semibold shadow-sm transition-colors"
                        >
                          Approve
                        </button>
                      ) : (
                        <button
                          onClick={() => rejectMachine(m.id)}
                          className="px-3 py-1.5 bg-gray-100 hover:bg-rose-50 hover:text-rose-700 text-gray-600 rounded-lg text-xs font-semibold transition-colors"
                        >
                          Block / Revoke
                        </button>
                      )}
                    </td>
                  </tr>
                ))
              )}
            </tbody>
          </table>
        </div>
      </div>
    </div>
  );
}
