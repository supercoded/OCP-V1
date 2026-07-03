import 'package:ocp_transport/src/ocp_transport.dart';

/// TCP/IP transport stub for post-v1 implementation.
class TcpTransport implements OcpTransport {
  TcpTransport({this.host = '127.0.0.1', this.port = 18888});

  final String host;
  final int port;

  @override
  String get name => 'tcp';

  @override
  TransportState state = TransportState.disconnected;

  @override
  Stream<TransportState> get stateChanges => const Stream.empty();

  @override
  Stream<List<int>> get incoming => const Stream.empty();

  @override
  Future<void> connect() async {
  }

  @override
  Future<void> disconnect() async {
    state = TransportState.disconnected;
  }

  @override
  Future<void> send(List<int> data) async {
    throw UnimplementedError('TCP transport not implemented in v1');
  }
}
