import 'package:ocp_core/src/models/node_position.dart';

/// Position-history storage contract.
abstract class NodePositionRepository {
  /// Appends a new fix.
  Future<void> add(NodePosition position);

  /// Most recent [limit] fixes for [nodeId], newest first.
  Future<List<NodePosition>> history(String nodeId, {int limit});

  /// The single most recent fix for [nodeId].
  Future<NodePosition?> latest(String nodeId);

  /// The most recent fix for every known node.
  Future<List<NodePosition>> latestPerNode();

  /// Retention hook: drops fixes older than [cutoff], returns the count removed.
  Future<int> pruneBefore(DateTime cutoff);

  /// Retention hook: keeps only the newest [maxSamples] fixes for [nodeId],
  /// returns the count removed.
  Future<int> trimToLatest(String nodeId, int maxSamples);
}
