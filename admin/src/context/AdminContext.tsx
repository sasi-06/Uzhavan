import React, { createContext, useContext, useState, useEffect, useCallback } from 'react';

export interface OriginalMachine {
  id: string;
  type: string;
  model: string;
  pricePerHour?: number;
  pricePerAcre?: number;
  operatorIncluded?: boolean;
  status: string;
  latitude?: number;
  longitude?: number;
  village?: string;
  district?: string;
  photos?: string[];
  ownerId?: string;
  ownerName?: string;
  ownerPhone?: string;
  owner?: any;
  serviceRadiusKm?: number;
  createdAt?: string;
}

export interface OriginalBooking {
  id: string;
  machineId: string;
  renterId: string;
  ownerId: string;
  priceTotal: number;
  totalAmount: number;
  startDate: string;
  endDate: string;
  operatorIncluded?: boolean;
  status: string;
  farmerName: string;
  farmerPhone: string;
  ownerName: string;
  ownerPhone: string;
  machineModel: string;
  machineType: string;
  renter?: any;
  owner?: any;
  machine?: any;
  createdAt?: string;
}

export interface OriginalUser {
  id: string;
  name: string;
  phone: string;
  role: string;
  preferredLanguage?: string;
  kycStatus?: string;
  village?: string;
  district?: string;
  createdAt?: any;
}

export interface OriginalStats {
  totalMachines: number;
  activeMachines: number;
  pendingMachines: number;
  totalUsers: number;
  farmerCount: number;
  ownerCount: number;
  pendingKycUsers: number;
  totalBookings: number;
  totalGmv: number;
}

export interface DistrictMetric {
  district: string;
  count: number;
}

interface AdminContextType {
  machines: OriginalMachine[];
  bookings: OriginalBooking[];
  users: OriginalUser[];
  stats: OriginalStats;
  districts: DistrictMetric[];
  isLoading: boolean;
  error: string | null;
  refreshData: () => Promise<void>;
  approveMachine: (id: string) => Promise<void>;
  rejectMachine: (id: string) => Promise<void>;
  approveUserKyc: (id: string) => Promise<void>;
}

const defaultStats: OriginalStats = {
  totalMachines: 0,
  activeMachines: 0,
  pendingMachines: 0,
  totalUsers: 0,
  farmerCount: 0,
  ownerCount: 0,
  pendingKycUsers: 0,
  totalBookings: 0,
  totalGmv: 0,
};

const AdminContext = createContext<AdminContextType | undefined>(undefined);

export const AdminProvider: React.FC<{ children: React.ReactNode }> = ({ children }) => {
  const [machines, setMachines] = useState<OriginalMachine[]>([]);
  const [bookings, setBookings] = useState<OriginalBooking[]>([]);
  const [users, setUsers] = useState<OriginalUser[]>([]);
  const [stats, setStats] = useState<OriginalStats>(defaultStats);
  const [districts, setDistricts] = useState<DistrictMetric[]>([]);
  const [isLoading, setIsLoading] = useState<boolean>(true);
  const [error, setError] = useState<string | null>(null);

  const API_BASE = 'http://localhost:3000/api/v1/admin';

  const refreshData = useCallback(async () => {
    setIsLoading(true);
    setError(null);
    try {
      const [overviewRes, machinesRes, bookingsRes, usersRes] = await Promise.all([
        fetch(`${API_BASE}/overview`),
        fetch(`${API_BASE}/machines`),
        fetch(`${API_BASE}/bookings`),
        fetch(`${API_BASE}/users`),
      ]);

      if (!overviewRes.ok || !machinesRes.ok || !bookingsRes.ok || !usersRes.ok) {
        throw new Error('Failed to fetch original data from Uzhavan API');
      }

      const [overviewData, machinesData, bookingsData, usersData] = await Promise.all([
        overviewRes.json(),
        machinesRes.json(),
        bookingsRes.json(),
        usersRes.json(),
      ]);

      setStats(overviewData.stats || defaultStats);
      setDistricts(overviewData.districts || []);
      setMachines(machinesData || []);
      setBookings(bookingsData || []);
      setUsers(usersData || []);
    } catch (err: any) {
      console.error('Error fetching original data:', err);
      setError(err.message || 'Unable to connect to live backend');
    } finally {
      setIsLoading(false);
    }
  }, []);

  useEffect(() => {
    refreshData();
  }, [refreshData]);

  const approveMachine = async (id: string) => {
    try {
      const res = await fetch(`${API_BASE}/machines/${id}/approve`, { method: 'POST' });
      if (res.ok) {
        setMachines((prev) =>
          prev.map((m) => (m.id === id ? { ...m, status: 'active' } : m))
        );
        refreshData();
      }
    } catch (err) {
      console.error('Failed to approve machine:', err);
    }
  };

  const rejectMachine = async (id: string) => {
    try {
      const res = await fetch(`${API_BASE}/machines/${id}/reject`, { method: 'POST' });
      if (res.ok) {
        setMachines((prev) =>
          prev.map((m) => (m.id === id ? { ...m, status: 'blocked' } : m))
        );
        refreshData();
      }
    } catch (err) {
      console.error('Failed to reject machine:', err);
    }
  };

  const approveUserKyc = async (id: string) => {
    try {
      const res = await fetch(`${API_BASE}/users/${id}/kyc-approve`, { method: 'POST' });
      if (res.ok) {
        setUsers((prev) =>
          prev.map((u) => (u.id === id ? { ...u, kycStatus: 'approved' } : u))
        );
        refreshData();
      }
    } catch (err) {
      console.error('Failed to approve user KYC:', err);
    }
  };

  return (
    <AdminContext.Provider
      value={{
        machines,
        bookings,
        users,
        stats,
        districts,
        isLoading,
        error,
        refreshData,
        approveMachine,
        rejectMachine,
        approveUserKyc,
      }}
    >
      {children}
    </AdminContext.Provider>
  );
};

export const useAdmin = () => {
  const context = useContext(AdminContext);
  if (!context) {
    throw new Error('useAdmin must be used within an AdminProvider');
  }
  return context;
};
