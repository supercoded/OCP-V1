import 'package:mock_position_feed/src/geo.dart';
import 'package:mock_position_feed/src/mock_node_position.dart';

/// A scripted node whose position is a deterministic function of elapsed time.
abstract class MockNode {
  String get id;

  /// Position of this node [elapsedSeconds] after the feed epoch.
  MockNodePosition positionAt(double elapsedSeconds, DateTime timestamp);
}

/// A node that never moves.
class StationaryNode implements MockNode {
  StationaryNode({
    required this.id,
    required this.latitude,
    required this.longitude,
    this.altitudeMeters,
  });

  @override
  final String id;
  final double latitude;
  final double longitude;
  final double? altitudeMeters;

  @override
  MockNodePosition positionAt(double elapsedSeconds, DateTime timestamp) {
    return MockNodePosition(
      nodeId: id,
      latitude: latitude,
      longitude: longitude,
      altitudeMeters: altitudeMeters,
      speedMps: 0,
      timestamp: timestamp,
    );
  }
}

/// A node travelling in a straight line at constant speed and bearing.
class LinearNode implements MockNode {
  LinearNode({
    required this.id,
    required this.startLatitude,
    required this.startLongitude,
    required this.bearingDegrees,
    required this.speedMps,
  });

  @override
  final String id;
  final double startLatitude;
  final double startLongitude;
  final double bearingDegrees;
  final double speedMps;

  @override
  MockNodePosition positionAt(double elapsedSeconds, DateTime timestamp) {
    final point = MockGeo.destination(
      startLatitude,
      startLongitude,
      bearingDegrees,
      speedMps * elapsedSeconds,
    );
    return MockNodePosition(
      nodeId: id,
      latitude: point.lat,
      longitude: point.lon,
      headingDegrees: bearingDegrees,
      speedMps: speedMps,
      timestamp: timestamp,
    );
  }
}

/// A node orbiting a center point at constant angular speed.
class CircularNode implements MockNode {
  CircularNode({
    required this.id,
    required this.centerLatitude,
    required this.centerLongitude,
    required this.radiusMeters,
    required this.angularSpeedDegPerSec,
    this.startAngleDegrees = 0,
  });

  @override
  final String id;
  final double centerLatitude;
  final double centerLongitude;
  final double radiusMeters;
  final double angularSpeedDegPerSec;
  final double startAngleDegrees;

  @override
  MockNodePosition positionAt(double elapsedSeconds, DateTime timestamp) {
    final angle = startAngleDegrees + angularSpeedDegPerSec * elapsedSeconds;
    final point = MockGeo.destination(
      centerLatitude,
      centerLongitude,
      angle,
      radiusMeters,
    );
    // Tangential heading is 90° ahead of the radial bearing for a positive orbit.
    final heading = (angle + 90) % 360;
    final circumferenceSpeed =
        (angularSpeedDegPerSec * 3.141592653589793 / 180.0) * radiusMeters;
    return MockNodePosition(
      nodeId: id,
      latitude: point.lat,
      longitude: point.lon,
      headingDegrees: heading < 0 ? heading + 360 : heading,
      speedMps: circumferenceSpeed.abs(),
      timestamp: timestamp,
    );
  }
}
