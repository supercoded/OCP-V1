import 'dart:math' as math;

import 'package:meta/meta.dart';
import 'package:ocp_maps/src/geo/geo_point.dart';

/// A derived ground velocity: speed plus the course it is travelling.
@immutable
class GroundVelocity {
  const GroundVelocity({required this.speedMps, required this.courseDegrees});

  /// Ground speed in meters per second.
  final double speedMps;

  /// Course over ground, degrees true `[0, 360)`.
  final double courseDegrees;

  @override
  bool operator ==(Object other) =>
      other is GroundVelocity &&
      other.speedMps == speedMps &&
      other.courseDegrees == courseDegrees;

  @override
  int get hashCode => Object.hash(speedMps, courseDegrees);
}

/// Great-circle geodesy on a spherical earth.
///
/// Pure math — no I/O, no Flutter. This is the unit-testable heart of the
/// sonar view, exercised against synthetic feeds before any real GPS fix.
abstract final class GeoMath {
  /// Mean earth radius in meters (spherical model).
  static const double earthRadiusMeters = 6371000.0;

  static double _degToRad(double degrees) => degrees * math.pi / 180.0;

  static double _radToDeg(double radians) => radians * 180.0 / math.pi;

  /// Normalizes [degrees] into the `[0, 360)` range.
  static double normalizeDegrees(double degrees) {
    final wrapped = degrees % 360.0;
    return wrapped < 0 ? wrapped + 360.0 : wrapped;
  }

  /// Haversine great-circle distance between [a] and [b], in meters.
  static double distanceMeters(GeoPoint a, GeoPoint b) {
    final lat1 = _degToRad(a.latitude);
    final lat2 = _degToRad(b.latitude);
    final dLat = _degToRad(b.latitude - a.latitude);
    final dLon = _degToRad(b.longitude - a.longitude);

    final h = math.sin(dLat / 2) * math.sin(dLat / 2) +
        math.cos(lat1) * math.cos(lat2) * math.sin(dLon / 2) * math.sin(dLon / 2);
    final c = 2 * math.atan2(math.sqrt(h), math.sqrt(1 - h));
    return earthRadiusMeters * c;
  }

  /// Initial great-circle bearing from [from] to [to], degrees true `[0, 360)`.
  static double initialBearingDegrees(GeoPoint from, GeoPoint to) {
    final lat1 = _degToRad(from.latitude);
    final lat2 = _degToRad(to.latitude);
    final dLon = _degToRad(to.longitude - from.longitude);

    final y = math.sin(dLon) * math.cos(lat2);
    final x = math.cos(lat1) * math.sin(lat2) -
        math.sin(lat1) * math.cos(lat2) * math.cos(dLon);
    return normalizeDegrees(_radToDeg(math.atan2(y, x)));
  }

  /// Ground velocity derived from two consecutive fixes.
  ///
  /// Returns `null` when the time delta is zero or negative (cannot derive a
  /// meaningful speed).
  static GroundVelocity? velocityBetween(
    GeoPoint from,
    DateTime fromTime,
    GeoPoint to,
    DateTime toTime,
  ) {
    final dtSeconds = toTime.difference(fromTime).inMicroseconds / 1e6;
    if (dtSeconds <= 0) return null;
    final distance = distanceMeters(from, to);
    return GroundVelocity(
      speedMps: distance / dtSeconds,
      courseDegrees: initialBearingDegrees(from, to),
    );
  }
}
