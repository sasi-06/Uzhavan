import * as functions from 'firebase-functions/v1';

import { getFirestore, FieldValue } from 'firebase-admin/firestore';

export const confirmBooking = functions.firestore
  .document('bookings/{bookingId}')
  .onUpdate(async (change, context) => {
    const newValue = change.after.data();
    const previousValue = change.before.data();

    // Only proceed if status changed to 'confirmed'
    if (newValue.status === 'confirmed' && previousValue.status !== 'confirmed') {
      const bookingId = context.params.bookingId;
      const db = getFirestore();

      try {
        // Fetch the private location
        const privateLocDoc = await db.collection('bookings').doc(bookingId).collection('private_data').doc('location').get();
        
        if (privateLocDoc.exists) {
          const locationData = privateLocDoc.data();
          
          // Copy to the main booking doc so the owner can see the exact pin
          await change.after.ref.update({
            exactLocation: {
              lat: locationData?.lat,
              lng: locationData?.lng
            },
            locationRevealedAt: FieldValue.serverTimestamp()
          });
          
          console.log(`Revealed exact location for booking ${bookingId}`);
        } else {
          console.warn(`No private location found for booking ${bookingId}`);
        }
      } catch (error) {
        console.error(`Error copying location for booking ${bookingId}:`, error);
      }
    }
    
    return null;
  });
