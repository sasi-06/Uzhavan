import 'package:geolocator/geolocator.dart';
import 'package:cloud_functions/cloud_functions.dart';

class LocationService {
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  Future<bool> requestLocationPermission() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      return false;
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      // Prompt with an explanation before OS dialog using permission_handler if needed,
      // but Geolocator.requestPermission() handles the OS prompt.
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        return false;
      }
    }

    if (permission == LocationPermission.deniedForever) {
      return false;
    }

    return true;
  }

  Future<Position?> getCurrentLocation() async {
    final hasPermission = await requestLocationPermission();
    if (!hasPermission) return null;

    try {
      return await Geolocator.getCurrentPosition();
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> reverseGeocode(double lat, double lng) async {
    try {
      final HttpsCallable callable = _functions.httpsCallable('reverseGeocode');
      final result = await callable.call(<String, dynamic>{
        'lat': lat,
        'lng': lng,
      });
      if (result.data['success'] == true) {
        return {
          'village': result.data['village'],
          'district': result.data['district'],
          'state': result.data['state'],
        };
      }
    } catch (e) {
      print('Error reverse geocoding: $e');
    }
    return null;
  }
}
