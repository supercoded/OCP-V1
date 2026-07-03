import 'dart:async';

import 'package:logging/logging.dart';
import 'package:ocp_core/src/logging/ocp_logger.dart';
import 'package:ocp_core/src/models/node_position.dart';
import 'package:ocp_core/src/repositories/node_position_repository.dart';

/// Location Manager (minimal, per build-plan v2 Phase 1).
///
/// Ingests position updates, writes them to the position history, and exposes a
/// broadcast stream that the Maps workspace subscribes to. Deliberately thin:
/// retention/pruning policy and multi-pack management are Phase 2 concerns.
class LocationService {
  LocationService(this._positions, {Logger? logger})
      : _logger = logger ?? ocpLogger('location');

  final NodePositionRepository _positions;
  final Logger _logger;
  final StreamController<NodePosition> _updates =
      StreamController<NodePosition>.broadcast();

  /// Emits every ingested position fix.
  Stream<NodePosition> get positionUpdates => _updates.stream;

  /// Records a new fix and notifies listeners.
  Future<void> ingest(NodePosition position) async {
    await _positions.add(position);
    if (!_updates.isClosed) {
      _updates.add(position);
    }
    _logger.fine(
      'Ingested position for ${position.nodeId} '
      '(${position.latitude}, ${position.longitude})',
    );
  }

  /// Most recent [limit] fixes for [nodeId], newest first.
  Future<List<NodePosition>> history(String nodeId, {int limit = 50}) =>
      _positions.history(nodeId, limit: limit);

  /// The single most recent fix for [nodeId].
  Future<NodePosition?> latest(String nodeId) => _positions.latest(nodeId);

  /// The most recent fix for every known node.
  Future<List<NodePosition>> latestPerNode() => _positions.latestPerNode();

  /// Retention hook (Phase 2): prunes fixes older than [cutoff].
  Future<int> prune(DateTime cutoff) => _positions.pruneBefore(cutoff);

  Future<void> dispose() => _updates.close();
}
