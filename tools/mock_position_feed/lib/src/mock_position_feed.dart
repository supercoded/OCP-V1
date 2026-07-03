import 'dart:async';

import 'package:mock_position_feed/src/mock_node_position.dart';
import 'package:mock_position_feed/src/paths.dart';

/// Fabricates deterministic moving-node position streams so the sonar view is
/// buildable and testable before any real GPS hardware exists.
class MockPositionFeed {
  MockPositionFeed(List<MockNode> nodes, {DateTime? epoch})
      : _nodes = List.unmodifiable(nodes),
        epoch = epoch ?? DateTime.utc(2026);

  /// A representative scene: one stationary node, one node moving in a straight
  /// line, and one orbiting node.
  factory MockPositionFeed.demo({DateTime? epoch}) {
    return MockPositionFeed(
      [
        StationaryNode(
          id: 'base-camp',
          latitude: 37.7749,
          longitude: -122.4194,
        ),
        LinearNode(
          id: 'hiker',
          startLatitude: 37.7749,
          startLongitude: -122.4194,
          bearingDegrees: 45,
          speedMps: 1.4,
        ),
        CircularNode(
          id: 'drone',
          centerLatitude: 37.7749,
          centerLongitude: -122.4194,
          radiusMeters: 500,
          angularSpeedDegPerSec: 6,
        ),
      ],
      epoch: epoch,
    );
  }

  final List<MockNode> _nodes;

  /// Reference time for `t = 0`.
  final DateTime epoch;

  List<MockNode> get nodes => _nodes;

  double _elapsed(DateTime time) =>
      time.difference(epoch).inMicroseconds / 1e6;

  /// One position per node at [time].
  List<MockNodePosition> sampleAt(DateTime time) {
    final elapsed = _elapsed(time);
    return [for (final node in _nodes) node.positionAt(elapsed, time)];
  }

  /// Per-node history between [from] and [to] at [interval] spacing
  /// (chronological order).
  Map<String, List<MockNodePosition>> history({
    required DateTime from,
    required DateTime to,
    Duration interval = const Duration(seconds: 5),
  }) {
    final result = <String, List<MockNodePosition>>{
      for (final node in _nodes) node.id: <MockNodePosition>[],
    };
    var time = from;
    while (!time.isAfter(to)) {
      final elapsed = _elapsed(time);
      for (final node in _nodes) {
        result[node.id]!.add(node.positionAt(elapsed, time));
      }
      time = time.add(interval);
    }
    return result;
  }

  /// Emits a full snapshot (all nodes) on each [interval] tick.
  ///
  /// [count] bounds the number of ticks; omit for an unbounded stream. [clock]
  /// defaults to wall-clock time.
  Stream<List<MockNodePosition>> snapshots({
    Duration interval = const Duration(seconds: 1),
    int? count,
    DateTime Function()? clock,
  }) {
    final now = clock ?? DateTime.now;
    final source = Stream<int>.periodic(interval, (tick) => tick);
    final bounded = count == null ? source : source.take(count);
    return bounded.map((_) => sampleAt(now()));
  }
}
