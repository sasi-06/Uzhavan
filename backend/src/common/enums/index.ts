export enum UserRole {
  FARMER = 'farmer',
  OWNER = 'owner',
  BOTH = 'both',
  ADMIN = 'admin',
}

export enum KycStatus {
  PENDING = 'pending',
  SUBMITTED = 'submitted',
  APPROVED = 'approved',
  REJECTED = 'rejected',
}

export enum PreferredLanguage {
  TAMIL = 'ta',
  TELUGU = 'te',
  HINDI = 'hi',
  ENGLISH = 'en',
}

export enum MachineType {
  TRACTOR = 'tractor',
  HARVESTER = 'harvester',
  PLOUGH = 'plough',
  SEEDER = 'seeder',
  SPRAYER = 'sprayer',
  OTHER = 'other',
}

export enum MachineStatus {
  DRAFT = 'draft',
  PENDING_APPROVAL = 'pending_approval',
  ACTIVE = 'active',
  MAINTENANCE = 'maintenance',
  INACTIVE = 'inactive',
}

export enum BookingStatus {
  PENDING = 'pending',       // Farmer sent request; awaiting owner action
  ACCEPTED = 'accepted',     // Owner accepted; machine is booked/locked
  CONFIRMED = 'confirmed',   // Both sides confirmed; ready for work
  IN_PROGRESS = 'in_progress',
  COMPLETED = 'completed',
  CANCELLED = 'cancelled',
  DISPUTED = 'disputed',
}

export enum PaymentMode {
  UPI = 'upi',
  CASH = 'cash',
}

export enum PaymentStatus {
  PENDING = 'pending',
  HELD = 'held',
  RELEASED = 'released',
  REFUNDED = 'refunded',
  FAILED = 'failed',
}

export enum DisputeStatus {
  OPEN = 'open',
  UNDER_REVIEW = 'under_review',
  RESOLVED = 'resolved',
  CLOSED = 'closed',
}
