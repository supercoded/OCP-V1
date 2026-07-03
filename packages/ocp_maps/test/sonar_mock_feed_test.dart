import 'package:mock_position_feed/mock_position_feed.dart';
import 'package:ocp_maps/ocp_maps.dart';
import 'package:test/test.dart';

/// Mock-first: exercise the projector against synthetic scripted paths from
/// `tools/mock_position_feed` before wiring it to live ONP data.
void main() {
  test('projects the demo feed into an active sonar scene', () {
    final feed = MockPositionFeed.demo();
    final from = feed.epoch;
    final to = feed.epoch.add(const Duration(seconds: 60));
    final history = feed.history(
      from: from,
      to: to,
      interval: const Duration(seconds: 10),
    );

    final samplesByNode = <String, List<SonarSample>>{
      for (final entry in history.entries)
        entry.key: [
          for (final p in entry.value)
            SonarSample(
              nodeId: p.nodeId,
              position: GeoPoint(
                latitude: p.latitude,
                longitude: p.longitude,
              ),
              timestamp: p.timestamp,
              headingDegrees: p.headingDegrees,
              speedMps: p.speedMps,
            ),
        ],
    };

    // Self sits at the base-camp location.
    const self = GeoPoint(latitude: 37.7749, longitude: -122.4194);
    const projector = SonarProjector();
    final vm = projector.project(
      self: self,
      samplesByNode: samplesByNode,
      center: const ScreenOffset(150, 150),
      radiusPixels: 150,
      now: to,
    );

    expect(vm.blips.map((b) => b.nodeId), containsAll(['base-camp', 'hiker', 'drone']));

    final baseCamp = vm.blips.firstWhere((b) => b.nodeId == 'base-camp');
    expect(baseCamp.rangeMeters, closeTo(0, 1e-6));

    final drone = vm.blips.firstWhere((b) => b.nodeId == 'drone');
    // Orbiting at a 500 m radius around self.
    expect(drone.rangeMeters, closeTo(500, 5));
    expect(drone.isMoving, isTrue);

    final hiker = vm.blips.firstWhere((b) => b.nodeId == 'hiker');
    expect(hiker.isMoving, isTrue);
    expect(hiker.rangeMeters, greaterThan(0));
  });
}
