import 'package:meta/meta.dart';
import 'package:ocp_maps/src/geo/geo_point.dart';

/// One position observation of a node, fed into the sonar projector.
///
/// The app adapts `ocp_core`'s `NodePosition` domain model into this at the
/// edge, keeping `ocp_maps` free of storage/core coupling.
@immutable
class SonarSample {
  const SonarSample({
    required this.nodeId,
    required this.position,
    required this.timestamp,
    this.headingDegrees,
    this.speedMps,
    this.label,
  });

  final String nodeId;
  final GeoPoint position;
  final DateTime timestamp;

  /// Device-reported heading, degrees true, when available.
  final double? headingDegrees;

  /// Device-reported ground speed in m/s, when available.
  final double? speedMps;

  /// Human-readable label for the node (falls back to [nodeId] in the UI).
  final String? label;
}
