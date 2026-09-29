export default function Listings() {
  return (
    <div>
      <h2 className="text-3xl font-semibold mb-2">Machine Listings</h2>
      <p className="text-gray-500 mb-8">Approve or reject owner listings and KYC</p>
      <div className="bg-white rounded-xl border border-gray-100 p-8 text-center text-gray-400">
        No pending listings — data loads from <code className="text-green-700">GET /api/v1/machines</code>
      </div>
    </div>
  )
}
