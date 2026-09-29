import { Injectable, Logger } from '@nestjs/common';
import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import { v4 as uuidv4 } from 'uuid';
import { MachineStatus, MachineType, UserRole, KycStatus, PreferredLanguage } from '../common/enums';

@Injectable()
export class SeedService {
  private readonly logger = new Logger(SeedService.name);

  async run() {
    const db = getFirestore();
    const machinesSnap = await db.collection('machines').limit(1).get();
    if (!machinesSnap.empty) {
      this.logger.log('Database already seeded, skipping');
      return;
    }

    let owner: any = null;
    let ownerId = '';

    const usersSnap = await db
      .collection('users')
      .where('phone', '==', '9876543210')
      .limit(1)
      .get();

    if (usersSnap.empty) {
      ownerId = uuidv4();
      owner = {
        id: ownerId,
        name: 'Ravi Tractors',
        phone: '9876543210',
        role: UserRole.OWNER,
        preferredLanguage: PreferredLanguage.TAMIL,
        kycStatus: KycStatus.APPROVED,
        latitude: 13.0827,
        longitude: 80.2707,
        kycDocumentUrl: null,
        fcmTokens: [],
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      };
      await db.collection('users').doc(ownerId).set(owner);
    } else {
      ownerId = usersSnap.docs[0].id;
      owner = usersSnap.docs[0].data();
    }

    const machines = [
      {
        type: MachineType.TRACTOR,
        model: 'Mahindra 575',
        pricePerHour: 800,
        pricePerAcre: 1200,
        latitude: 13.085,
        longitude: 80.275,
        operatorIncluded: true,
      },
      {
        type: MachineType.HARVESTER,
        model: 'Kartar 4000',
        pricePerHour: 1500,
        pricePerAcre: 2000,
        latitude: 13.078,
        longitude: 80.265,
        operatorIncluded: true,
      },
      {
        type: MachineType.PLOUGH,
        model: 'Standard 3-disc',
        pricePerHour: 400,
        pricePerAcre: 600,
        latitude: 13.09,
        longitude: 80.28,
        operatorIncluded: false,
      },
      {
        type: MachineType.SEEDER,
        model: 'VST Seeder Pro',
        pricePerHour: 500,
        pricePerAcre: 800,
        latitude: 13.075,
        longitude: 80.26,
        operatorIncluded: false,
      },
    ];

    for (const m of machines) {
      const id = uuidv4();
      const machine = {
        id,
        ownerId,
        type: m.type,
        model: m.model,
        pricePerHour: m.pricePerHour,
        pricePerAcre: m.pricePerAcre,
        latitude: m.latitude,
        longitude: m.longitude,
        operatorIncluded: m.operatorIncluded,
        status: MachineStatus.ACTIVE,
        serviceRadiusKm: 25,
        photos: [],
        createdAt: FieldValue.serverTimestamp(),
        updatedAt: FieldValue.serverTimestamp(),
      };
      await db.collection('machines').doc(id).set(machine);
    }

    this.logger.log(`Seeded ${machines.length} machines for owner ${owner.phone}`);
    this.logger.log('Demo farmer login: register with any new phone, or use owner 9876543210');
  }
}
