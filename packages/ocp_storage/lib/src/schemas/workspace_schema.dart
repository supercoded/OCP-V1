import 'package:isar/isar.dart';

part 'workspace_schema.g.dart';

/// Workspace data isolation boundary.
@collection
class WorkspaceSchema {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String workspaceId;

  late String name;
  List<String> assignedDeviceIds = [];
  String settingsJson = '{}';
  DateTime createdAt = DateTime.now().toUtc();
  DateTime updatedAt = DateTime.now().toUtc();
}
