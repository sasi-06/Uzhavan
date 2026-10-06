import { Injectable, NotFoundException } from '@nestjs/common';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';

@Injectable()
export class AdminService {
  private get db() {
    return getFirestore();
  }

  async getOverview() {
    const [machinesSnap, usersSnap, bookingsSnap] = await Promise.all([
      this.db.collection('machines').get(),
      this.db.collection('users').get(),
      this.db.collection('bookings').get(),
    ]);

    const machines = machinesSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const users = usersSnap.docs.map((d) => ({ id: d.id, ...d.data() }));
    const bookings = bookingsSnap.docs.map((d) => ({ id: d.id, ...d.data() }));

    const activeMachines = machines.filter(
      (m: any) => m.status === 'active' || m.status === 'ACTIVE'
    ).length;
    const pendingMachines = machines.filter(
      (m: any) =>
        m.status === 'pending_approval' ||
        m.status === 'PENDING_APPROVAL' ||
        m.status === 'pending'
    ).length;

    const farmers = users.filter((u: any) => u.role === 'farmer' || u.role === 'FARMER').length;
    const owners = users.filter((u: any) => u.role === 'owner' || u.role === 'OWNER').length;
    const pendingKycUsers = users.filter(
      (u: any) => u.kycStatus === 'pending' || u.kycStatus === 'PENDING'
    ).length;

    const totalGmv = bookings.reduce(
      (sum: number, b: any) => sum + (Number(b.priceTotal) || 0),
      0
    );

    // Calculate district breakdown from users and machines
    const districtCounts: Record<string, number> = {};
    for (const u of users as any[]) {
      const d = u.district || 'Unassigned';
      districtCounts[d] = (districtCounts[d] || 0) + 1;
    }

    return {
      stats: {
        totalMachines: machines.length,
        activeMachines,
        pendingMachines,
        totalUsers: users.length,
        farmerCount: farmers,
        ownerCount: owners,
        pendingKycUsers,
        totalBookings: bookings.length,
        totalGmv,
      },
      districts: Object.entries(districtCounts).map(([district, count]) => ({
        district,
        count,
      })),
    };
  }

  async getMachines() {
    const snap = await this.db.collection('machines').get();
    const machines = await Promise.all(
      snap.docs.map(async (doc) => {
        const data = doc.data();
        let owner: any = data.owner || null;
        if (!owner && data.ownerId) {
          const ownerDoc = await this.db.collection('users').doc(data.ownerId).get();
          if (ownerDoc.exists) {
            owner = { id: ownerDoc.id, ...ownerDoc.data() };
          }
        }

        return {
          id: doc.id,
          ...data,
          owner,
          ownerName: data.ownerName || owner?.name || 'Unknown Owner',
          ownerPhone: data.ownerPhone || owner?.phone || '—',
          createdAt: data.createdAt?.toDate?.() || data.createdAt,
          updatedAt: data.updatedAt?.toDate?.() || data.updatedAt,
        };
      })
    );

    return machines;
  }

  async approveMachine(id: string) {
    const ref = this.db.collection('machines').doc(id);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundException('Machine not found');
    await ref.update({
      status: 'active',
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { success: true, id, status: 'active' };
  }

  async rejectMachine(id: string) {
    const ref = this.db.collection('machines').doc(id);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundException('Machine not found');
    await ref.update({
      status: 'blocked',
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { success: true, id, status: 'blocked' };
  }

  async getBookings() {
    const snap = await this.db.collection('bookings').get();
    const bookings = await Promise.all(
      snap.docs.map(async (doc) => {
        const data = doc.data();
        let renter: any = null;
        let owner: any = null;
        let machine: any = null;

        if (data.renterId) {
          const rDoc = await this.db.collection('users').doc(data.renterId).get();
          if (rDoc.exists) renter = { id: rDoc.id, ...rDoc.data() };
        }
        if (data.ownerId) {
          const oDoc = await this.db.collection('users').doc(data.ownerId).get();
          if (oDoc.exists) owner = { id: oDoc.id, ...oDoc.data() };
        }
        if (data.machineId) {
          const mDoc = await this.db.collection('machines').doc(data.machineId).get();
          if (mDoc.exists) machine = { id: mDoc.id, ...mDoc.data() };
        }

        return {
          id: doc.id,
          ...data,
          renter,
          owner,
          machine,
          farmerName: renter?.name || 'Farmer',
          farmerPhone: renter?.phone || '—',
          ownerName: owner?.name || 'Owner',
          ownerPhone: owner?.phone || '—',
          machineModel: machine?.model || machine?.type || 'Farm Equipment',
          machineType: machine?.type || 'TRACTOR',
          totalAmount: Number(data.priceTotal) || 0,
          status: (data.status || 'CONFIRMED').toUpperCase(),
          createdAt: data.createdAt?.toDate?.() || data.createdAt,
        };
      })
    );

    return bookings;
  }

  async getUsers() {
    const snap = await this.db.collection('users').get();
    return snap.docs.map((doc) => {
      const data = doc.data();
      return {
        id: doc.id,
        ...data,
        createdAt: data.createdAt?.toDate?.() || data.createdAt,
      };
    });
  }

  async approveUserKyc(id: string) {
    const ref = this.db.collection('users').doc(id);
    const doc = await ref.get();
    if (!doc.exists) throw new NotFoundException('User not found');
    await ref.update({
      kycStatus: 'approved',
      updatedAt: FieldValue.serverTimestamp(),
    });
    return { success: true, id, kycStatus: 'approved' };
  }
}
