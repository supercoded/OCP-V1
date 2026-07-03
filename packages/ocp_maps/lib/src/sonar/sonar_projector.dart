import 'dart:math' as math;

import 'package:ocp_maps/src/geo/geo_math.dart';
import 'package:ocp_maps/src/geo/geo_point.dart';
import 'package:ocp_maps/src/sonar/sonar_blip.dart';
import 'package:ocp_maps/src/sonar/sonar_sample.dart';
import 'package:ocp_maps/src/sonar/sonar_view_model.dart';

/// Projects node position samples into a self-centered sonar/radar scene.
///
/// See `specs/maps-spec.md` §4. Pure logic: bearing/range/velocity math, an
/// auto-scaled range-ring layout, active/stale classification, and motion
/// vectors. No Flutter, no I/O.
class SonarProjector {
  const SonarProjector({
    this.recencyWindow = const Duration(minutes: 2),
    this.dropAge = const Duration(minutes: 15),
    this.ringCount = 4,
    this.rotationOffsetDegrees = 0,
    this.trailSamples = 3,
    this.defaultMaxRangeMeters = 1000,
  })  : assert(ringCount >= 1, 'need at least one ring'),
        assert(trailSamples >= 2, 'a trail needs at least two samples');

  /// Fixes newer than this render as [BlipActivity.active].
  final Duration recencyWindow;

  /// Fixes older than this leave the sonar view (surfaced as "last seen").
  final Duration dropAge;

  /// Number of concentric range rings.
  final int ringCount;

  /// View rotation. 0 = north-up (MVP); compass heading = heading-up (Phase 7).
  final double rotationOffsetDegrees;

  /// Number of trailing samples used to build a motion vector.
  final int trailSamples;

  /// Ring scale used when no nodes are in range yet.
  final double defaultMaxRangeMeters;

  /// Builds the sonar scene.
  ///
  /// [samplesByNode] maps a nodeId to its recent samples (any order). [now] is
  /// the reference time for age classification. Pass [manualMaxRangeMeters] to
  /// override the auto-scaled range rings (manual zoom).
  SonarViewModel project({
    required GeoPoint self,
    required Map<String, List<SonarSample>> samplesByNode,
    required ScreenOffset center,
    required double radiusPixels,
    required DateTime now,
    double? manualMaxRangeMeters,
  }) {
    final ranged = <_RangedNode>[];
    final dropped = <DroppedNode>[];

    for (final entry in samplesByNode.entries) {
      if (entry.value.isEmpty) continue;
      final samples = [...entry.value]
        ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
      final latest = samples.first;
      final ageSeconds =
          now.difference(latest.timestamp).inMicroseconds / 1e6;
      final label = latest.label ?? entry.key;

      if (ageSeconds > dropAge.inMicroseconds / 1e6) {
        dropped.add(
          DroppedNode(nodeId: entry.key, label: label, ageSeconds: ageSeconds),
        );
        continue;
      }

      ranged.add(
        _RangedNode(
          nodeId: entry.key,
          label: label,
          samples: samples,
          rangeMeters: GeoMath.distanceMeters(self, latest.position),
          bearingDegrees:
              GeoMath.initialBearingDegrees(self, latest.position),
          ageSeconds: ageSeconds,
        ),
      );
    }

    final farthest = ranged.fold<double>(
      0,
      (acc, node) => math.max(acc, node.rangeMeters),
    );
    final maxRange = manualMaxRangeMeters ??
        (farthest <= 0 ? defaultMaxRangeMeters : _niceCeiling(farthest));

    final ringRadii = <double>[];
    final ringRanges = <double>[];
    for (var i = 1; i <= ringCount; i++) {
      ringRadii.add(radiusPixels * i / ringCount);
      ringRanges.add(maxRange * i / ringCount);
    }

    final recencySeconds = recencyWindow.inMicroseconds / 1e6;
    final blips = <SonarBlip>[];
    for (final node in ranged) {
      final clamped = node.rangeMeters > maxRange;
      final fraction = maxRange <= 0
          ? 0.0
          : (node.rangeMeters / maxRange).clamp(0.0, 1.0);
      final position = _project(
        center: center,
        radiusPixels: radiusPixels,
        bearingDegrees: node.bearingDegrees,
        fraction: fraction.toDouble(),
      );

      blips.add(
        SonarBlip(
          nodeId: node.nodeId,
          label: node.label,
          bearingDegrees: node.bearingDegrees,
          rangeMeters: node.rangeMeters,
          position: position,
          activity: node.ageSeconds <= recencySeconds
              ? BlipActivity.active
              : BlipActivity.stale,
          ageSeconds: node.ageSeconds,
          clamped: clamped,
          motion: _motionFor(
            node: node,
            self: self,
            center: center,
            radiusPixels: radiusPixels,
            maxRange: maxRange,
          ),
        ),
      );
    }

    return SonarViewModel(
      center: center,
      radiusPixels: radiusPixels,
      maxRangeMeters: maxRange,
      ringRadiiPixels: ringRadii,
      ringRangeMeters: ringRanges,
      blips: blips,
      droppedNodes: dropped,
      rotationOffsetDegrees: rotationOffsetDegrees,
    );
  }

  MotionVector? _motionFor({
    required _RangedNode node,
    required GeoPoint self,
    required ScreenOffset center,
    required double radiusPixels,
    required double maxRange,
  }) {
    if (node.samples.length < 2) return null;
    final latest = node.samples[0];
    final previous = node.samples[1];

    double? course = latest.headingDegrees;
    double? speed = latest.speedMps;
    if (course == null || speed == null) {
      final velocity = GeoMath.velocityBetween(
        previous.position,
        previous.timestamp,
        latest.position,
        latest.timestamp,
      );
      if (velocity == null) return null;
      course ??= velocity.courseDegrees;
      speed ??= velocity.speedMps;
    }

    final trail = <ScreenOffset>[];
    final count = math.min(trailSamples, node.samples.length);
    for (var i = 0; i < count; i++) {
      final sample = node.samples[i];
      final range = GeoMath.distanceMeters(self, sample.position);
      final bearing = GeoMath.initialBearingDegrees(self, sample.position);
      final fraction =
          maxRange <= 0 ? 0.0 : (range / maxRange).clamp(0.0, 1.0).toDouble();
      trail.add(
        _project(
          center: center,
          radiusPixels: radiusPixels,
          bearingDegrees: bearing,
          fraction: fraction,
        ),
      );
    }

    return MotionVector(courseDegrees: course, speedMps: speed, trail: trail);
  }

  ScreenOffset _project({
    required ScreenOffset center,
    required double radiusPixels,
    required double bearingDegrees,
    required double fraction,
  }) {
    final theta =
        GeoMath.normalizeDegrees(bearingDegrees - rotationOffsetDegrees) *
            math.pi /
            180.0;
    final r = radiusPixels * fraction;
    return ScreenOffset(
      center.dx + r * math.sin(theta),
      center.dy - r * math.cos(theta),
    );
  }

  /// Rounds [value] up to a "nice" 1/2/5 × 10ⁿ scale for the outer ring.
  static double _niceCeiling(double value) {
    if (value <= 0) return 0;
    final exponent = (math.log(value) / math.ln10).floor();
    final magnitude = math.pow(10, exponent).toDouble();
    final normalized = value / magnitude;
    final double nice;
    if (normalized <= 1) {
      nice = 1;
    } else if (normalized <= 2) {
      nice = 2;
    } else if (normalized <= 5) {
      nice = 5;
    } else {
      nice = 10;
    }
    return nice * magnitude;
  }
}

class _RangedNode {
  _RangedNode({
    required this.nodeId,
    required this.label,
    required this.samples,
    required this.rangeMeters,
    required this.bearingDegrees,
    required this.ageSeconds,
  });

  final String nodeId;
  final String label;
  final List<SonarSample> samples;
  final double rangeMeters;
  final double bearingDegrees;
  final double ageSeconds;
}
