/// Workspace domain model.
class Workspace {
  const Workspace({
    required this.workspaceId,
    required this.name,
    required this.assignedDeviceIds,
    required this.settingsJson,
    required this.createdAt,
    required this.updatedAt,
  });

  final String workspaceId;
  final String name;
  final List<String> assignedDeviceIds;
  final String settingsJson;
  final DateTime createdAt;
  final DateTime updatedAt;
}
