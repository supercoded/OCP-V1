import 'package:logging/logging.dart';
import 'package:ocp_core/src/errors/ocp_exception.dart';
import 'package:ocp_core/src/logging/ocp_logger.dart';
import 'package:ocp_core/src/models/workspace.dart';
import 'package:ocp_core/src/repositories/device_repository.dart';
import 'package:ocp_core/src/repositories/workspace_repository.dart';

/// Manages workspace isolation, device assignment, and shared settings.
class WorkspaceService {
  WorkspaceService(
    this._workspaces,
    this._devices, {
    Logger? logger,
  }) : _logger = logger ?? ocpLogger('workspace');

  final WorkspaceRepository _workspaces;
  final DeviceRepository _devices;
  final Logger _logger;

  Future<Workspace> create({
    required String workspaceId,
    required String name,
  }) async {
    final now = DateTime.now().toUtc();
    final workspace = Workspace(
      workspaceId: workspaceId,
      name: name,
      assignedDeviceIds: const [],
      settingsJson: '{}',
      createdAt: now,
      updatedAt: now,
    );
    await _workspaces.save(workspace);
    _logger.info('Created workspace $workspaceId');
    return workspace;
  }

  Future<List<Workspace>> list() => _workspaces.findAll();

  Future<void> assignDevice({
    required String workspaceId,
    required String deviceId,
  }) async {
    final workspace = await _workspaces.findById(workspaceId);
    if (workspace == null) {
      throw OcpException('Workspace not found', code: 'workspace_not_found');
    }
    final device = await _devices.findById(deviceId);
    if (device == null) {
      throw OcpException('Device not found', code: 'device_not_found');
    }
    final ids = {...workspace.assignedDeviceIds, deviceId}.toList();
    await _workspaces.save(
      Workspace(
        workspaceId: workspace.workspaceId,
        name: workspace.name,
        assignedDeviceIds: ids,
        settingsJson: workspace.settingsJson,
        createdAt: workspace.createdAt,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }
}
