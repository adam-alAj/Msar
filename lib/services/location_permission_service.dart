import 'package:geolocator/geolocator.dart';

enum LocationResult { granted, denied, deniedForever, serviceDisabled }

class LocationPermissionService {
  /// Check current permission state without requesting.
  Future<LocationResult> checkStatus() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationResult.serviceDisabled;
    }
    final perm = await Geolocator.checkPermission();
    return _mapPermission(perm);
  }

  /// Request permission from the system.
  Future<LocationResult> request() async {
    if (!await Geolocator.isLocationServiceEnabled()) {
      return LocationResult.serviceDisabled;
    }
    final perm = await Geolocator.requestPermission();
    return _mapPermission(perm);
  }

  /// Get current position (call only after granted).
  Future<Position> getPosition() => Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 10),
        ),
      );

  /// Open device app settings (for deniedForever).
  Future<bool> openSettings() => Geolocator.openAppSettings();

  /// Open device location settings (for serviceDisabled).
  Future<bool> openLocationSettings() => Geolocator.openLocationSettings();

  LocationResult _mapPermission(LocationPermission perm) {
    switch (perm) {
      case LocationPermission.always:
      case LocationPermission.whileInUse:
        return LocationResult.granted;
      case LocationPermission.deniedForever:
        return LocationResult.deniedForever;
      default:
        return LocationResult.denied;
    }
  }
}
