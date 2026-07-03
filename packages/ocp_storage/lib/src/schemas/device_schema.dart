import 'package:isar/isar.dart';

part 'device_schema.g.dart';

/// Paired or discovered device.
@collection
class DeviceSchema {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String deviceId;

  @Index()
  late String workspaceId;

  late String name;
  String? transportType;
  List<String> capabilities = [];
  String? firmwareVersion;
  bool isPaired = false;
  DateTime? lastSeenAt;
  DateTime createdAt = DateTime.now().toUtc();
  DateTime updatedAt = DateTime.now().toUtc();
}
