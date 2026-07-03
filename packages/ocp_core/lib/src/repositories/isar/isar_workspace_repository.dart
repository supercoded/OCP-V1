import 'package:ocp_core/src/models/workspace.dart';
import 'package:ocp_core/src/repositories/workspace_repository.dart';
import 'package:ocp_storage/ocp_storage.dart';

/// Isar-backed [WorkspaceRepository].
class IsarWorkspaceRepository implements WorkspaceRepository {
  IsarWorkspaceRepository(OcpDatabase database) : _stores = OcpStores(database);

  final OcpStores _stores;

  @override
  Future<void> delete(String workspaceId) async {
    final existing = await _stores.workspaceById(workspaceId);
    if (existing != null) {
      await _stores.deleteWorkspace(existing.id);
    }
  }

  @override
  Future<Workspace?> findById(String workspaceId) async {
    final schema = await _stores.workspaceById(workspaceId);
    return schema == null ? null : _toModel(schema);
  }

  @override
  Future<List<Workspace>> findAll() async {
    final schemas = await _stores.allWorkspaces();
    return schemas.map(_toModel).toList();
  }

  @override
  Future<void> save(Workspace workspace) async {
    final existing = await _stores.workspaceById(workspace.workspaceId);
    final schema = _toSchema(workspace);
    if (existing != null) {
      schema.id = existing.id;
    }
    await _stores.putWorkspace(schema);
  }

  Workspace _toModel(WorkspaceSchema schema) => Workspace(
        workspaceId: schema.workspaceId,
        name: schema.name,
        assignedDeviceIds: List<String>.from(schema.assignedDeviceIds),
        settingsJson: schema.settingsJson,
        createdAt: schema.createdAt,
        updatedAt: schema.updatedAt,
      );

  WorkspaceSchema _toSchema(Workspace workspace) => WorkspaceSchema()
    ..workspaceId = workspace.workspaceId
    ..name = workspace.name
    ..assignedDeviceIds = List<String>.from(workspace.assignedDeviceIds)
    ..settingsJson = workspace.settingsJson
    ..createdAt = workspace.createdAt
    ..updatedAt = workspace.updatedAt;
}
