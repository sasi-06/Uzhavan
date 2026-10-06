import { useAdmin } from '../context/AdminContext';

export default function Disputes() {
  const { bookings } = useAdmin();

  const disputedBookings = bookings.filter((b) => b.status === 'DISPUTED');
  const confirmedBookings = bookings.filter((b) => b.status === 'CONFIRMED' || b.status === 'COMPLETED');

  return (
    <div className="space-y-6 max-w-7xl mx-auto">
      <div>
        <h2 className="text-3xl font-bold text-gray-900 tracking-tight">Disputes & Escrow Mediation</h2>
        <p className="text-gray-500 text-sm mt-1">
          Monitor escrow safety and resolve complaints from live bookings
        </p>
      </div>

      {disputedBookings.length === 0 ? (
        <div className="bg-white rounded-2xl border border-gray-100 p-12 text-center shadow-sm">
          <div className="w-16 h-16 bg-emerald-50 text-emerald-600 rounded-full flex items-center justify-center mx-auto text-2xl mb-4">
            ✓
          </div>
          <h3 className="text-lg font-bold text-gray-900">No Open Disputes</h3>
          <p className="text-gray-500 text-sm max-w-md mx-auto mt-1">
            All {bookings.length} rental bookings in the live database are currently in healthy standing with no reported escrow disputes.
          </p>
        </div>
      ) : (
        <div className="space-y-4">
          {disputedBookings.map((b) => (
            <div key={b.id} className="bg-white p-6 rounded-2xl border border-rose-100 shadow-sm">
              <div className="flex items-center justify-between">
                <span className="font-mono text-xs font-bold text-rose-700">{b.id}</span>
                <span className="font-bold text-gray-900">₹{b.totalAmount}</span>
              </div>
            </div>
          ))}
        </div>
      )}

      {/* Escrow Audited Bookings */}
      <div className="bg-white rounded-2xl border border-gray-100 shadow-sm overflow-hidden">
        <div className="p-6 border-b border-gray-100">
          <h3 className="text-lg font-bold text-gray-900">Escrow Security Audit (Live Bookings)</h3>
          <p className="text-gray-500 text-xs mt-0.5">
            Active reservations tracked by GPS and diesel telematics
          </p>
        </div>

        <div className="divide-y divide-gray-100">
          {confirmedBookings.map((b) => (
            <div key={b.id} className="p-5 flex flex-col sm:flex-row sm:items-center justify-between gap-3 hover:bg-gray-50/50 transition-colors">
              <div>
                <div className="flex items-center gap-2">
                  <span className="font-mono font-bold text-xs text-gray-700">{b.id}</span>
                  <span className="text-xs px-2 py-0.5 rounded-full font-semibold bg-emerald-50 text-emerald-700 border border-emerald-200">
                    Escrow Protected
                  </span>
                </div>
                <div className="text-sm font-semibold text-gray-900 mt-1">
                  Farmer: {b.farmerName} • Equipment: {b.machineModel}
                </div>
                <div className="text-xs text-gray-400">
                  Owner: {b.ownerName} ({b.ownerPhone})
                </div>
              </div>
              <div className="text-right">
                <div className="text-base font-extrabold text-gray-900">₹{b.totalAmount}</div>
                <div className="text-[11px] text-gray-400">Escrow on Hold</div>
              </div>
            </div>
          ))}
        </div>
      </div>
    </div>
  );
}
