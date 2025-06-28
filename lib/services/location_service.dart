import 'package:geolocator/geolocator.dart';

class LocationService {
  /// Checks and requests location permissions, then returns current position.
  Future<Position> getCurrentLocation() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Check if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled, throw error or prompt user
      throw Exception('Location services are disabled. Please enable them in settings.');
    }

    // Check permission status.
    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw Exception('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever
      throw Exception(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // If permissions are granted, get position
    return await Geolocator.getCurrentPosition();
  }
}

// Usage example in your code:
// final location = await LocationService().getCurrentLocation();
// final userLatLng = LatLng(location.latitude, location.longitude);
