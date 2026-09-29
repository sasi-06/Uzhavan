import * as functions from 'firebase-functions/v1';

import { getFirestore } from 'firebase-admin/firestore';
import * as geofire from 'geofire-common';

export const searchNearbyMachines = functions.https.onCall(async (data, context) => {
  try {
    const { lat, lng, radius } = data;

    if (typeof lat !== 'number' || typeof lng !== 'number') {
      throw new functions.https.HttpsError('invalid-argument', 'Valid lat and lng are required.');
    }

    const initialRadiusInKm = typeof radius === 'number' ? radius : 15;
    const center = [lat, lng] as [number, number];

    const db = getFirestore();
    
    // A helper function to execute the geo query and filter
    const performSearch = async (searchRadiusKm: number) => {
      const radiusInM = searchRadiusKm * 1000;
      const bounds = geofire.geohashQueryBounds(center, radiusInM);
      
      const promises = bounds.map(b => {
        return db.collection('machines')
          .orderBy('location.geohash')
          .startAt(b[0])
          .endAt(b[1])
          .get();
      });

      const snapshots = await Promise.all(promises);
      const matchingDocs: any[] = [];

      for (const snap of snapshots) {
        for (const doc of snap.docs) {
          const machineData = doc.data();
          const machineLat = Number(machineData.location?.lat);
          const machineLng = Number(machineData.location?.lng);
          const serviceRadius = Number(machineData.serviceRadius) || 0; // in km

          if (!isNaN(machineLat) && !isNaN(machineLng)) {
            const distanceInKm = geofire.distanceBetween([machineLat, machineLng], center);
            
            // Check if machine is within user's requested radius
            // AND user is within the machine owner's service radius
            if (distanceInKm <= searchRadiusKm && distanceInKm <= serviceRadius) {
              
              // Privacy rule: Farmer sees Owner's approx service area/village only — never exact GPS pin
              const safeData = { ...machineData };
              delete safeData.latitude;
              delete safeData.longitude;
              if (safeData.location) {
                delete safeData.location.lat;
                delete safeData.location.lng;
                delete safeData.location.geohash;
              }

              matchingDocs.push({
                id: doc.id,
                ...safeData,
                distance: distanceInKm
              });
            }
          }
        }
      }

      // Sort by distance
      matchingDocs.sort((a, b) => a.distance - b.distance);
      return matchingDocs;
    };

    let results = await performSearch(initialRadiusInKm);
    let finalRadius = initialRadiusInKm;
    let autoWidened = false;

    // Auto-widen search radius if no machines found
    if (results.length === 0) {
      const widenedRadius = initialRadiusInKm * 2;
      results = await performSearch(widenedRadius);
      finalRadius = widenedRadius;
      autoWidened = true;
    }

    return {
      success: true,
      data: results,
      radiusUsed: finalRadius,
      autoWidened
    };
  } catch (error: any) {
    console.error("Error in searchNearbyMachines:", error);
    throw new functions.https.HttpsError('internal', error.message || 'Unknown internal error occurred.');
  }
});
