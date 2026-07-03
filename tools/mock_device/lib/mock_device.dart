import 'package:ocp_odp/ocp_odp.dart';

/// Simulated ODP device for loopback testing.
class MockOdpDevice {
  MockOdpDevice({OdpCodec? codec}) : _codec = codec ?? OdpCodec();

  final OdpCodec _codec;
  final List<String> _capabilities = ['mock-radio', 'firmware-1.0.0'];

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
      default:
        return _codec.encode(
          OdpFrame(
            version: OdpCodec.protocolVersion,
            type: OdpMessageType.data,
            sequence: frame.sequence,
            payload: const [0x00],
          ),
        );
    }
  }
}
