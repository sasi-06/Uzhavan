import * as functions from 'firebase-functions/v1';
import { Client } from '@googlemaps/google-maps-services-js';

const client = new Client({});

export const reverseGeocode = functions.https.onCall(async (data, context) => {
  const { lat, lng } = data;

  if (typeof lat !== 'number' || typeof lng !== 'number') {
    throw new functions.https.HttpsError('invalid-argument', 'Valid lat and lng are required.');
  }

  // Expecting the API key to be set via environment variable
  const apiKey = process.env.GOOGLE_MAPS_API_KEY;

  if (!apiKey) {
    throw new functions.https.HttpsError('failed-precondition', 'Google Maps API key is not configured on the server.');
  }

  try {
    const response = await client.reverseGeocode({
      params: {
        latlng: [lat, lng],
        key: apiKey,
      }
    });

    if (response.data.results && response.data.results.length > 0) {
      // Find district and village/locality
      const addressComponents = response.data.results[0].address_components;
      let district = '';
      let village = '';
      let state = '';

      for (const component of addressComponents) {
        if (component.types.includes('locality' as any) || component.types.includes('sublocality' as any)) {
          if (!village) village = component.long_name;
        }
        if (component.types.includes('administrative_area_level_2' as any)) {
          district = component.long_name;
        }
        if (component.types.includes('administrative_area_level_1' as any)) {
          state = component.long_name;
        }
      }

      return {
        success: true,
        address: response.data.results[0].formatted_address,
        village,
        district,
        state
      };
    } else {
      return { success: false, message: 'No results found' };
    }
  } catch (error) {
    console.error('Reverse Geocoding Error:', error);
    throw new functions.https.HttpsError('internal', 'Failed to reverse geocode location.');
  }
});
