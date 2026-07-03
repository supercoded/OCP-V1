import 'package:flutter_test/flutter_test.dart';
import 'package:ocp_app/app/ocp_app_coordinator.dart';
import 'package:ocp_storage/ocp_storage.dart';
import 'package:ocp_storage/src/testing/isar_test_init.dart';
import 'package:ocp_transport/ocp_transport.dart';

void main() {
  setUpAll(() async {
    await initializeIsarForTests();
  });

  test('pairing handoff opens session and ingests wire positions', () async {
    final db = await OcpDatabase.openMemory();
    final coordinator = await OcpAppCoordinator.createInMemory(db);

    const discovered = BleDiscoveredDevice(
      id: 'AA:BB:CC:00:11:22',
      name: 'Meshtastic_RAK4631',
      serviceUuids: [MeshtasticBle.serviceUuid],
    );

    final result = await coordinator.pairDiscovered(discovered);
    expect(result.success, isTrue);
    expect(coordinator.hasActiveSession, isTrue);
    expect(coordinator.positionPublisher?.isRunning, isTrue);

    await Future<void>.delayed(const Duration(milliseconds: 1200));

    final nodes = await coordinator.core.locationService.latestPerNode();
    expect(nodes, isNotEmpty);

    await coordinator.dispose();
  });
}
