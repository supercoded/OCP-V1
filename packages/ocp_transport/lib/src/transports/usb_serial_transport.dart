import 'package:ocp_transport/src/ocp_transport.dart';

/// USB Serial transport stub for desktop platforms.
class UsbSerialTransport implements OcpTransport {
  UsbSerialTransport({this.portName = 'usb0'});

  final String portName;

  @override
  String get name => 'usb_serial';

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
      throw StateError('USB serial transport not connected');
    }
  }
}
