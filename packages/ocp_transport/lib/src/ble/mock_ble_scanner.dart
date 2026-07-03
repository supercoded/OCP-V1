import 'dart:async';

import 'package:ocp_transport/src/ble/ble_scanner.dart';

/// Deterministic [BleScanner] for tests and the MVP demo.
///
/// Emits a scripted mix of Meshtastic boards (RAK4631, LilyGo) and an unrelated
/// peripheral so the auto-detect filter can be exercised without hardware.
class MockBleScanner implements BleScanner {
  MockBleScanner({List<BleDiscoveredDevice>? devices, this.emitInterval})
      : _devices = devices ?? _defaultDevices;

  final List<BleDiscoveredDevice> _devices;

  /// Optional delay between emissions (defaults to none for fast tests).
  final Duration? emitInterval;

  StreamController<BleDiscoveredDevice>? _controller;

  static final List<BleDiscoveredDevice> _defaultDevices = [
    const BleDiscoveredDevice(
      id: 'AA:BB:CC:00:11:22',
      name: 'Meshtastic_RAK4631',
      serviceUuids: [MeshtasticBle.serviceUuid],
      rssi: -52,
    ),
    const BleDiscoveredDevice(
      id: 'AA:BB:CC:33:44:55',
      name: 'Meshtastic_LilyGo_TBeam',
      serviceUuids: [MeshtasticBle.serviceUuid],
      rssi: -67,
    ),
    const BleDiscoveredDevice(
      id: 'AA:BB:CC:66:77:88',
      name: 'Some Headphones',
      serviceUuids: ['0000110b-0000-1000-8000-00805f9b34fb'],
      rssi: -80,
    ),
  ];

  @override
  Stream<BleDiscoveredDevice> scan() {
    final controller = StreamController<BleDiscoveredDevice>();
    _controller = controller;

    Future<void> pump() async {
      for (final device in _devices) {
        if (controller.isClosed) return;
        if (emitInterval != null) {
          await Future<void>.delayed(emitInterval!);
        }
        if (controller.isClosed) return;
        controller.add(device);
      }
      // A mock scan emits a finite scripted set, then completes. A real scanner
      // runs until stop(); the pairing controller bounds both with a timeout.
      if (!controller.isClosed) await controller.close();
    }

    unawaited(pump());
    return controller.stream;
  }

  @override
  Future<void> stop() async {
    await _controller?.close();
    _controller = null;
  }
}
