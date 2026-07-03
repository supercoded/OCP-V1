import 'dart:async';

import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:ocp_transport/ocp_transport.dart';
import 'package:ocp_transport_ble/src/meshtastic_ble_transport.dart';

/// [BleScanner] backed by [flutter_blue_plus] on Android/iOS.
class FlutterBleScanner implements BleScanner {
  StreamSubscription<List<ScanResult>>? _subscription;
  StreamController<BleDiscoveredDevice>? _controller;

  @override
  Stream<BleDiscoveredDevice> scan() {
    final controller = StreamController<BleDiscoveredDevice>();
    _controller = controller;

    unawaited(_startScan(controller));
    return controller.stream;
  }

  Future<void> _startScan(StreamController<BleDiscoveredDevice> controller) async {
    await MeshtasticBleTransport.ensureReady();

    await FlutterBluePlus.startScan(
      withServices: [Guid(MeshtasticBle.serviceUuid)],
      timeout: const Duration(seconds: 15),
    );

    _subscription = FlutterBluePlus.scanResults.listen((results) {
      for (final result in results) {
        final name = result.device.platformName.isNotEmpty
            ? result.device.platformName
            : result.device.remoteId.str;
        final uuids = result.advertisementData.serviceUuids
            .map((g) => g.str.toLowerCase())
            .toList();
        controller.add(
          BleDiscoveredDevice(
            id: result.device.remoteId.str,
            name: name,
            serviceUuids: uuids,
            rssi: result.rssi,
          ),
        );
      }
    });

    controller.onCancel = () async {
      await stop();
    };
  }

  @override
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
    await FlutterBluePlus.stopScan();
    await _controller?.close();
    _controller = null;
  }
}
