import 'dart:math';

/// Offline sunrise/sunset calculator using NOAA solar equations.
/// No network dependency — pure math from lat/lng + date.
class SolarService {
  static const _defaultLat = 31.8980; // Ramallah
  static const _defaultLng = 35.2042;
  static const _zenith = 96.0; // Civil twilight: sun 6° below horizon

  /// Calculate sunrise and sunset for given location and date.
  /// Returns null times for polar regions with no sunrise/sunset.
  static ({DateTime? sunrise, DateTime? sunset}) calculate({
    double lat = _defaultLat,
    double lng = _defaultLng,
    DateTime? date,
  }) {
    final d = date ?? DateTime.now();
    final dayOfYear = _dayOfYear(d);

    final sunrise = _calcTime(dayOfYear, lat, lng, true, d);
    final sunset = _calcTime(dayOfYear, lat, lng, false, d);
    return (sunrise: sunrise, sunset: sunset);
  }

  /// Is it currently dark (after sunset or before sunrise)?
  static bool isDark({double lat = _defaultLat, double lng = _defaultLng}) {
    final times = calculate(lat: lat, lng: lng);
    if (times.sunrise == null || times.sunset == null) return false;
    final now = DateTime.now();
    return now.isBefore(times.sunrise!) || now.isAfter(times.sunset!);
  }

  static DateTime? _calcTime(int dayOfYear, double lat, double lng, bool isSunrise, DateTime date) {
    // Convert longitude to hour value
    final lngHour = lng / 15.0;

    // Approximate time
    final t = isSunrise
        ? dayOfYear + ((6 - lngHour) / 24)
        : dayOfYear + ((18 - lngHour) / 24);

    // Sun's mean anomaly
    final m = (0.9856 * t) - 3.289;

    // Sun's true longitude
    var l = m + (1.916 * _sin(m)) + (0.020 * _sin(2 * m)) + 282.634;
    l = l % 360;

    // Sun's right ascension
    var ra = _atan(0.91764 * _tan(l));
    ra = ra % 360;

    // Adjust RA to same quadrant as L
    final lQuad = (l / 90).floor() * 90;
    final raQuad = (ra / 90).floor() * 90;
    ra += (lQuad - raQuad);
    ra /= 15; // Convert to hours

    // Sun's declination
    final sinDec = 0.39782 * _sin(l);
    final cosDec = _cos(_asin(sinDec));

    // Sun's local hour angle
    final cosH = (_cos(_zenith) - (sinDec * _sin(lat))) / (cosDec * _cos(lat));

    // No sunrise/sunset (polar)
    if (cosH > 1 || cosH < -1) return null;

    final h = isSunrise ? (360 - _acos(cosH)) / 15 : _acos(cosH) / 15;

    // Local mean time of event
    final localMeanTime = h + ra - (0.06571 * t) - 6.622;

    // UTC time
    var utc = localMeanTime - lngHour;
    utc = utc % 24;

    final hour = utc.floor();
    final minute = ((utc - hour) * 60).round();

    return DateTime(date.year, date.month, date.day, hour, minute).toLocal();
  }

  static int _dayOfYear(DateTime d) =>
      d.difference(DateTime(d.year, 1, 1)).inDays + 1;

  static double _sin(double deg) => sin(deg * pi / 180);
  static double _cos(double deg) => cos(deg * pi / 180);
  static double _tan(double deg) => tan(deg * pi / 180);
  static double _asin(double x) => asin(x) * 180 / pi;
  static double _acos(double x) => acos(x) * 180 / pi;
  static double _atan(double x) => atan(x) * 180 / pi;
}
