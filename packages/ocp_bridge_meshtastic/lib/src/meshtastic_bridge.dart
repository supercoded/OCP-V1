import 'package:ocp_bridge_meshtastic/src/bridge_message.dart';
import 'package:ocp_bridge_meshtastic/src/meshtastic_position.dart';
import 'package:ocp_odp/ocp_odp.dart';

/// Meshtastic PortNum values the bridge understands.
///
/// Values match upstream Meshtastic (`TEXT_MESSAGE_APP = 1`,
/// `POSITION_APP = 3`), so they map straight onto [OdpPort].
enum MeshtasticPortnum {
  textMessage(1),
  position(3);

  const MeshtasticPortnum(this.code);
  final int code;
}

/// Bridges Meshtastic application frames to/from ODP.
///
/// Text and position are translated to port-tagged ODP DATA frames
/// (build-plan-v2 Phase 1 / Phase 5). The on-air Meshtastic `Position` is a
/// protobuf; this bridge carries a fixed subset in a compact little-endian
/// layout — see `specs/odp-spec.md` (POSITION port).
class MeshtasticBridge {
  MeshtasticBridge({OdpCodec? codec}) : _codec = codec ?? OdpCodec();

  final OdpCodec _codec;
  int _sequence = 0;

  int _nextSequence() => ++_sequence;

  /// Wraps an opaque Meshtastic payload in an ODP DATA frame (legacy path).
  List<int> toOdp(List<int> meshtasticPayload) {
    return _codec.encode(
      OdpFrame(
        version: OdpCodec.protocolVersion,
        type: OdpMessageType.data,
        sequence: _nextSequence(),
        payload: meshtasticPayload,
      ),
    );
  }

  /// Extracts the raw payload from an ODP DATA frame (legacy path).
  List<int>? fromOdp(List<int> odpFrame) {
    final frame = _codec.decode(odpFrame);
    if (frame == null || frame.type != OdpMessageType.data) return null;
    return frame.payload;
  }

  /// Encodes a [BridgeMessage] into a port-tagged ODP DATA frame.
  List<int> encodeToOdp(BridgeMessage message) {
    switch (message) {
      case TextBridgeMessage(:final text):
        return _codec.encodePortData(
          sequence: _nextSequence(),
          port: OdpPort.textMessage,
          bytes: _utf8(text),
        );
      case PositionBridgeMessage(:final position):
        return _codec.encodePortData(
          sequence: _nextSequence(),
          port: OdpPort.position,
          bytes: encodePositionPayload(position),
        );
    }
  }

  /// Decodes a port-tagged ODP DATA frame into a [BridgeMessage].
  ///
  /// Returns `null` for non-DATA frames or unmapped ports.
  BridgeMessage? decodeFromOdp(List<int> odpFrame) {
    final payload = _codec.decodePortData(odpFrame);
    if (payload == null) return null;
    switch (payload.port) {
      case OdpPort.textMessage:
        return TextBridgeMessage(String.fromCharCodes(payload.bytes));
      case OdpPort.position:
        final position = decodePositionPayload(payload.bytes);
        return position == null ? null : PositionBridgeMessage(position);
      case OdpPort.unknown:
        return null;
    }
  }

  /// Translates a decoded Meshtastic frame (portnum + app bytes) to a
  /// [BridgeMessage]. Returns `null` for portnums the bridge does not handle.
  BridgeMessage? meshtasticToBridge(int portnum, List<int> appPayload) {
    if (portnum == MeshtasticPortnum.textMessage.code) {
      return TextBridgeMessage(String.fromCharCodes(appPayload));
    }
    if (portnum == MeshtasticPortnum.position.code) {
      final position = decodePositionPayload(appPayload);
      return position == null ? null : PositionBridgeMessage(position);
    }
    return null;
  }

  /// Returns device firmware info from a capability response payload.
  String? parseFirmwareVersion(List<int> capabilityPayload) {
    if (capabilityPayload.isEmpty) return null;
    return String.fromCharCodes(capabilityPayload);
  }

  /// Serializes a position into the ODP POSITION payload layout:
  /// `lat_i, lon_i, alt_i (int32 LE), time (uint32 LE)`.
  static List<int> encodePositionPayload(MeshtasticPosition position) => [
        ..._int32Le(position.latitudeI),
        ..._int32Le(position.longitudeI),
        ..._int32Le(position.altitudeI),
        ..._uint32Le(position.unixSeconds),
      ];

  /// Parses the ODP POSITION payload layout. Returns `null` if too short.
  static MeshtasticPosition? decodePositionPayload(List<int> bytes) {
    if (bytes.length < 16) return null;
    return MeshtasticPosition.fromIntegers(
      latitudeI: _readInt32Le(bytes, 0),
      longitudeI: _readInt32Le(bytes, 4),
      altitudeMeters: _readInt32Le(bytes, 8),
      unixSeconds: _readUint32Le(bytes, 12),
    );
  }

  static List<int> _utf8(String text) => text.codeUnits;

  static List<int> _uint32Le(int value) => [
        value & 0xFF,
        (value >> 8) & 0xFF,
        (value >> 16) & 0xFF,
        (value >> 24) & 0xFF,
      ];

  static List<int> _int32Le(int value) => _uint32Le(value & 0xFFFFFFFF);

  static int _readUint32Le(List<int> bytes, int offset) =>
      bytes[offset] |
      (bytes[offset + 1] << 8) |
      (bytes[offset + 2] << 16) |
      (bytes[offset + 3] << 24);

  static int _readInt32Le(List<int> bytes, int offset) {
    final unsigned = _readUint32Le(bytes, offset);
    return unsigned >= 0x80000000 ? unsigned - 0x100000000 : unsigned;
  }
}
