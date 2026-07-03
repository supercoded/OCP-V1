import 'package:isar/isar.dart';

part 'node_position_schema.g.dart';

/// Where a position fix originated.
enum PositionSource { direct, relayed }

/// A single position fix for a node.
///
/// This is a *history* table: every fix is appended, there is no single
/// latest-position field. A motion vector for a moving node needs at least two
/// samples, so a single-latest design cannot draw one.
@collection
class NodePositionSchema {
  Id id = Isar.autoIncrement;

  @Index(composite: [CompositeIndex('timestamp')])
  late String nodeId;

  late double lat;
  late double lon;
  double? altitude;
  double? heading;
  double? speedMps;

  @Index()
  late DateTime timestamp;

  @enumerated
  PositionSource source = PositionSource.direct;
}
