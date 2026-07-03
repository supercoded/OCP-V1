import 'package:ocp_odp/src/codec/odp_codec.dart';
import 'package:ocp_odp/src/codec/odp_frame.dart';

/// Application port carried inside an ODP DATA frame.
///
/// Port codes are chosen to line up with the Meshtastic PortNum values the
/// bridge translates (`TEXT_MESSAGE_APP = 1`, `POSITION_APP = 3`), so the
/// mapping is a direct pass-through. See `specs/odp-spec.md`.
enum OdpPort {
  unknown(0x00),
  textMessage(0x01),
  position(0x03);

  const OdpPort(this.code);
  final int code;

  static OdpPort fromCode(int code) => OdpPort.values.firstWhere(
        (port) => port.code == code,
        orElse: () => OdpPort.unknown,
      );
}

/// A port-tagged DATA payload: a single port byte followed by the app bytes.
class OdpDataPayload {
  const OdpDataPayload({required this.port, required this.bytes});

  final OdpPort port;
  final List<int> bytes;

  /// Serializes to `[portCode, ...bytes]`.
  List<int> encode() => [port.code, ...bytes];

  /// Parses a DATA-frame payload. Returns `null` when empty.
  static OdpDataPayload? decode(List<int> payload) {
    if (payload.isEmpty) return null;
    return OdpDataPayload(
      port: OdpPort.fromCode(payload.first),
      bytes: payload.sublist(1),
    );
  }
}

/// Port-aware helpers over [OdpCodec].
extension OdpPortCodec on OdpCodec {
  /// Encodes a port-tagged DATA frame.
  List<int> encodePortData({
    required int sequence,
    required OdpPort port,
    required List<int> bytes,
  }) =>
      encode(
        OdpFrame(
          version: OdpCodec.protocolVersion,
          type: OdpMessageType.data,
          sequence: sequence,
          payload: OdpDataPayload(port: port, bytes: bytes).encode(),
        ),
      );

  /// Decodes a frame's DATA payload as a port-tagged payload, or `null` if the
  /// bytes are not a valid DATA frame.
  OdpDataPayload? decodePortData(List<int> bytes) {
    final frame = decode(bytes);
    if (frame == null || frame.type != OdpMessageType.data) return null;
    return OdpDataPayload.decode(frame.payload);
  }
}
