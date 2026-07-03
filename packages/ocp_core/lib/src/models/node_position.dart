/// Where a position fix originated.
enum PositionSource { direct, relayed }

/// A single position fix for a node (domain model).
///
/// Positions are recorded as a *history*, not a single latest fix, so the
/// sonar view can derive motion vectors for moving nodes.
class NodePosition {
  const NodePosition({
    required this.nodeId,
    required this.latitude,
    required this.longitude,
    required this.timestamp,
    this.altitude,
    this.heading,
    this.speedMps,
    this.source = PositionSource.direct,
  });

  final String nodeId;
  final double latitude;
  final double longitude;
  final DateTime timestamp;
  final double? altitude;
  final double? heading;
  final double? speedMps;
  final PositionSource source;
}
