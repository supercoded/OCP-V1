import 'package:meta/meta.dart';

/// A WGS-84 geographic coordinate.
@immutable
class GeoPoint {
  const GeoPoint({
    required this.latitude,
    required this.longitude,
    this.altitudeMeters,
  });

  /// Latitude in degrees, `[-90, 90]`.
  final double latitude;

  /// Longitude in degrees, `[-180, 180]`.
  final double longitude;

  /// Altitude above the ellipsoid in meters, when known.
  final double? altitudeMeters;

  @override
  bool operator ==(Object other) =>
      other is GeoPoint &&
      other.latitude == latitude &&
      other.longitude == longitude &&
      other.altitudeMeters == altitudeMeters;

  @override
  int get hashCode => Object.hash(latitude, longitude, altitudeMeters);

  @override
  String toString() =>
      'GeoPoint($latitude, $longitude${altitudeMeters == null ? '' : ', ${altitudeMeters}m'})';
}
