const stats = [
  { label: 'Active Listings', value: '—', color: 'text-green-700' },
  { label: 'Pending Approval', value: '—', color: 'text-amber-600' },
  { label: 'Open Disputes', value: '—', color: 'text-red-600' },
  { label: 'Bookings Today', value: '—', color: 'text-blue-700' },
]

export default function Dashboard() {
  return (
    <div>
      <h2 className="text-3xl font-semibold mb-2">Dashboard</h2>
      <p className="text-gray-500 mb-8">Platform overview — connect to API for live data</p>
      <div className="grid grid-cols-1 md:grid-cols-2 xl:grid-cols-4 gap-6">
        {stats.map((s) => (
          <div key={s.label} className="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
            <p className="text-gray-500 text-sm mb-2">{s.label}</p>
            <p className={`text-4xl font-bold ${s.color}`}>{s.value}</p>
          </div>
        ))}
      </div>
    </div>
  )
}
