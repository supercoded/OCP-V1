/// A device found during a BLE scan.
class BleDiscoveredDevice {
  const BleDiscoveredDevice({
    required this.id,
    required this.name,
    this.serviceUuids = const [],
    this.rssi,
  });

  /// Platform device identifier (MAC on Android, UUID on iOS/macOS).
  final String id;
  final String name;

  /// Advertised GATT service UUIDs (lower-case, canonical form).
  final List<String> serviceUuids;

  /// Signal strength in dBm, when reported.
  final int? rssi;
}

/// Scans for nearby BLE peripherals.
///
/// The concrete mobile implementation is backed by a platform plugin (e.g.
/// `flutter_blue_plus`); [MockBleScanner] provides a deterministic feed so the
/// pairing flow is buildable and testable without hardware.
abstract interface class BleScanner {
  /// Emits devices as they are discovered until [stop] is called.
  Stream<BleDiscoveredDevice> scan();

  /// Stops an in-progress scan.
  Future<void> stop();
}

/// Known Meshtastic BLE identifiers used for auto-detection and I/O.
///
/// UUIDs match the Meshtastic BLE API served by RAK4631 and LilyGo boards.
abstract final class MeshtasticBle {
  /// Primary Meshtastic GATT service.
  static const String serviceUuid = '6ba1b218-15a8-461f-9fa8-5dcae273eafd';

  /// Characteristic the app writes `ToRadio` frames to.
  static const String toRadioCharacteristic =
      'f75c76d2-129e-4dad-a1dd-7866124401e7';

  /// Characteristic the app reads/subscribes `FromRadio` frames from.
  static const String fromRadioCharacteristic =
      '2c55e69e-4993-11ed-b878-0242ac120002';

  /// Whether [device] advertises the Meshtastic service (the "with ease"
  /// auto-detect path).
  static bool isMeshtastic(BleDiscoveredDevice device) {
    return device.serviceUuids
        .map((uuid) => uuid.toLowerCase())
        .contains(serviceUuid);
  }
}
