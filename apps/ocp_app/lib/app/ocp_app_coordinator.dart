import 'dart:io';

import 'package:mock_device/mock_device.dart';
import 'package:mock_position_feed/mock_position_feed.dart';
import 'package:ocp_app/session/odp_device_session.dart';
import 'package:ocp_app/session/wire_position_publisher.dart';
import 'package:ocp_core/ocp_core.dart';
import 'package:ocp_maps/ocp_maps.dart';
import 'package:ocp_plugin_api/ocp_plugin_api.dart';
import 'package:ocp_plugin_example/ocp_plugin_example.dart';
import 'package:ocp_storage/ocp_storage.dart';
import 'package:ocp_transport/ocp_transport.dart';
import 'package:path_provider/path_provider.dart';

/// Thin app-layer coordinator — wires UI to [OcpCore] services only.
class OcpAppCoordinator {
  OcpAppCoordinator._({
    required this.core,
    required this.plugins,
    required this.positionFeed,
    required this.selfPosition,
    required this.baseDirectory,
    required this.appTransport,
    required this.deviceTransport,
    required this.mockDevice,
    required this.mockDeviceLoop,
  });

  final OcpCore core;
  final PluginRegistry plugins;

  /// Live ODP session after pairing (null until a device is paired + connected).
  OdpDeviceSession? deviceSession;

  /// Emits mock POSITION frames when a session is active.
  WirePositionPublisher? positionPublisher;

  /// Mock transport pair — shared by pairing handshake and the live session.
  final MockTransport appTransport;
  final MockTransport deviceTransport;
  final MockOdpDevice mockDevice;
  final MockOdpDeviceLoop mockDeviceLoop;

  /// Synthetic node paths used by [WirePositionPublisher].
  final MockPositionFeed positionFeed;

  /// Self position for the self-centered sonar view (base-camp for the demo).
  final GeoPoint selfPosition;

  /// App storage root (used for the offline tile pack, among others).
  final Directory baseDirectory;

  static const defaultWorkspaceId = 'default';
  static const defaultConversationId = 'default';

  bool get hasActiveSession =>
      deviceSession != null &&
      core.sessionService.state == SessionState.connected;

  /// ODP pairing handshake exchange (mock-first: in-process [MockOdpDevice]).
  Future<List<int>> pairingExchange(List<int> outgoing) async {
    return mockDevice.handle(outgoing) ?? const <int>[];
  }

  /// Opens (or replaces) the ODP session for a paired [device].
  Future<bool> connectPairedDevice(Device device) async {
    await _closeSession(stopPublisher: true);

    final session = OdpDeviceSession(
      transport: appTransport,
      messaging: core.messagingService,
      location: core.locationService,
      session: core.sessionService,
      workspaceId: defaultWorkspaceId,
      conversationId: defaultConversationId,
      localSenderId: 'local',
      remoteSenderId: device.deviceId,
    );

    final ok = await session.open(deviceId: device.deviceId);
    if (!ok) {
      session.dispose();
      return false;
    }

    deviceSession = session;
    positionPublisher ??= WirePositionPublisher(
      feed: positionFeed,
      deviceLoop: mockDeviceLoop,
    );
    positionPublisher!.start();
    return true;
  }

  Future<void> _closeSession({required bool stopPublisher}) async {
    if (stopPublisher) {
      positionPublisher?.stop();
    }
    await deviceSession?.close();
    deviceSession?.dispose();
    deviceSession = null;
  }

  static Future<OcpAppCoordinator> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final database = await OcpDatabase.open(dir.path);
    final core = await OcpCore.create(database);
    final plugins = PluginRegistry();
    await plugins.install(ExamplePlugin());

    final feed = MockPositionFeed.demo();
    final appTransport = MockTransport(name: 'app');
    final deviceTransport = MockTransport(name: 'device');
    appTransport.peer = deviceTransport;
    deviceTransport.peer = appTransport;

    final mockDevice = MockOdpDevice();
    final mockLoop = MockOdpDeviceLoop(
      device: mockDevice,
      transport: deviceTransport,
    );
    mockLoop.start();

    return OcpAppCoordinator._(
      core: core,
      plugins: plugins,
      positionFeed: feed,
      selfPosition: const GeoPoint(latitude: 37.7749, longitude: -122.4194),
      baseDirectory: dir,
      appTransport: appTransport,
      deviceTransport: deviceTransport,
      mockDevice: mockDevice,
      mockDeviceLoop: mockLoop,
    );
  }

  /// In-memory coordinator for widget/unit tests (no path_provider).
  static Future<OcpAppCoordinator> createInMemory(OcpDatabase database) async {
    final core = await OcpCore.create(database);
    final plugins = PluginRegistry();
    await plugins.install(ExamplePlugin());

    final feed = MockPositionFeed.demo();
    final appTransport = MockTransport(name: 'app');
    final deviceTransport = MockTransport(name: 'device');
    appTransport.peer = deviceTransport;
    deviceTransport.peer = appTransport;

    final mockDevice = MockOdpDevice();
    final mockLoop = MockOdpDeviceLoop(
      device: mockDevice,
      transport: deviceTransport,
    );
    mockLoop.start();

    return OcpAppCoordinator._(
      core: core,
      plugins: plugins,
      positionFeed: feed,
      selfPosition: const GeoPoint(latitude: 37.7749, longitude: -122.4194),
      baseDirectory: Directory.systemTemp,
      appTransport: appTransport,
      deviceTransport: deviceTransport,
      mockDevice: mockDevice,
      mockDeviceLoop: mockLoop,
    );
  }

  Future<void> dispose() async {
    await _closeSession(stopPublisher: true);
    await mockDeviceLoop.stop();
    appTransport.dispose();
    deviceTransport.dispose();
    await core.dispose();
  }
}
