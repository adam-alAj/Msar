import 'package:latlong2/latlong.dart';

class Governorate {
  final String id;
  final String nameAr;
  final LatLng center;
  final double north, south, east, west;

  const Governorate({
    required this.id,
    required this.nameAr,
    required this.center,
    required this.north,
    required this.south,
    required this.east,
    required this.west,
  });

  bool contains(double lat, double lng) =>
      lat >= south && lat <= north && lng >= west && lng <= east;

  static const List<Governorate> all = [
    Governorate(id: 'ramallah', nameAr: 'رام الله', center: LatLng(31.9038, 35.2034), north: 32.04, south: 31.80, east: 35.32, west: 35.08),
    Governorate(id: 'nablus', nameAr: 'نابلس', center: LatLng(32.2211, 35.2544), north: 32.35, south: 32.10, east: 35.45, west: 35.10),
    Governorate(id: 'hebron', nameAr: 'الخليل', center: LatLng(31.5326, 35.0998), north: 31.70, south: 31.35, east: 35.25, west: 34.90),
    Governorate(id: 'bethlehem', nameAr: 'بيت لحم', center: LatLng(31.7054, 35.2024), north: 31.80, south: 31.60, east: 35.35, west: 35.08),
    Governorate(id: 'jericho', nameAr: 'أريحا', center: LatLng(31.8611, 35.4607), north: 32.05, south: 31.70, east: 35.60, west: 35.32),
    Governorate(id: 'jenin', nameAr: 'جنين', center: LatLng(32.4610, 35.2953), north: 32.60, south: 32.35, east: 35.45, west: 35.10),
    Governorate(id: 'tulkarm', nameAr: 'طولكرم', center: LatLng(32.3104, 35.0286), north: 32.40, south: 32.20, east: 35.15, west: 34.90),
    Governorate(id: 'qalqilya', nameAr: 'قلقيلية', center: LatLng(32.1893, 34.9706), north: 32.28, south: 32.10, east: 35.08, west: 34.87),
    Governorate(id: 'salfit', nameAr: 'سلفيت', center: LatLng(32.0853, 35.1727), north: 32.18, south: 32.00, east: 35.28, west: 35.05),
    Governorate(id: 'tubas', nameAr: 'طوباس', center: LatLng(32.3226, 35.3717), north: 32.45, south: 32.20, east: 35.55, west: 35.25),
  ];

  static Governorate? fromCoordinates(double lat, double lng) {
    for (final gov in all) {
      if (gov.contains(lat, lng)) return gov;
    }
    // Nearest within ~15km fallback
    double minDist = double.infinity;
    Governorate? nearest;
    for (final gov in all) {
      final d = _distSq(lat, lng, gov.center.latitude, gov.center.longitude);
      if (d < minDist) { minDist = d; nearest = gov; }
    }
    return minDist < 0.0225 ? nearest : null; // ~15km threshold
  }

  static double _distSq(double lat1, double lng1, double lat2, double lng2) =>
      (lat1 - lat2) * (lat1 - lat2) + (lng1 - lng2) * (lng1 - lng2);
}
