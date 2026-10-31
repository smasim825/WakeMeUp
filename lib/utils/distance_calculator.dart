import 'dart:math' as math;

/// Offline Haversine distance calculator and formatter.
class DistanceCalculator {
  DistanceCalculator._();

  static const double earthRadiusMeters = 6371000.0;

  /// Calculate great-circle distance between two GPS coordinates in meters.
  /// 100% offline, pure mathematics.
  static double distanceBetween(
    double startLatitude,
    double startLongitude,
    double endLatitude,
    double endLongitude,
  ) {
    final double dLat = _degreesToRadians(endLatitude - startLatitude);
    final double dLon = _degreesToRadians(endLongitude - startLongitude);

    final double lat1Rad = _degreesToRadians(startLatitude);
    final double lat2Rad = _degreesToRadians(endLatitude);

    final double a = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1Rad) * math.cos(lat2Rad) *
        math.sin(dLon / 2) * math.sin(dLon / 2);

    final double c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return earthRadiusMeters * c;
  }

  static double _degreesToRadians(double degrees) {
    return degrees * (math.pi / 180.0);
  }

  /// Format distance nicely: "450 m" if < 1000m, "12.4 km" if >= 1000m.
  static String formatDistance(double meters) {
    if (meters < 0) return '0 m';
    if (meters < 1000) {
      return '${meters.round()} m';
    } else {
      final km = meters / 1000.0;
      if (km < 10) {
        return '${km.toStringAsFixed(2)} km';
      } else {
        return '${km.toStringAsFixed(1)} km';
      }
    }
  }

  /// Calculate progress percentage (0.0 to 1.0)
  static double calculateProgress(double initialDistanceMeters, double remainingDistanceMeters) {
    if (initialDistanceMeters <= 0) return 1.0;
    final progress = (initialDistanceMeters - remainingDistanceMeters) / initialDistanceMeters;
    return progress.clamp(0.0, 1.0);
  }

  /// Calculate bearing in degrees from point 1 to point 2 (0° - 360°)
  static double calculateBearing(
    double startLat,
    double startLng,
    double endLat,
    double endLng,
  ) {
    final double lat1 = _degreesToRadians(startLat);
    final double lat2 = _degreesToRadians(endLat);
    final double dLon = _degreesToRadians(endLng - startLng);

    final double y = math.sin(dLon) * math.cos(lat2);
    final double x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);

    final double radians = math.atan2(y, x);
    final double degrees = radians * (180.0 / math.pi);
    return (degrees + 360.0) % 360.0;
  }
}
