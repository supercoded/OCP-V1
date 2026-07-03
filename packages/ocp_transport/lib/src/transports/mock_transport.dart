import 'dart:async';
import 'dart:collection';

import 'package:ocp_transport/src/ocp_transport.dart';

/// Loopback transport for tests and simulator integration.
class MockTransport implements OcpTransport {
  MockTransport({this.name = 'mock'});

  @override
  final String name;

  @override
  TransportState state = TransportState.disconnected;

  final _stateController = StreamController<TransportState>.broadcast();
  final _incomingController = StreamController<List<int>>.broadcast();
  final Queue<List<int>> _outbox = Queue();

  MockTransport? peer;

  @override
  Stream<TransportState> get stateChanges => _stateController.stream;

  @override
  Stream<List<int>> get incoming => _incomingController.stream;

  List<List<int>> get sent => List.unmodifiable(_outbox);

  @override
  Future<void> connect() async {
    state = TransportState.connected;
    _stateController.add(state);
  }

  @override
  Future<void> disconnect() async {
    state = TransportState.disconnected;
    _stateController.add(state);
  }

  @override
  Future<void> send(List<int> data) async {
    _outbox.add(List<int>.from(data));
    peer?._incomingController.add(List<int>.from(data));
  }

  /// Simulates receiving data from peer/device.
  void simulateIncoming(List<int> data) {
    _incomingController.add(data);
  }

  void dispose() {
    _stateController.close();
    _incomingController.close();
  }
}
