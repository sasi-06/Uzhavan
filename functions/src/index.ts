import * as admin from 'firebase-admin';

// Initialize the Firebase Admin SDK
admin.initializeApp();

// Export Cloud Functions
export { searchNearbyMachines } from './search/searchNearbyMachines';
export { reverseGeocode } from './geocoding/reverseGeocode';
export { createBookingRequest } from './bookings/createBookingRequest';
export { confirmBooking } from './bookings/confirmBooking';
