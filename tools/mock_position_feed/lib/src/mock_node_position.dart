import 'package:meta/meta.dart';

/// A fabricated node position fix.
///
/// Deliberately self-contained (plain lat/lon fields, no `ocp_maps` types) so
/// this tool has no dependency on the package it is used to test.
@immutable
class MockNodePosition {
  const MockNodePosition({
    required this.nodeId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.altitudeMeters,
    this.headingDegrees,
    this.speedMps,
  });

  final String nodeId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? altitudeMeters;
  final double? headingDegrees;
  final double? speedMps;

  @override
  String toString() =>
      'MockNodePosition($nodeId, ${latitude.toStringAsFixed(6)}, '
      '${longitude.toStringAsFixed(6)}, ${timestamp.toIso8601String()})';
}
