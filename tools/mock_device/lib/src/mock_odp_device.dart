import 'package:ocp_odp/ocp_odp.dart';

/// Simulated ODP device for loopback testing.
///
/// Handles the handshake and port-tagged TEXT DATA frames. Text sent from the
/// app is echoed back prefixed with `echo:` so the mock-first messaging path
/// can be exercised without hardware.
class MockOdpDevice {
  MockOdpDevice({OdpCodec? codec}) : _codec = codec ?? OdpCodec();

  final OdpCodec _codec;
  final List<String> _capabilities = ['mock-radio', 'firmware-1.0.0'];
  int _sequence = 0;

  /// Last text the app sent (after decoding the TEXT port).
  String? lastReceivedText;

  /// Handles one inbound ODP frame and returns the response bytes, if any.
  List<int>? handle(List<int> incoming) {
    final frame = _codec.decode(incoming);
    if (frame == null) return null;
    switch (frame.type) {
      case OdpMessageType.hello:
        final version = frame.payload.isNotEmpty ? frame.payload.first : 1;
        return _codec.encodeHelloAck(
          sequence: frame.sequence,
          selectedVersion: version,
        );
      case OdpMessageType.capabilityReq:
        return _codec.encode(
          OdpFrame(
            version: OdpCodec.protocolVersion,
            type: OdpMessageType.capabilityRsp,
            sequence: frame.sequence,
            payload: _capabilities.join(',').codeUnits,
          ),
        );
      case OdpMessageType.data:
        return _handleData(frame);
      default:
        return null;
    }
  }

  /// Builds a device-originated TEXT DATA frame (simulates an inbound mesh message).
  List<int> emitText(String text) {
    _sequence++;
    return _codec.encodePortData(
      sequence: _sequence,
      port: OdpPort.textMessage,
      bytes: text.codeUnits,
    );
  }

  List<int>? _handleData(OdpFrame frame) {
    final payload = OdpDataPayload.decode(frame.payload);
    if (payload == null) return null;
    if (payload.port == OdpPort.textMessage) {
      lastReceivedText = String.fromCharCodes(payload.bytes);
      _sequence++;
      return _codec.encodePortData(
        sequence: _sequence,
        port: OdpPort.textMessage,
        bytes: 'echo: $lastReceivedText'.codeUnits,
      );
    }
    if (payload.port == OdpPort.position) {
      // Position pass-through echo for future location wiring tests.
      _sequence++;
      return _codec.encodePortData(
        sequence: _sequence,
        port: OdpPort.position,
        bytes: payload.bytes,
      );
    }
    return null;
  }
}
