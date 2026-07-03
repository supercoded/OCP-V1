import 'package:ocp_maps/ocp_maps.dart';
import 'package:test/test.dart';

void main() {
  const projector = SonarProjector();
  const self = GeoPoint(latitude: 0, longitude: 0);
  const center = ScreenOffset(200, 200);
  const radius = 200.0;
  final now = DateTime.utc(2026, 1, 1, 12);

  SonarSample sample(
    String id,
    double lat,
    double lon,
    DateTime ts, {
    double? heading,
    double? speed,
  }) =>
      SonarSample(
        nodeId: id,
        position: GeoPoint(latitude: lat, longitude: lon),
        timestamp: ts,
        headingDegrees: heading,
        speedMps: speed,
      );

  test('projects a node due north above the center', () {
    final vm = projector.project(
      self: self,
      samplesByNode: {
        'n': [sample('n', 0.01, 0, now)],
      },
      center: center,
      radiusPixels: radius,
      now: now,
    );

    expect(vm.blips, hasLength(1));
    final blip = vm.blips.single;
    expect(blip.bearingDegrees, closeTo(0, 1e-6));
    expect(blip.position.dx, closeTo(center.dx, 1e-6));
    expect(blip.position.dy, lessThan(center.dy));
    expect(blip.activity, BlipActivity.active);
    expect(blip.clamped, isFalse);
  });

  test('projects a node due east to the right of center', () {
    final vm = projector.project(
      self: self,
      samplesByNode: {
        'e': [sample('e', 0, 0.01, now)],
      },
      center: center,
      radiusPixels: radius,
      now: now,
    );
    final blip = vm.blips.single;
    expect(blip.bearingDegrees, closeTo(90, 1e-6));
    expect(blip.position.dx, greaterThan(center.dx));
    expect(blip.position.dy, closeTo(center.dy, 1e-3));
  });

  test('lays out evenly spaced auto-scaled range rings', () {
    final vm = projector.project(
      self: self,
      samplesByNode: {
        'n': [sample('n', 0.01, 0, now)], // ~1113 m
      },
      center: center,
      radiusPixels: radius,
      now: now,
    );
    expect(vm.ringRadiiPixels, [50, 100, 150, 200]);
    expect(vm.maxRangeMeters, 2000); // niceCeiling(1113)
  });

  test('classifies stale nodes and drops very old ones', () {
    final vm = projector.project(
      self: self,
      samplesByNode: {
        'stale': [sample('stale', 0.01, 0, now.subtract(const Duration(minutes: 5)))],
        'gone': [sample('gone', 0.01, 0, now.subtract(const Duration(minutes: 20)))],
      },
      center: center,
      radiusPixels: radius,
      now: now,
    );
    expect(vm.blips.map((b) => b.nodeId), ['stale']);
    expect(vm.blips.single.activity, BlipActivity.stale);
    expect(vm.droppedNodes.map((d) => d.nodeId), ['gone']);
  });

  test('clamps out-of-range nodes to the outer ring with a manual scale', () {
    final vm = projector.project(
      self: self,
      samplesByNode: {
        'far': [sample('far', 0.01, 0, now)], // ~1113 m
      },
      center: center,
      radiusPixels: radius,
      now: now,
      manualMaxRangeMeters: 500,
    );
    final blip = vm.blips.single;
    expect(blip.clamped, isTrue);
    expect(blip.position.dy, closeTo(center.dy - radius, 1e-6));
    expect(vm.maxRangeMeters, 500);
  });

  test('builds a motion vector from multiple samples of a moving node', () {
    final vm = projector.project(
      self: self,
      samplesByNode: {
        'mover': [
          sample('mover', 0, 0.02, now),
          sample('mover', 0, 0.01, now.subtract(const Duration(seconds: 60))),
        ],
      },
      center: center,
      radiusPixels: radius,
      now: now,
    );
    final blip = vm.blips.single;
    expect(blip.isMoving, isTrue);
    expect(blip.motion!.courseDegrees, closeTo(90, 1e-2));
    expect(blip.motion!.speedMps, greaterThan(0));
    expect(blip.motion!.trail, hasLength(2));
  });

  test('a single sample yields no motion vector', () {
    final vm = projector.project(
      self: self,
      samplesByNode: {
        'still': [sample('still', 0.01, 0, now)],
      },
      center: center,
      radiusPixels: radius,
      now: now,
    );
    expect(vm.blips.single.isMoving, isFalse);
  });

  test('empty input falls back to the default scale with no blips', () {
    final vm = projector.project(
      self: self,
      samplesByNode: const {},
      center: center,
      radiusPixels: radius,
      now: now,
    );
    expect(vm.blips, isEmpty);
    expect(vm.maxRangeMeters, 1000);
  });
}
