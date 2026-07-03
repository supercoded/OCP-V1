/// A Meshtastic position fix (simplified domain model).
///
/// Meshtastic's on-air `Position` is a protobuf with many optional fields; this
/// bridge carries the subset the app needs (lat/lon/alt/time). Coordinates use
/// Meshtastic's integer convention: degrees × 1e7.
class MeshtasticPosition {
  const MeshtasticPosition({
    required this.latitude,
    required this.longitude,
    this.altitudeMeters,
    this.time,
  });

  final double latitude;
  final double longitude;
  final double? altitudeMeters;
  final DateTime? time;

  /// Builds from Meshtastic integer fields.
  factory MeshtasticPosition.fromIntegers({
    required int latitudeI,
    required int longitudeI,
    int? altitudeMeters,
    int? unixSeconds,
  }) {
    return MeshtasticPosition(
      latitude: latitudeI / 1e7,
      longitude: longitudeI / 1e7,
      altitudeMeters: altitudeMeters?.toDouble(),
      time: unixSeconds == null || unixSeconds == 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              unixSeconds * 1000,
              isUtc: true,
            ),
    );
  }

  int get latitudeI => (latitude * 1e7).round();
  int get longitudeI => (longitude * 1e7).round();
  int get altitudeI => (altitudeMeters ?? 0).round();
  int get unixSeconds =>
      time == null ? 0 : time!.toUtc().millisecondsSinceEpoch ~/ 1000;
}
