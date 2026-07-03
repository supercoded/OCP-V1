import 'package:ocp_core/src/models/device.dart';

/// Device storage contract.
abstract class DeviceRepository {
  Future<Device?> findById(String deviceId);
  Future<List<Device>> findByWorkspace(String workspaceId);
  Future<void> save(Device device);
  Future<void> delete(String deviceId);
}
