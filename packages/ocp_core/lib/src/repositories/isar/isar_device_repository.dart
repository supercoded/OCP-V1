import 'package:ocp_core/src/models/device.dart';
import 'package:ocp_core/src/repositories/device_repository.dart';
import 'package:ocp_storage/ocp_storage.dart';

/// Isar-backed [DeviceRepository].
class IsarDeviceRepository implements DeviceRepository {
  IsarDeviceRepository(OcpDatabase database) : _stores = OcpStores(database);

  final OcpStores _stores;

  @override
  Future<void> delete(String deviceId) async {
    final existing = await _stores.deviceById(deviceId);
    if (existing != null) {
      await _stores.deleteDevice(existing.id);
    }
  }

  @override
  Future<Device?> findById(String deviceId) async {
    final schema = await _stores.deviceById(deviceId);
    return schema == null ? null : _toModel(schema);
  }

  @override
  Future<List<Device>> findByWorkspace(String workspaceId) async {
    final schemas = await _stores.devicesForWorkspace(workspaceId);
    return schemas.map(_toModel).toList();
  }

  @override
  Future<void> save(Device device) async {
    final existing = await _stores.deviceById(device.deviceId);
    final schema = _toSchema(device);
    if (existing != null) {
      schema.id = existing.id;
    }
    await _stores.putDevice(schema);
  }

  Device _toModel(DeviceSchema schema) => Device(
        deviceId: schema.deviceId,
        workspaceId: schema.workspaceId,
        name: schema.name,
        transportType: schema.transportType,
        capabilities: List<String>.from(schema.capabilities),
        firmwareVersion: schema.firmwareVersion,
        isPaired: schema.isPaired,
        lastSeenAt: schema.lastSeenAt,
        createdAt: schema.createdAt,
        updatedAt: schema.updatedAt,
      );

  DeviceSchema _toSchema(Device device) => DeviceSchema()
    ..deviceId = device.deviceId
    ..workspaceId = device.workspaceId
    ..name = device.name
    ..transportType = device.transportType
    ..capabilities = List<String>.from(device.capabilities)
    ..firmwareVersion = device.firmwareVersion
    ..isPaired = device.isPaired
    ..lastSeenAt = device.lastSeenAt
    ..createdAt = device.createdAt
    ..updatedAt = device.updatedAt;
}
