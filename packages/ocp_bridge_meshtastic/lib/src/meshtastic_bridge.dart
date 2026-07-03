import 'package:ocp_odp/ocp_odp.dart';

/// Simplified Meshtastic → ODP translator.
///
/// Production bridge would use published Meshtastic protobuf definitions.
class MeshtasticBridge {
  MeshtasticBridge({OdpCodec? codec}) : _codec = codec ?? OdpCodec();

  final OdpCodec _codec;
  int _sequence = 0;

  /// Converts a Meshtastic packet payload into an ODP DATA frame.
  List<int> toOdp(List<int> meshtasticPayload) {
    _sequence++;
    return _codec.encode(
      OdpFrame(
        version: OdpCodec.protocolVersion,
        type: OdpMessageType.data,
        sequence: _sequence,
        payload: meshtasticPayload,
      ),
    );
  }

  /// Extracts Meshtastic payload from ODP DATA frame.
  List<int>? fromOdp(List<int> odpFrame) {
    final frame = _codec.decode(odpFrame);
    if (frame == null || frame.type != OdpMessageType.data) return null;
    return frame.payload;
  }

  /// Returns device firmware info from a capability response payload.
  String? parseFirmwareVersion(List<int> capabilityPayload) {
    if (capabilityPayload.isEmpty) return null;
    return String.fromCharCodes(capabilityPayload);
  }
}
