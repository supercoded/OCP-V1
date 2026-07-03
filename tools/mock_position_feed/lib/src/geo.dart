import 'dart:math' as math;

/// Minimal spherical-earth geodesy for generating scripted paths.
///
/// Self-contained so this tool depends on nothing it is meant to test.
abstract final class MockGeo {
  static const double earthRadiusMeters = 6371000.0;

  static double _degToRad(double d) => d * math.pi / 180.0;

  static double _radToDeg(double r) => r * 180.0 / math.pi;

  /// Point reached by travelling [distanceMeters] along [bearingDegrees] from
  /// (`lat`, `lon`).
  static ({double lat, double lon}) destination(
    double lat,
    double lon,
    double bearingDegrees,
    double distanceMeters,
  ) {
    final angular = distanceMeters / earthRadiusMeters;
    final bearing = _degToRad(bearingDegrees);
    final lat1 = _degToRad(lat);
    final lon1 = _degToRad(lon);

    final lat2 = math.asin(
      math.sin(lat1) * math.cos(angular) +
          math.cos(lat1) * math.sin(angular) * math.cos(bearing),
    );
    final lon2 = lon1 +
        math.atan2(
          math.sin(bearing) * math.sin(angular) * math.cos(lat1),
          math.cos(angular) - math.sin(lat1) * math.sin(lat2),
        );

    return (lat: _radToDeg(lat2), lon: _radToDeg(lon2));
  }
}
