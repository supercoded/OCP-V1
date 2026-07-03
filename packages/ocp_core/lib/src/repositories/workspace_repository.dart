import 'package:ocp_core/src/models/workspace.dart';

/// Workspace storage contract.
abstract class WorkspaceRepository {
  Future<Workspace?> findById(String workspaceId);
  Future<List<Workspace>> findAll();
  Future<void> save(Workspace workspace);
  Future<void> delete(String workspaceId);
}
