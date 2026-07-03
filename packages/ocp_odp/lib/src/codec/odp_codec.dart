import 'package:ocp_odp/src/codec/odp_frame.dart';

/// Encodes and decodes ODP frames per specs/odp-spec.md.
class OdpCodec {
  static const int magic1 = 0x4F;
  static const int magic2 = 0x44;
  static const int protocolVersion = 1;

  List<int> encode(OdpFrame frame) {
    final header = <int>[
      magic1,
      magic2,
      frame.version,
      frame.type.code,
      ..._uint32Le(frame.sequence),
      ..._uint16Le(frame.payload.length),
      ...frame.payload,
    ];
    final crc = _crc32(header);
    return [...header, ..._uint32Le(crc)];
  }

  OdpFrame? decode(List<int> bytes) {
    if (bytes.length < 14) return null;
    if (bytes[0] != magic1 || bytes[1] != magic2) return null;
    final version = bytes[2];
    final type = OdpMessageType.fromCode(bytes[3]);
    final sequence = _readUint32Le(bytes, 4);
    final length = _readUint16Le(bytes, 8);
    if (bytes.length < 10 + length + 4) return null;
    final payload = bytes.sublist(10, 10 + length);
    final expectedCrc = _readUint32Le(bytes, 10 + length);
    final actualCrc = _crc32(bytes.sublist(0, 10 + length));
    if (expectedCrc != actualCrc) return null;
    return OdpFrame(
      version: version,
      type: type,
      sequence: sequence,
      payload: payload,
    );
  }

  List<int> encodeHello({required int sequence, List<int> versions = const [1]}) =>
      encode(
        OdpFrame(
          version: protocolVersion,
          type: OdpMessageType.hello,
          sequence: sequence,
          payload: versions,
        ),
      );

  List<int> encodeHelloAck({
    required int sequence,
    required int selectedVersion,
  }) =>
      encode(
        OdpFrame(
          version: protocolVersion,
          type: OdpMessageType.helloAck,
          sequence: sequence,
          payload: [selectedVersion],
        ),
      );

  static List<int> _uint16Le(int value) => [value & 0xFF, (value >> 8) & 0xFF];

  static List<int> _uint32Le(int value) => [
        value & 0xFF,
        (value >> 8) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 24) & 0xFF,
      ];

  static int _readUint16Le(List<int> bytes, int offset) =>
      bytes[offset] | (bytes[offset + 1] << 8);

  static int _readUint32Le(List<int> bytes, int offset) =>
      bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);

  static int _crc32(List<int> data) {
    var crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
      }
    }
    return crc ^ 0xFFFFFFFF;
  }
}
