import 'package:geolocator/geolocator.dart';

import '../logging/app_logger.dart';

class LatLng {
  const LatLng(this.latitude, this.longitude);
  final double latitude;
  final double longitude;
}

/// Location is requested only when a screen explicitly needs it (e.g. "sort
/// by distance"), never on app start, and every failure path returns `null`
/// rather than throwing — spec section 18: "Never require GPS for every
/// application feature" and "Allow users to manually enter an address if
/// location permission is denied."
class LocationService {
  const LocationService();

  Future<LatLng?> getCurrentLocation() async {
    try {
      if (!await Geolocator.isLocationServiceEnabled()) return null;

      var permission = await Geolocator.checkPermission();
      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }
      if (permission == LocationPermission.denied ||
          permission == LocationPermission.deniedForever) {
        return null;
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(accuracy: LocationAccuracy.medium),
      );
      return LatLng(position.latitude, position.longitude);
    } catch (e, st) {
      AppLogger.warning('getCurrentLocation failed: $e');
      AppLogger.error('getCurrentLocation error detail', error: e, stackTrace: st);
      return null;
    }
  }
}
