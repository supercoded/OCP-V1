import 'dart:async';

import 'package:logging/logging.dart';
import 'package:ocp_core/src/logging/ocp_logger.dart';
import 'package:ocp_core/src/models/node_position.dart';
import 'package:ocp_core/src/repositories/node_position_repository.dart';

/// Retention policy for the `NodePosition` history (build-plan-v2 Phase 2).
///
/// Unbounded per-node history is not sustainable, so ingest trims to at most
/// [maxSamplesPerNode] fixes per node and, when [maxAge] is set, drops fixes
/// older than that window.
class PositionRetentionPolicy {
  const PositionRetentionPolicy({
    this.maxSamplesPerNode = 500,
    this.maxAge,
  });

  /// Keeps history unbounded (useful in tests / short-lived tooling).
  static const PositionRetentionPolicy unbounded =
      PositionRetentionPolicy(maxSamplesPerNode: null);

  final int? maxSamplesPerNode;
  final Duration? maxAge;
}

/// Location Manager (build-plan-v2 Phase 1, retention added in Phase 2).
///
/// Ingests position updates, writes them to the position history, applies the
/// retention policy, and exposes a broadcast stream the Maps workspace
/// subscribes to.
class LocationService {
  LocationService(
    this._positions, {
    Logger? logger,
    this.retentionPolicy = const PositionRetentionPolicy(),
    DateTime Function()? clock,
  })  : _logger = logger ?? ocpLogger('location'),
        _clock = clock ?? (() => DateTime.now().toUtc());

  final NodePositionRepository _positions;
  final Logger _logger;
  final PositionRetentionPolicy retentionPolicy;
  final DateTime Function() _clock;
  final StreamController<NodePosition> _updates =
      StreamController<NodePosition>.broadcast();

  /// Emits every ingested position fix.
  Stream<NodePosition> get positionUpdates => _updates.stream;

  /// Records a new fix, applies retention, and notifies listeners.
  Future<void> ingest(NodePosition position) async {
    await _positions.add(position);
    await _applyRetention(position.nodeId);
    if (!_updates.isClosed) {
      _updates.add(position);
    }
    _logger.fine(
      'Ingested position for ${position.nodeId} '
      '(${position.latitude}, ${position.longitude})',
    );
  }

  Future<void> _applyRetention(String nodeId) async {
    final maxAge = retentionPolicy.maxAge;
    if (maxAge != null) {
      await _positions.pruneBefore(_clock().subtract(maxAge));
    }
    final maxSamples = retentionPolicy.maxSamplesPerNode;
    if (maxSamples != null) {
      await _positions.trimToLatest(nodeId, maxSamples);
    }
  }

  /// Most recent [limit] fixes for [nodeId], newest first.
  Future<List<NodePosition>> history(String nodeId, {int limit = 50}) =>
      _positions.history(nodeId, limit: limit);

  /// The single most recent fix for [nodeId].
  Future<NodePosition?> latest(String nodeId) => _positions.latest(nodeId);

  /// The most recent fix for every known node.
  Future<List<NodePosition>> latestPerNode() => _positions.latestPerNode();

  /// Explicit retention hook: prunes fixes older than [cutoff].
  Future<int> prune(DateTime cutoff) => _positions.pruneBefore(cutoff);

  Future<void> dispose() => _updates.close();
}
