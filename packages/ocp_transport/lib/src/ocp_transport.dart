/// Transport connection state.
enum TransportState { disconnected, connecting, connected, error }

/// Hardware transport abstraction.
abstract class OcpTransport {
  String get name;

  TransportState get state;

  Stream<TransportState> get stateChanges;

  Stream<List<int>> get incoming;

  Future<void> connect();

  Future<void> disconnect();

  Future<void> send(List<int> data);
}
