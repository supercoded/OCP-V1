import 'package:ocp_core/ocp_core.dart';
import 'package:ocp_odp/ocp_odp.dart';
import 'package:ocp_transport/ocp_transport.dart';

/// Result of a pairing attempt.
class PairingResult {
  const PairingResult({required this.success, this.device, this.reason});

  final bool success;
  final Device? device;
  final String? reason;
}

/// Orchestrates the "scan → auto-detect Meshtastic → one-tap pair" flow.
///
/// Hardware-independent: BLE discovery sits behind [BleScanner] and the ODP
/// handshake behind an injected `exchange` function, so the whole flow is unit
/// testable and, for the MVP, driven by mock implementations. The real build
/// swaps in a `flutter_blue_plus`-backed scanner and a BLE characteristic
/// exchange without touching this logic.
class DevicePairingController {
  DevicePairingController({
    required BleScanner scanner,
    required DeviceRepository devices,
    required this.workspaceId,
    this.scanTimeout = const Duration(seconds: 4),
    OdpConnection Function()? connectionFactory,
  })  : _scanner = scanner,
        _devices = devices,
        _connectionFactory = connectionFactory ?? OdpConnection.new;

  final BleScanner _scanner;
  final DeviceRepository _devices;
  final String workspaceId;
  final Duration scanTimeout;
  final OdpConnection Function() _connectionFactory;

  /// Scans and returns only auto-detected Meshtastic devices (deduped by id).
  Future<List<BleDiscoveredDevice>> scanForMeshtastic() async {
    final results = <BleDiscoveredDevice>[];
    final seen = <String>{};
    final sub = _scanner.scan().where(MeshtasticBle.isMeshtastic).listen(
      (device) {
        if (seen.add(device.id)) results.add(device);
      },
    );
    await Future<void>.delayed(scanTimeout);
    await sub.cancel();
    await _scanner.stop();
    return results;
  }

  /// Pairs [discovered]: runs the ODP handshake over [exchange] and, on
  /// success, persists a paired [Device].
  Future<PairingResult> pair(
    BleDiscoveredDevice discovered, {
    required Future<List<int>> Function(List<int> outgoing) exchange,
  }) async {
    final connection = _connectionFactory();
    final ok = await connection.runHandshake(exchange);
    final version = connection.negotiatedVersion;
    connection.dispose();

    if (!ok) {
      return const PairingResult(
        success: false,
        reason: 'ODP handshake failed',
      );
    }

    final now = DateTime.now().toUtc();
    final device = Device(
      deviceId: discovered.id,
      workspaceId: workspaceId,
      name: discovered.name,
      transportType: 'ble',
      capabilities: const ['meshtastic', 'lora'],
      firmwareVersion: version == null ? null : 'odp-v$version',
      isPaired: true,
      lastSeenAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await _devices.save(device);
    return PairingResult(success: true, device: device);
  }

  /// Pairs [discovered] after BLE link verification (no ODP handshake).
  Future<PairingResult> pairVerified(BleDiscoveredDevice discovered) async {
    final now = DateTime.now().toUtc();
    final device = Device(
      deviceId: discovered.id,
      workspaceId: workspaceId,
      name: discovered.name,
      transportType: 'ble',
      capabilities: const ['meshtastic', 'lora'],
      firmwareVersion: 'meshtastic-ble',
      isPaired: true,
      lastSeenAt: now,
      createdAt: now,
      updatedAt: now,
    );
    await _devices.save(device);
    return PairingResult(success: true, device: device);
  }
}
