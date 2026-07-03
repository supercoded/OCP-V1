import 'dart:async';

import 'package:mock_device/src/mock_odp_device.dart';
import 'package:ocp_bridge_meshtastic/ocp_bridge_meshtastic.dart';
import 'package:ocp_transport/ocp_transport.dart';

/// Wires a [MockOdpDevice] to the device-side [MockTransport] peer.
///
/// Every frame the app sends is passed through [MockOdpDevice.handle] and the
/// response is written back on the transport. Use [emitText] to simulate an
/// unsolicited inbound message from the mesh.
class MockOdpDeviceLoop {
  MockOdpDeviceLoop({
    required MockOdpDevice device,
    required MockTransport transport,
  })  : _device = device,
        _transport = transport;

  final MockOdpDevice _device;
  final MockTransport _transport;
  StreamSubscription<List<int>>? _subscription;

  MockOdpDevice get device => _device;

  /// Starts responding to inbound transport frames.
  void start() {
    _subscription ??= _transport.incoming.listen(_onIncoming);
  }

  /// Stops the response loop.
  Future<void> stop() async {
    await _subscription?.cancel();
    _subscription = null;
  }

  /// Simulates the device pushing a text message to the app.
  Future<void> emitText(String text) async {
    await _transport.send(_device.emitText(text));
  }

  /// Simulates a POSITION report from the mesh for [nodeId].
  Future<void> emitPosition(
    MeshtasticPosition position, {
    required String nodeId,
  }) async {
    await _transport.send(_device.emitPosition(position, nodeId: nodeId));
  }

  Future<void> _onIncoming(List<int> data) async {
    final response = _device.handle(data);
    if (response != null) {
      await _transport.send(response);
    }
  }
}
