import 'package:meta/meta.dart';

/// A 2D point in sonar-canvas pixel space (origin top-left, y grows downward).
@immutable
class ScreenOffset {
  const ScreenOffset(this.dx, this.dy);

  final double dx;
  final double dy;

  @override
  bool operator ==(Object other) =>
      other is ScreenOffset && other.dx == dx && other.dy == dy;

  @override
  int get hashCode => Object.hash(dx, dy);

  @override
  String toString() => 'ScreenOffset($dx, $dy)';
}

/// Recency classification for a blip.
enum BlipActivity {
  /// Heard from inside the recency window — render bright/pulsing.
  active,

  /// Older than the recency window but not yet dropped — render faded.
  stale,
}

/// The motion of a moving node, drawn as a heading arrow + trail.
@immutable
class MotionVector {
  const MotionVector({
    required this.courseDegrees,
    required this.speedMps,
    required this.trail,
  });

  /// Course over ground, degrees true `[0, 360)`.
  final double courseDegrees;

  /// Ground speed in m/s.
  final double speedMps;

  /// Recent projected positions, newest first, for drawing a trail.
  final List<ScreenOffset> trail;
}

/// A single node projected onto the sonar canvas.
@immutable
class SonarBlip {
  const SonarBlip({
    required this.nodeId,
    required this.label,
    required this.bearingDegrees,
    required this.rangeMeters,
    required this.position,
    required this.activity,
    required this.ageSeconds,
    required this.clamped,
    this.motion,
  });

  final String nodeId;
  final String label;

  /// Bearing from self, degrees true `[0, 360)`.
  final double bearingDegrees;

  /// Range from self in meters.
  final double rangeMeters;

  /// Projected canvas position.
  final ScreenOffset position;

  final BlipActivity activity;

  /// Seconds since the node's most recent fix.
  final double ageSeconds;

  /// Whether the node was beyond the scale and clamped to the outer ring.
  final bool clamped;

  /// Motion vector when the node has ≥ 2 recent samples; otherwise `null`.
  final MotionVector? motion;

  bool get isMoving => motion != null;
}
