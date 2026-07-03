import 'package:ocp_core/src/models/node_position.dart';
import 'package:ocp_core/src/repositories/node_position_repository.dart';
import 'package:ocp_storage/ocp_storage.dart' as db;

/// Isar-backed [NodePositionRepository].
class IsarNodePositionRepository implements NodePositionRepository {
  IsarNodePositionRepository(db.OcpDatabase database)
      : _stores = db.OcpStores(database);

  final db.OcpStores _stores;

  @override
  Future<void> add(NodePosition position) => _stores.putNodePosition(
        _toSchema(position),
      );

  @override
  Future<List<NodePosition>> history(String nodeId, {int limit = 50}) async {
    final schemas = await _stores.positionsForNode(nodeId, limit: limit);
    return schemas.map(_toModel).toList();
  }

  @override
  Future<NodePosition?> latest(String nodeId) async {
    final schema = await _stores.latestPositionForNode(nodeId);
    return schema == null ? null : _toModel(schema);
  }

  @override
  Future<List<NodePosition>> latestPerNode() async {
    final schemas = await _stores.allLatestPositions();
    return schemas.map(_toModel).toList();
  }

  @override
  Future<int> pruneBefore(DateTime cutoff) =>
      _stores.prunePositionsBefore(cutoff);

  NodePosition _toModel(db.NodePositionSchema schema) => NodePosition(
        nodeId: schema.nodeId,
        latitude: schema.lat,
        longitude: schema.lon,
        altitude: schema.altitude,
        heading: schema.heading,
        speedMps: schema.speedMps,
        timestamp: schema.timestamp,
        source: schema.source == db.PositionSource.relayed
            ? PositionSource.relayed
            : PositionSource.direct,
      );

  db.NodePositionSchema _toSchema(NodePosition position) =>
      db.NodePositionSchema()
        ..nodeId = position.nodeId
        ..lat = position.latitude
        ..lon = position.longitude
        ..altitude = position.altitude
        ..heading = position.heading
        ..speedMps = position.speedMps
        ..timestamp = position.timestamp.toUtc()
        ..source = position.source == PositionSource.relayed
            ? db.PositionSource.relayed
            : db.PositionSource.direct;
}
