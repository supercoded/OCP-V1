import 'package:flutter_test/flutter_test.dart';
import 'package:mock_device/mock_device.dart';
import 'package:ocp_app/pairing/device_pairing_controller.dart';
import 'package:ocp_core/ocp_core.dart';
import 'package:ocp_odp/ocp_odp.dart';
import 'package:ocp_transport/ocp_transport.dart';

/// In-memory [DeviceRepository] for testing the pairing flow without Isar.
class _FakeDeviceRepository implements DeviceRepository {
  final Map<String, Device> _store = {};

  @override
  Future<void> delete(String deviceId) async => _store.remove(deviceId);

  @override
  Future<Device?> findById(String deviceId) async => _store[deviceId];

  @override
  Future<List<Device>> findByWorkspace(String workspaceId) async => _store
      .values
      .where((d) => d.workspaceId == workspaceId)
      .toList();

  @override
  Future<void> save(Device device) async => _store[device.deviceId] = device;
}

void main() {
  test('scan returns only auto-detected Meshtastic devices', () async {
    final controller = DevicePairingController(
      scanner: MockBleScanner(),
      devices: _FakeDeviceRepository(),
      workspaceId: 'default',
      scanTimeout: const Duration(milliseconds: 50),
    );
    final found = await controller.scanForMeshtastic();
    expect(found, hasLength(2));
    expect(found.every(MeshtasticBle.isMeshtastic), isTrue);
  });

  test('pairing runs the ODP handshake and persists a paired device', () async {
    final repo = _FakeDeviceRepository();
    final controller = DevicePairingController(
      scanner: MockBleScanner(),
      devices: repo,
      workspaceId: 'default',
    );
    final mock = MockOdpDevice();
    final result = await controller.pair(
      const BleDiscoveredDevice(
        id: 'AA:BB:CC:00:11:22',
        name: 'Meshtastic_RAK4631',
        serviceUuids: [MeshtasticBle.serviceUuid],
      ),
      exchange: (outgoing) async => mock.handle(outgoing) ?? const <int>[],
    );

    expect(result.success, isTrue);
    expect(result.device!.isPaired, isTrue);
    expect(result.device!.transportType, 'ble');
    expect(await repo.findById('AA:BB:CC:00:11:22'), isNotNull);
  });

  test('pairing fails cleanly when the handshake never completes', () async {
    final controller = DevicePairingController(
      scanner: MockBleScanner(),
      devices: _FakeDeviceRepository(),
      workspaceId: 'default',
      connectionFactory: () =>
          OdpConnection(handshakeTimeout: const Duration(milliseconds: 50)),
    );
    final result = await controller.pair(
      const BleDiscoveredDevice(
        id: 'X',
        name: 'Meshtastic_X',
        serviceUuids: [MeshtasticBle.serviceUuid],
      ),
      // Never returns a valid frame → handshake times out.
      exchange: (outgoing) => Future.delayed(
        const Duration(seconds: 1),
        () => const <int>[],
      ),
    );
    expect(result.success, isFalse);
    expect(result.reason, isNotNull);
  });
}
