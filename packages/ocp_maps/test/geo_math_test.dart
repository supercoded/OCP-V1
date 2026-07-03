import 'package:ocp_maps/ocp_maps.dart';
import 'package:test/test.dart';

void main() {
  group('GeoMath', () {
    const origin = GeoPoint(latitude: 0, longitude: 0);

    test('distance of one degree of longitude at the equator', () {
      const east = GeoPoint(latitude: 0, longitude: 1);
      expect(GeoMath.distanceMeters(origin, east), closeTo(111195, 5));
    });

    test('distance is symmetric and zero for identical points', () {
      const a = GeoPoint(latitude: 37.0, longitude: -122.0);
      const b = GeoPoint(latitude: 40.0, longitude: -73.0);
      expect(GeoMath.distanceMeters(a, a), 0);
      expect(
        GeoMath.distanceMeters(a, b),
        closeTo(GeoMath.distanceMeters(b, a), 1e-6),
      );
    });

    test('bearing is north, east, south, west for cardinal offsets', () {
      expect(
        GeoMath.initialBearingDegrees(
          origin,
          const GeoPoint(latitude: 1, longitude: 0),
        ),
        closeTo(0, 1e-6),
      );
      expect(
        GeoMath.initialBearingDegrees(
          origin,
          const GeoPoint(latitude: 0, longitude: 1),
        ),
        closeTo(90, 1e-6),
      );
      expect(
        GeoMath.initialBearingDegrees(
          origin,
          const GeoPoint(latitude: -1, longitude: 0),
        ),
        closeTo(180, 1e-6),
      );
      expect(
        GeoMath.initialBearingDegrees(
          origin,
          const GeoPoint(latitude: 0, longitude: -1),
        ),
        closeTo(270, 1e-6),
      );
    });

    test('velocity derives speed and course from two fixes', () {
      final t0 = DateTime.utc(2026);
      final t1 = t0.add(const Duration(seconds: 100));
      final v = GeoMath.velocityBetween(
        origin,
        t0,
        const GeoPoint(latitude: 0, longitude: 0.01),
        t1,
      );
      expect(v, isNotNull);
      expect(v!.courseDegrees, closeTo(90, 1e-3));
      // ~1113 m over 100 s ≈ 11.1 m/s.
      expect(v.speedMps, closeTo(11.1, 0.2));
    });

    test('velocity is null for non-positive time delta', () {
      final t0 = DateTime.utc(2026);
      expect(
        GeoMath.velocityBetween(origin, t0, origin, t0),
        isNull,
      );
    });
  });
}
