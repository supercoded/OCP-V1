import 'dart:io';

import 'package:mock_device/mock_device.dart';
import 'package:mock_position_feed/mock_position_feed.dart';
import 'package:ocp_app/session/odp_device_session.dart';
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
    required this.deviceSession,
    required this.mockDeviceLoop,
  });

  final OcpCore core;
  final PluginRegistry plugins;

  /// Mock-first ODP session (transport ↔ ODP ↔ bridge ↔ messaging).
  final OdpDeviceSession deviceSession;

  /// Device-side responder loop paired with [deviceSession].
  final MockOdpDeviceLoop mockDeviceLoop;

  /// MVP-only synthetic node feed driving the Maps workspace before real GPS
  /// hardware is wired in (see build-plan-v2 Phase 1).
  final MockPositionFeed positionFeed;

  /// Self position for the self-centered sonar view (base-camp for the demo).
  final GeoPoint selfPosition;

  /// App storage root (used for the offline tile pack, among others).
  final Directory baseDirectory;

  static const mockDeviceId = 'mock-device';
  static const defaultWorkspaceId = 'default';
  static const defaultConversationId = 'default';

  static Future<OcpAppCoordinator> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final database = await OcpDatabase.open(dir.path);
    final core = await OcpCore.create(database);
    final plugins = PluginRegistry();
    await plugins.install(ExamplePlugin());

    // Mock-first transport pair: app ↔ simulated Meshtastic device.
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

    final session = OdpDeviceSession(
      transport: appTransport,
      messaging: core.messagingService,
      session: core.sessionService,
      workspaceId: defaultWorkspaceId,
      conversationId: defaultConversationId,
      localSenderId: 'local',
      remoteSenderId: mockDeviceId,
    );
    await session.open(deviceId: mockDeviceId);

    return OcpAppCoordinator._(
      core: core,
      plugins: plugins,
      positionFeed: MockPositionFeed.demo(),
      selfPosition: const GeoPoint(latitude: 37.7749, longitude: -122.4194),
      baseDirectory: dir,
      deviceSession: session,
      mockDeviceLoop: mockLoop,
    );
  }

  Future<void> dispose() async {
    await mockDeviceLoop.stop();
    await deviceSession.close();
    deviceSession.dispose();
    await core.dispose();
  }
}
