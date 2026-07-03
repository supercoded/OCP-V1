import 'package:meta/meta.dart';
import 'package:ocp_maps/src/sonar/sonar_blip.dart';

/// A node that has aged past the drop threshold and left the sonar view.
@immutable
class DroppedNode {
  const DroppedNode({
    required this.nodeId,
    required this.label,
    required this.ageSeconds,
  });

  final String nodeId;
  final String label;
  final double ageSeconds;
}

/// The fully-projected sonar scene, ready for a painter to render.
@immutable
class SonarViewModel {
  const SonarViewModel({
    required this.center,
    required this.radiusPixels,
    required this.maxRangeMeters,
    required this.ringRadiiPixels,
    required this.ringRangeMeters,
    required this.blips,
    required this.droppedNodes,
    required this.rotationOffsetDegrees,
  });

  /// Canvas center (self position).
  final ScreenOffset center;

  /// Radius of the outermost ring in pixels.
  final double radiusPixels;

  /// Range represented by the outermost ring, in meters.
  final double maxRangeMeters;

  /// Ring radii in pixels, innermost first.
  final List<double> ringRadiiPixels;

  /// Range represented by each ring in meters, innermost first.
  final List<double> ringRangeMeters;

  /// Projected active/stale nodes.
  final List<SonarBlip> blips;

  /// Nodes past the drop age, surfaced as a "last seen" list instead.
  final List<DroppedNode> droppedNodes;

  /// View rotation applied (0 = north-up).
  final double rotationOffsetDegrees;
}
