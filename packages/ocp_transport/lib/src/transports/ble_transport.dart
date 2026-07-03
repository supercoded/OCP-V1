import 'package:ocp_transport/src/ocp_transport.dart';

/// BLE transport stub — platform implementation wired in mobile builds.
class BleTransport implements OcpTransport {
  BleTransport({this.deviceId = 'ble-device'});

  final String deviceId;

  @override
  String get name => 'ble';

  @override
  TransportState state = TransportState.disconnected;

  @override
  Stream<TransportState> get stateChanges => const Stream.empty();

  @override
  Stream<List<int>> get incoming => const Stream.empty();

  @override
  Future<void> connect() async {
    state = TransportState.connected;
  }

  @override
  Future<void> disconnect() async {
    state = TransportState.disconnected;
  }

  @override
  Future<void> send(List<int> data) async {
    if (state != TransportState.connected) {
      throw StateError('BLE transport not connected');
    }
  }
}
