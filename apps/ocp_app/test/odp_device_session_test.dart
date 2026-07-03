import 'package:flutter_test/flutter_test.dart';
import 'package:mock_device/mock_device.dart';
import 'package:ocp_app/session/odp_device_session.dart';
import 'package:ocp_core/ocp_core.dart';
import 'package:ocp_odp/ocp_odp.dart';
import 'package:ocp_storage/ocp_storage.dart';
import 'package:ocp_storage/src/testing/isar_test_init.dart';
import 'package:ocp_transport/ocp_transport.dart';

void main() {
  setUpAll(() async {
    await initializeIsarForTests();
  });

  test('mock ODP session sends text and receives device echo', () async {
    final db = await OcpDatabase.openMemory();
    final core = await OcpCore.create(db);

    final app = MockTransport(name: 'app');
    final device = MockTransport(name: 'device');
    app.peer = device;
    device.peer = app;

    final loop = MockOdpDeviceLoop(
      device: MockOdpDevice(),
      transport: device,
    );
    loop.start();

    final session = OdpDeviceSession(
      transport: app,
      messaging: core.messagingService,
      session: core.sessionService,
      workspaceId: 'default',
      conversationId: 'default',
      localSenderId: 'local',
      remoteSenderId: 'mock-device',
    );

    expect(await session.open(deviceId: 'mock-device'), isTrue);
    expect(core.sessionService.state, SessionState.connected);

    await session.sendText('hello mesh');

    // Allow the echo to round-trip through the transport loop.
    await Future<void>.delayed(const Duration(milliseconds: 50));

    final history =
        await core.messagingService.conversationHistory('default');
    expect(history.length, greaterThanOrEqualTo(2));
    expect(history.any((m) => m.body == 'hello mesh'), isTrue);
    expect(history.any((m) => m.body == 'echo: hello mesh'), isTrue);

    await session.close();
    session.dispose();
    await loop.stop();
    app.dispose();
    device.dispose();
    await core.dispose();
  });

  test('session reconnect flushes pending messages after handshake', () async {
    final db = await OcpDatabase.openMemory();
    final core = await OcpCore.create(db);

    final app = MockTransport(name: 'app');
    final device = MockTransport(name: 'device');
    app.peer = device;
    device.peer = app;

    final mock = MockOdpDevice();
    final loop = MockOdpDeviceLoop(device: mock, transport: device);
    loop.start();

    final session = OdpDeviceSession(
      transport: app,
      messaging: core.messagingService,
      session: core.sessionService,
      workspaceId: 'default',
      conversationId: 'default',
      localSenderId: 'local',
      remoteSenderId: 'mock-device',
    );

    await session.open(deviceId: 'mock-device');
    session.connection.disconnect();
    expect(session.connection.state, isNot(OdpState.connected));

    await core.messagingService.sendMessage(
      messageId: 'queued-1',
      conversationId: 'default',
      workspaceId: 'default',
      senderId: 'local',
      body: 'queued while down',
    );

    expect(await session.reconnect(), isTrue);
    expect(await core.messagingService.pendingMessages(), isEmpty);

    await session.close();
    session.dispose();
    await loop.stop();
    app.dispose();
    device.dispose();
    await core.dispose();
  });
}
