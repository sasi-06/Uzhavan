export interface MachineListing {
  id: string;
  model: string;
  type: 'TRACTOR' | 'HARVESTER' | 'POWER_TILLER' | 'ROTAVATOR' | 'DRONE_SPRAYER';
  ownerName: string;
  ownerPhone: string;
  district: string;
  village: string;
  pricePerHour: number;
  pricePerAcre: number;
  operatorIncluded: boolean;
  kycStatus: 'APPROVED' | 'PENDING' | 'REJECTED';
  status: 'ACTIVE' | 'PENDING_APPROVAL' | 'MAINTENANCE' | 'BLOCKED';
  rating: number;
  totalBookings: number;
  photoUrl: string;
  registeredDate: string;
  hp: number;
}

export interface BookingRecord {
  id: string;
  farmerName: string;
  farmerPhone: string;
  machineModel: string;
  machineType: string;
  ownerName: string;
  location: string;
  date: string;
  hours: number;
  acres: number;
  totalAmount: number;
  paymentMode: 'UPI' | 'CASH_ON_DELIVERY' | 'ESCROW';
  status: 'PENDING' | 'CONFIRMED' | 'IN_PROGRESS' | 'COMPLETED' | 'DISPUTED';
  bookingSource: 'VOICE_TAMIL' | 'VOICE_HINDI' | 'VOICE_TELUGU' | 'MANUAL_APP';
}

export interface DisputeRecord {
  id: string;
  bookingId: string;
  farmerName: string;
  ownerName: string;
  machineModel: string;
  escrowAmount: number;
  reason: string;
  voiceTranscript: string;
  evidenceSummary: string;
  status: 'OPEN' | 'UNDER_REVIEW' | 'RESOLVED_FARMER' | 'RESOLVED_OWNER' | 'RESOLVED_SPLIT';
  dateRaised: string;
}

export const initialListings: MachineListing[] = [
  {
    id: 'm-101',
    model: 'Mahindra 575 DI (45 HP)',
    type: 'TRACTOR',
    ownerName: 'K. Murugan',
    ownerPhone: '+91 98421 77301',
    district: 'Thanjavur',
    village: 'Orathanadu',
    pricePerHour: 850,
    pricePerAcre: 1300,
    operatorIncluded: true,
    kycStatus: 'APPROVED',
    status: 'ACTIVE',
    rating: 4.8,
    totalBookings: 64,
    photoUrl: '🚜',
    registeredDate: '2026-08-14',
    hp: 45,
  },
  {
    id: 'm-102',
    model: 'Kubota Combine Harvester DC-68G',
    type: 'HARVESTER',
    ownerName: 'S. Ramanathan',
    ownerPhone: '+91 94432 11980',
    district: 'Tiruchirappalli',
    village: 'Lalgudi',
    pricePerHour: 2200,
    pricePerAcre: 2600,
    operatorIncluded: true,
    kycStatus: 'APPROVED',
    status: 'ACTIVE',
    rating: 4.9,
    totalBookings: 82,
    photoUrl: '🌾',
    registeredDate: '2026-07-22',
    hp: 68,
  },
  {
    id: 'm-103',
    model: 'John Deere 5050D 4WD',
    type: 'TRACTOR',
    ownerName: 'A. Selvam',
    ownerPhone: '+91 97880 44211',
    district: 'Madurai',
    village: 'Melur',
    pricePerHour: 950,
    pricePerAcre: 1400,
    operatorIncluded: false,
    kycStatus: 'PENDING',
    status: 'PENDING_APPROVAL',
    rating: 0,
    totalBookings: 0,
    photoUrl: '🚜',
    registeredDate: '2026-09-28',
    hp: 50,
  },
  {
    id: 'm-104',
    model: 'VST Shakti 130DI Power Tiller',
    type: 'POWER_TILLER',
    ownerName: 'P. Arumugam',
    ownerPhone: '+91 99443 88120',
    district: 'Salem',
    village: 'Attur',
    pricePerHour: 450,
    pricePerAcre: 750,
    operatorIncluded: true,
    kycStatus: 'APPROVED',
    status: 'ACTIVE',
    rating: 4.6,
    totalBookings: 39,
    photoUrl: '⚙️',
    registeredDate: '2026-08-01',
    hp: 13,
  },
  {
    id: 'm-105',
    model: 'Preet 987 Self-Propelled Harvester',
    type: 'HARVESTER',
    ownerName: 'C. Vellayan',
    ownerPhone: '+91 98940 33912',
    district: 'Thiruvarur',
    village: 'Mannargudi',
    pricePerHour: 2400,
    pricePerAcre: 2800,
    operatorIncluded: true,
    kycStatus: 'PENDING',
    status: 'PENDING_APPROVAL',
    rating: 0,
    totalBookings: 0,
    photoUrl: '🌾',
    registeredDate: '2026-09-29',
    hp: 101,
  },
  {
    id: 'm-106',
    model: 'Garuda Agri-Drone 16L Sprayer',
    type: 'DRONE_SPRAYER',
    ownerName: 'TechAgri Solutions (R. Karthik)',
    ownerPhone: '+91 90031 55667',
    district: 'Coimbatore',
    village: 'Pollachi',
    pricePerHour: 1200,
    pricePerAcre: 550,
    operatorIncluded: true,
    kycStatus: 'APPROVED',
    status: 'ACTIVE',
    rating: 4.9,
    totalBookings: 51,
    photoUrl: '🛸',
    registeredDate: '2026-06-15',
    hp: 0,
  },
  {
    id: 'm-107',
    model: 'Sonalika Tiger DI 50',
    type: 'TRACTOR',
    ownerName: 'M. Palanisamy',
    ownerPhone: '+91 94862 33100',
    district: 'Erode',
    village: 'Perundurai',
    pricePerHour: 900,
    pricePerAcre: 1350,
    operatorIncluded: true,
    kycStatus: 'PENDING',
    status: 'PENDING_APPROVAL',
    rating: 0,
    totalBookings: 0,
    photoUrl: '🚜',
    registeredDate: '2026-09-30',
    hp: 52,
  },
  {
    id: 'm-108',
    model: 'Shaktiman Rotary Tiller SRT-6',
    type: 'ROTAVATOR',
    ownerName: 'V. Sundaram',
    ownerPhone: '+91 93601 22894',
    district: 'Cuddalore',
    village: 'Chidambaram',
    pricePerHour: 550,
    pricePerAcre: 850,
    operatorIncluded: false,
    kycStatus: 'APPROVED',
    status: 'ACTIVE',
    rating: 4.5,
    totalBookings: 27,
    photoUrl: '🌱',
    registeredDate: '2026-07-10',
    hp: 40,
  }
];

export const initialBookings: BookingRecord[] = [
  {
    id: 'BK-2026-9041',
    farmerName: 'G. Kannan',
    farmerPhone: '+91 97910 88201',
    machineModel: 'Mahindra 575 DI',
    machineType: 'TRACTOR',
    ownerName: 'K. Murugan',
    location: 'Thanjavur, Orathanadu',
    date: 'Today, 08:30 AM',
    hours: 4,
    acres: 3.5,
    totalAmount: 4550,
    paymentMode: 'ESCROW',
    status: 'IN_PROGRESS',
    bookingSource: 'VOICE_TAMIL',
  },
  {
    id: 'BK-2026-9040',
    farmerName: 'D. Subramanian',
    farmerPhone: '+91 98402 11980',
    machineModel: 'Kubota Combine Harvester',
    machineType: 'HARVESTER',
    ownerName: 'S. Ramanathan',
    location: 'Tiruchirappalli, Lalgudi',
    date: 'Today, 07:00 AM',
    hours: 5,
    acres: 6,
    totalAmount: 15600,
    paymentMode: 'UPI',
    status: 'IN_PROGRESS',
    bookingSource: 'VOICE_TAMIL',
  },
  {
    id: 'BK-2026-9039',
    farmerName: 'N. Muthuvel',
    farmerPhone: '+91 93450 77112',
    machineModel: 'VST Shakti 130DI',
    machineType: 'POWER_TILLER',
    ownerName: 'P. Arumugam',
    location: 'Salem, Attur',
    date: 'Today, 06:15 AM',
    hours: 3,
    acres: 2,
    totalAmount: 1500,
    paymentMode: 'CASH_ON_DELIVERY',
    status: 'COMPLETED',
    bookingSource: 'MANUAL_APP',
  },
  {
    id: 'BK-2026-9038',
    farmerName: 'R. Rajesh',
    farmerPhone: '+91 91590 66200',
    machineModel: 'Mahindra 575 DI',
    machineType: 'TRACTOR',
    ownerName: 'K. Murugan',
    location: 'Pudukkottai, Alangudi',
    date: 'Yesterday',
    hours: 6,
    acres: 5,
    totalAmount: 6500,
    paymentMode: 'ESCROW',
    status: 'DISPUTED',
    bookingSource: 'VOICE_TAMIL',
  },
  {
    id: 'BK-2026-9037',
    farmerName: 'B. Maheshwar',
    farmerPhone: '+91 99520 44109',
    machineModel: 'Garuda Agri-Drone',
    machineType: 'DRONE_SPRAYER',
    ownerName: 'TechAgri Solutions',
    location: 'Coimbatore, Pollachi',
    date: 'Yesterday',
    hours: 2,
    acres: 8,
    totalAmount: 4400,
    paymentMode: 'UPI',
    status: 'COMPLETED',
    bookingSource: 'VOICE_TAMIL',
  }
];

export const initialDisputes: DisputeRecord[] = [
  {
    id: 'DSP-801',
    bookingId: 'BK-2026-9038',
    farmerName: 'R. Rajesh (Farmer)',
    ownerName: 'K. Murugan (Owner)',
    machineModel: 'Mahindra 575 DI',
    escrowAmount: 6500,
    reason: 'Machinery breakdown after 2 hours. Owner refused to complete 3 remaining acres.',
    voiceTranscript: '"ஐயா, 2 மணி நேரம் தான் ஓட்டுனாங்க, டயர் பஞ்சர்னு சொல்லிட்டு போயிட்டாங்க. பாக்கி 3 ஏக்கர் உழல. முழு பணம் கேக்குறாங்க." (Sir, only worked for 2 hours, then left citing flat tire. Remaining 3 acres left unploughed, yet demanding full payment)',
    evidenceSummary: 'Diesel audit logged 7 liters; GPS geofence showed machine departed field at 11:15 AM.',
    status: 'OPEN',
    dateRaised: 'Yesterday, 04:30 PM',
  },
  {
    id: 'DSP-802',
    bookingId: 'BK-2026-8992',
    farmerName: 'V. Sivakumar (Farmer)',
    ownerName: 'C. Vellayan (Owner)',
    machineModel: 'Preet 987 Harvester',
    escrowAmount: 8400,
    reason: 'Delay of 5 hours caused crop moisture penalty during sudden drizzle.',
    voiceTranscript: '"மழை வரதுக்கு முன்னாடி அறுவடை பண்ணனும்னு 7 மணிக்கு புக் பண்ணோம். 12 மணிக்கு தான் வந்தாங்க." (Booked for 7 AM to harvest before rain. They only arrived at 12 PM)',
    evidenceSummary: 'Farmer submitted photo of damp paddy sack; Weather alert logs confirmed rain at 11:00 AM.',
    status: 'UNDER_REVIEW',
    dateRaised: '2 days ago',
  }
];

export const districtDemandData = [
  { district: 'Thanjavur (Delta)', demandScore: 94, activeMachines: 42, topNeed: 'Paddy Harvesters', trend: '+28%' },
  { district: 'Tiruchirappalli', demandScore: 86, activeMachines: 34, topNeed: 'Medium Tractors', trend: '+18%' },
  { district: 'Madurai', demandScore: 78, activeMachines: 26, topNeed: 'Rotavators & Tillers', trend: '+12%' },
  { district: 'Coimbatore', demandScore: 72, activeMachines: 29, topNeed: 'Drones & Weeders', trend: '+35%' },
  { district: 'Salem & Erode', demandScore: 68, activeMachines: 22, topNeed: 'Power Tillers', trend: '+9%' },
];

export const voiceChannelStats = {
  voiceBookingPct: 71,
  manualTapPct: 29,
  languages: [
    { name: 'Tamil (தமிழ்)', pct: 76, color: 'bg-green-600' },
    { name: 'Telugu (తెలుగు)', pct: 15, color: 'bg-blue-600' },
    { name: 'Hindi (हिन्दी)', pct: 9, color: 'bg-amber-600' },
  ],
  accuracyRate: '96.4%',
  offlineFallbackHits: 384,
};
