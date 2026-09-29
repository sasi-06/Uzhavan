import * as functions from 'firebase-functions/v1';

import { getFirestore, FieldValue } from 'firebase-admin/firestore';
import * as geofire from 'geofire-common';

export const createBookingRequest = functions.https.onCall(async (data, context) => {
  const { machineId, farmerLat, farmerLng, slotDates, hoursRequested, farmerVillage } = data;

  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'User must be logged in.');
  }
  
  if (!machineId || typeof farmerLat !== 'number' || typeof farmerLng !== 'number') {
    throw new functions.https.HttpsError('invalid-argument', 'Missing required fields.');
  }

  const farmerId = context.auth.uid;
  const db = getFirestore();
  
  try {
    const bookingResult = await db.runTransaction(async (transaction) => {
      const machineRef = db.collection('machines').doc(machineId);
      const machineDoc = await transaction.get(machineRef);
      
      if (!machineDoc.exists) {
        throw new functions.https.HttpsError('not-found', 'Machine not found.');
      }
      
      const machineData = machineDoc.data()!;
      const ownerId = machineData.ownerId;
      const ownerLat = machineData.location?.lat;
      const ownerLng = machineData.location?.lng;
      const serviceRadius = machineData.serviceRadius || 15;
      const basePricePerHour = machineData.pricePerHour || 0;
      // Default per-km rate or fetch from machine
      const transportRatePerKm = machineData.transportRatePerKm || 10; 

      if (!ownerLat || !ownerLng) {
        throw new functions.https.HttpsError('failed-precondition', 'Machine location is not set properly.');
      }

      // 1. Distance & Radius check
      const distanceInKm = geofire.distanceBetween([farmerLat, farmerLng], [ownerLat, ownerLng]);
      if (distanceInKm > serviceRadius) {
        throw new functions.https.HttpsError('failed-precondition', 'Your location is outside the owner\'s service radius.');
      }

      // 2. Transport cost calculation
      const transportCost = Math.round(distanceInKm * transportRatePerKm);
      const totalBasePrice = basePricePerHour * (hoursRequested || 1);
      const totalPrice = totalBasePrice + transportCost;

      // 3. Double booking check (simplified slot checking)
      // Assume a subcollection `bookedSlots` on machine to check availability
      if (slotDates && slotDates.length > 0) {
        for (const date of slotDates) {
          const slotRef = machineRef.collection('bookedSlots').doc(date);
          const slotDoc = await transaction.get(slotRef);
          if (slotDoc.exists && slotDoc.data()?.isBooked) {
             throw new functions.https.HttpsError('already-exists', `Slot on ${date} is already booked.`);
          }
        }
      }

      // 4. Create the booking document
      const newBookingRef = db.collection('bookings').doc();
      const bookingData = {
        machineId,
        farmerId,
        ownerId,
        status: 'pending',
        farmerVillage: farmerVillage || 'Unknown', // Approximate location shared initially
        // Exact location NOT stored in the shared fields yet
        createdAt: FieldValue.serverTimestamp(),
        priceBreakdown: {
          basePrice: totalBasePrice,
          transportCost: transportCost,
          total: totalPrice
        },
        slotDates: slotDates || [],
        hoursRequested
      };

      transaction.set(newBookingRef, bookingData);

      // 5. Store exact coordinates in a restricted subcollection
      const privateLocationRef = newBookingRef.collection('private_data').doc('location');
      transaction.set(privateLocationRef, {
        lat: farmerLat,
        lng: farmerLng
      });

      // 6. Lock slots tentatively
      if (slotDates && slotDates.length > 0) {
        for (const date of slotDates) {
          const slotRef = machineRef.collection('bookedSlots').doc(date);
          transaction.set(slotRef, { isBooked: true, bookingId: newBookingRef.id });
        }
      }

      return { bookingId: newBookingRef.id, totalPrice, transportCost, distanceInKm };
    });

    return { success: true, ...bookingResult };
  } catch (error: any) {
    console.error('Transaction failed:', error);
    throw new functions.https.HttpsError('internal', error.message || 'Booking transaction failed.');
  }
});
