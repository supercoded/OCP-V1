import 'package:mock_position_feed/mock_position_feed.dart';
import 'package:test/test.dart';

void main() {
  group('MockPositionFeed', () {
    final epoch = DateTime.utc(2026);

    test('stationary node does not move', () {
      final feed = MockPositionFeed(
        [StationaryNode(id: 'a', latitude: 10, longitude: 20)],
        epoch: epoch,
      );
      final first = feed.sampleAt(epoch).single;
      final later =
          feed.sampleAt(epoch.add(const Duration(minutes: 5))).single;
      expect(later.latitude, first.latitude);
      expect(later.longitude, first.longitude);
      expect(first.speedMps, 0);
    });

    test('linear node advances along its bearing', () {
      final feed = MockPositionFeed(
        [
          LinearNode(
            id: 'mover',
            startLatitude: 0,
            startLongitude: 0,
            bearingDegrees: 90,
            speedMps: 10,
          ),
        ],
        epoch: epoch,
      );
      final start = feed.sampleAt(epoch).single;
      final after = feed.sampleAt(epoch.add(const Duration(seconds: 100))).single;
      expect(start.longitude, closeTo(0, 1e-9));
      // Moving east: longitude increases, latitude ~unchanged.
      expect(after.longitude, greaterThan(0));
      expect(after.latitude, closeTo(0, 1e-6));
      expect(after.speedMps, 10);
    });

    test('history returns evenly spaced samples per node', () {
      final feed = MockPositionFeed.demo(epoch: epoch);
      final history = feed.history(
        from: epoch,
        to: epoch.add(const Duration(seconds: 20)),
        interval: const Duration(seconds: 5),
      );
      expect(history.keys, containsAll(['base-camp', 'hiker', 'drone']));
      expect(history['hiker'], hasLength(5));
      final ts = history['hiker']!.map((s) => s.timestamp).toList();
      expect(ts.first, epoch);
      expect(ts.last, epoch.add(const Duration(seconds: 20)));
    });

    test('snapshots stream emits a bounded number of ticks', () async {
      final feed = MockPositionFeed.demo(epoch: epoch);
      var now = epoch;
      final snapshots = await feed
          .snapshots(
            interval: const Duration(milliseconds: 1),
            count: 3,
            clock: () {
              now = now.add(const Duration(seconds: 1));
              return now;
            },
          )
          .toList();
      expect(snapshots, hasLength(3));
      expect(snapshots.first, hasLength(3));
    });
  });
}
