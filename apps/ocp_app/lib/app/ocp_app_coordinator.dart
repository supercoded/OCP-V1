import 'dart:io';

import 'package:mock_device/mock_device.dart';
import 'package:mock_position_feed/mock_position_feed.dart';
import 'package:ocp_app/pairing/device_pairing_controller.dart';
import 'package:ocp_app/session/odp_device_session.dart';
import 'package:ocp_app/session/wire_position_publisher.dart';
import 'package:ocp_core/ocp_core.dart';
import 'package:ocp_maps/ocp_maps.dart';
import 'package:ocp_plugin_api/ocp_plugin_api.dart';
import 'package:ocp_plugin_example/ocp_plugin_example.dart';
import 'package:ocp_storage/ocp_storage.dart';
import 'package:ocp_transport/ocp_transport.dart';
import 'package:ocp_transport_ble/ocp_transport_ble.dart';
import 'package:path_provider/path_provider.dart';

/// Thin app-layer coordinator — wires UI to [OcpCore] services only.
class OcpAppCoordinator {
  OcpAppCoordinator._({
    required this.core,
    required this.plugins,
    required this.positionFeed,
    required this.selfPosition,
    required this.baseDirectory,
    required this.useBleHardware,
    required this.bleScanner,
    required this.pairing,
    this.appTransport,
    this.deviceTransport,
    this.mockDevice,
    this.mockDeviceLoop,
  });

  final OcpCore core;
  final PluginRegistry plugins;

  /// When true, scan/pair/connect use [MeshtasticBleTransport] on device.
  final bool useBleHardware;

  /// BLE scanner — [FlutterBleScanner] on mobile, [MockBleScanner] elsewhere.
  final BleScanner bleScanner;

  /// Pairing flow shared by the Devices workspace.
  final DevicePairingController pairing;

  /// Live ODP session after pairing (null until a device is paired + connected).
  OdpDeviceSession? deviceSession;

  /// Emits mock POSITION frames when a mock session is active.
  WirePositionPublisher? positionPublisher;

  /// Mock transport pair — mock mode only.
  final MockTransport? appTransport;
  final MockTransport? deviceTransport;
  final MockOdpDevice? mockDevice;
  final MockOdpDeviceLoop? mockDeviceLoop;

  /// Synthetic node paths used by [WirePositionPublisher] (mock mode).
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

  Duration get bleScanTimeout => useBleHardware
      ? const Duration(seconds: 15)
      : const Duration(milliseconds: 400);

  /// ODP pairing handshake exchange (mock mode only).
  Future<List<int>> pairingExchange(List<int> outgoing) async {
    final device = mockDevice;
    if (device == null) {
      throw StateError('pairingExchange requires mock mode');
    }
    return device.handle(outgoing) ?? const <int>[];
  }

  /// Scans for Meshtastic boards using the configured [bleScanner].
  Future<List<BleDiscoveredDevice>> scanForMeshtastic() {
    return pairing.scanForMeshtastic();
  }

  /// Pair a discovered board, verify link on hardware, then open a session.
  Future<PairingResult> pairDiscovered(BleDiscoveredDevice discovered) async {
    if (useBleHardware) {
      final transport = MeshtasticBleTransport(deviceId: discovered.id);
      try {
        await transport.connect();
        await transport.disconnect();
      } on Object catch (error) {
        transport.dispose();
        return PairingResult(
          success: false,
          reason: 'BLE connect failed: $error',
        );
      }
      transport.dispose();

      final result = await pairing.pairVerified(discovered);
      if (!result.success || result.device == null) return result;

      final connected = await connectPairedDevice(result.device!);
      return PairingResult(
        success: connected,
        device: result.device,
        reason: connected ? null : 'Paired but session connect failed',
      );
    }

    final result = await pairing.pair(
      discovered,
      exchange: pairingExchange,
    );
    if (!result.success || result.device == null) return result;

    final connected = await connectPairedDevice(result.device!);
    return PairingResult(
      success: connected,
      device: result.device,
      reason: connected ? null : 'Paired but session connect failed',
    );
  }

  /// Opens (or replaces) the ODP session for a paired [device].
  Future<bool> connectPairedDevice(Device device) async {
    await _closeSession(stopPublisher: true);

    final OcpTransport transport;
    final skipOdpHandshake = useBleHardware;
    if (useBleHardware) {
      transport = MeshtasticBleTransport(deviceId: device.deviceId);
    } else {
      transport = appTransport!;
    }

    final session = OdpDeviceSession(
      transport: transport,
      messaging: core.messagingService,
      location: core.locationService,
      session: core.sessionService,
      workspaceId: defaultWorkspaceId,
      conversationId: defaultConversationId,
      localSenderId: 'local',
      remoteSenderId: device.deviceId,
    );

    final ok = await session.open(
      deviceId: device.deviceId,
      skipOdpHandshake: skipOdpHandshake,
    );
    if (!ok) {
      session.dispose();
      return false;
    }

    deviceSession = session;
    if (!useBleHardware) {
      positionPublisher ??= WirePositionPublisher(
        feed: positionFeed,
        deviceLoop: mockDeviceLoop!,
      );
      positionPublisher!.start();
    }
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

    final useBle = MeshtasticBleTransport.isSupported;
    if (useBle) {
      try {
        await MeshtasticBleTransport.ensureReady();
      } on Object {
        // Adapter off or permissions pending — UI can retry on scan.
      }
    }

    final feed = MockPositionFeed.demo();
    final scanner = useBle ? FlutterBleScanner() : MockBleScanner();
    final pairing = DevicePairingController(
      scanner: scanner,
      devices: core.devices,
      workspaceId: defaultWorkspaceId,
      scanTimeout: useBle
          ? const Duration(seconds: 15)
          : const Duration(milliseconds: 400),
    );

    MockTransport? appTransport;
    MockTransport? deviceTransport;
    MockOdpDevice? mockDevice;
    MockOdpDeviceLoop? mockLoop;

    if (!useBle) {
      appTransport = MockTransport(name: 'app');
      deviceTransport = MockTransport(name: 'device');
      appTransport.peer = deviceTransport;
      deviceTransport.peer = appTransport;

      mockDevice = MockOdpDevice();
      mockLoop = MockOdpDeviceLoop(
        device: mockDevice,
        transport: deviceTransport,
      );
      mockLoop.start();
    }

    return OcpAppCoordinator._(
      core: core,
      plugins: plugins,
      positionFeed: feed,
      selfPosition: const GeoPoint(latitude: 37.7749, longitude: -122.4194),
      baseDirectory: dir,
      useBleHardware: useBle,
      bleScanner: scanner,
      pairing: pairing,
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

    final scanner = MockBleScanner();
    final pairing = DevicePairingController(
      scanner: scanner,
      devices: core.devices,
      workspaceId: defaultWorkspaceId,
      scanTimeout: const Duration(milliseconds: 50),
    );

    return OcpAppCoordinator._(
      core: core,
      plugins: plugins,
      positionFeed: feed,
      selfPosition: const GeoPoint(latitude: 37.7749, longitude: -122.4194),
      baseDirectory: Directory.systemTemp,
      useBleHardware: false,
      bleScanner: scanner,
      pairing: pairing,
      appTransport: appTransport,
      deviceTransport: deviceTransport,
      mockDevice: mockDevice,
      mockDeviceLoop: mockLoop,
    );
  }

  Future<void> dispose() async {
    await _closeSession(stopPublisher: true);
    await mockDeviceLoop?.stop();
    appTransport?.dispose();
    deviceTransport?.dispose();
    await bleScanner.stop();
    await core.dispose();
  }
}
