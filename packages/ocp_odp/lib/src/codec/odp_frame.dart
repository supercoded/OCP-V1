/// ODP message types per specs/odp-spec.md.
enum OdpMessageType {
  hello(0x01),
  helloAck(0x02),
  capabilityReq(0x03),
  capabilityRsp(0x04),
  data(0x10),
  error(0xFF);

  const OdpMessageType(this.code);
  final int code;

  static OdpMessageType fromCode(int code) => OdpMessageType.values.firstWhere(
        (type) => type.code == code,
        orElse: () => OdpMessageType.error,
      );
}

/// Parsed ODP frame.
class OdpFrame {
  const OdpFrame({
    required this.version,
    required this.type,
    required this.sequence,
    required this.payload,
  });

  final int version;
  final OdpMessageType type;
  final int sequence;
  final List<int> payload;
}
