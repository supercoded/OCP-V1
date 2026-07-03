import 'dart:convert';
import 'dart:typed_data';

import 'package:ocp_bridge_meshtastic/ocp_bridge_meshtastic.dart';

/// Minimal Meshtastic protobuf encoder/decoder for BLE ToRadio/FromRadio.
///
/// Hand-rolled wire format for the subset OCP needs: config handshake, text,
/// and position packets. See Meshtastic `mesh.proto` / `portnums.proto`.
abstract final class MeshtasticProto {
  static const int portText = 1;
  static const int portPosition = 3;
  static const int broadcastNodeId = 0xFFFFFFFF;

  /// `ToRadio { want_config_id = id }` — starts the device config download.
  static Uint8List encodeWantConfig({int configId = 1}) {
    final writer = _ProtoWriter();
    writer.writeUint32Field(11, configId);
    return writer.build();
  }

  /// `ToRadio { packet = MeshPacket{ decoded = Data{ portnum, payload }}}`.
  static Uint8List encodeTextToRadio(
    String text, {
    required int packetId,
    int channel = 0,
  }) {
    final data = _ProtoWriter()
      ..writeVarintField(1, portText)
      ..writeBytesField(2, utf8.encode(text));

    final mesh = _ProtoWriter()
      ..writeFixed32Field(2, broadcastNodeId)
      ..writeVarintField(3, channel)
      ..writeBytesField(4, data.build())
      ..writeVarintField(6, packetId);

    final toRadio = _ProtoWriter()..writeBytesField(1, mesh.build());
    return toRadio.build();
  }

  /// Encodes a Meshtastic `Position` protobuf as POSITION_APP payload bytes.
  static Uint8List encodePositionPayload(MeshtasticPosition position) {
    final writer = _ProtoWriter()
      ..writeSint32Field(1, position.latitudeI)
      ..writeSint32Field(2, position.longitudeI);
    if (position.altitudeMeters != null) {
      writer.writeSint32Field(3, position.altitudeI);
    }
    if (position.time != null) {
      writer.writeFixed32Field(4, position.unixSeconds);
    }
    return writer.build();
  }

  static Uint8List encodePositionToRadio(
    MeshtasticPosition position, {
    required int packetId,
    int channel = 0,
  }) {
    final payload = encodePositionPayload(position);

    final data = _ProtoWriter()
      ..writeVarintField(1, portPosition)
      ..writeBytesField(2, payload);

    final mesh = _ProtoWriter()
      ..writeFixed32Field(2, broadcastNodeId)
      ..writeVarintField(3, channel)
      ..writeBytesField(4, data.build())
      ..writeVarintField(6, packetId);

    final toRadio = _ProtoWriter()..writeBytesField(1, mesh.build());
    return toRadio.build();
  }

  /// Parses a `FromRadio` blob. Returns decoded app payloads when present.
  static List<MeshtasticAppPayload> decodeFromRadio(Uint8List bytes) {
    final reader = _ProtoReader(bytes);
    final payloads = <MeshtasticAppPayload>[];

    while (reader.hasMore) {
      final field = reader.readTag();
      if (field.fieldNumber == 2 && field.wireType == 2) {
        payloads.addAll(decodeMeshPacket(reader.readBytes()));
      } else if (field.fieldNumber == 7 && field.wireType == 0) {
        // config_complete_id — handshake milestone.
        reader.readVarint();
      } else {
        reader.skipField(field);
      }
    }
    return payloads;
  }

  static List<MeshtasticAppPayload> decodeMeshPacket(Uint8List bytes) {
    final reader = _ProtoReader(bytes);
    var portnum = 0;
    var payload = Uint8List(0);
    var fromNode = 0;

    while (reader.hasMore) {
      final field = reader.readTag();
      switch (field.fieldNumber) {
        case 1 when field.wireType == 5:
          fromNode = reader.readFixed32();
        case 4 when field.wireType == 2:
          final decoded = decodeData(reader.readBytes());
          portnum = decoded.portnum;
          payload = decoded.payload;
        default:
          reader.skipField(field);
      }
    }

    if (portnum == 0) return const [];
    return [
      MeshtasticAppPayload(
        portnum: portnum,
        payload: payload,
        fromNode: fromNode == 0 ? null : fromNode,
      ),
    ];
  }

  static ({int portnum, Uint8List payload}) decodeData(Uint8List bytes) {
    final reader = _ProtoReader(bytes);
    var portnum = 0;
    var payload = Uint8List(0);
    while (reader.hasMore) {
      final field = reader.readTag();
      if (field.fieldNumber == 1 && field.wireType == 0) {
        portnum = reader.readVarint();
      } else if (field.fieldNumber == 2 && field.wireType == 2) {
        payload = reader.readBytes();
      } else {
        reader.skipField(field);
      }
    }
    return (portnum: portnum, payload: payload);
  }

  /// Parses Meshtastic `Position` protobuf bytes (POSITION_APP).
  static MeshtasticPosition? decodePositionPayload(Uint8List bytes) {
    // OCP compact tail layout from mock feeds.
    final bridged = MeshtasticBridge.decodePositionPayload(bytes);
    if (bridged != null) return bridged;

    final reader = _ProtoReader(bytes);
    int? latI;
    int? lonI;
    int? alt;
    int? time;
    while (reader.hasMore) {
      final field = reader.readTag();
      switch (field.fieldNumber) {
        case 1 when field.wireType == 0:
          latI = reader.readSint32();
        case 2 when field.wireType == 0:
          lonI = reader.readSint32();
        case 3 when field.wireType == 0:
          alt = reader.readSint32();
        case 4 when field.wireType == 5:
          time = reader.readFixed32();
        default:
          reader.skipField(field);
      }
    }
    if (latI == null || lonI == null) return null;
    return MeshtasticPosition.fromIntegers(
      latitudeI: latI,
      longitudeI: lonI,
      altitudeMeters: alt,
      unixSeconds: time,
    );
  }
}

/// A decoded Meshtastic application payload from a mesh packet.
class MeshtasticAppPayload {
  const MeshtasticAppPayload({
    required this.portnum,
    required this.payload,
    this.fromNode,
  });

  final int portnum;
  final Uint8List payload;
  final int? fromNode;
}

class _ProtoWriter {
  final BytesBuilder _builder = BytesBuilder();

  Uint8List build() => _builder.toBytes();

  void writeVarintField(int fieldNumber, int value) {
    _writeTag(fieldNumber, 0);
    _writeVarint(value);
  }

  void writeUint32Field(int fieldNumber, int value) {
    writeVarintField(fieldNumber, value);
  }

  void writeSint32Field(int fieldNumber, int value) {
    writeVarintField(fieldNumber, _encodeZigZag32(value));
  }

  void writeFixed32Field(int fieldNumber, int value) {
    _writeTag(fieldNumber, 5);
    final bytes = ByteData(4)..setUint32(0, value, Endian.little);
    _builder.add(bytes.buffer.asUint8List());
  }

  void writeBytesField(int fieldNumber, List<int> bytes) {
    _writeTag(fieldNumber, 2);
    _writeVarint(bytes.length);
    _builder.add(bytes);
  }

  void _writeTag(int fieldNumber, int wireType) {
    _writeVarint((fieldNumber << 3) | wireType);
  }

  void _writeVarint(int value) {
    var v = value;
    while (v > 0x7F) {
      _builder.addByte((v & 0x7F) | 0x80);
      v >>= 7;
    }
    _builder.addByte(v & 0x7F);
  }
}

class _FieldTag {
  const _FieldTag({required this.fieldNumber, required this.wireType});
  final int fieldNumber;
  final int wireType;
}

class _ProtoReader {
  _ProtoReader(this._bytes);

  final Uint8List _bytes;
  var _offset = 0;

  bool get hasMore => _offset < _bytes.length;

  _FieldTag readTag() {
    final tag = readVarint();
    return _FieldTag(fieldNumber: tag >> 3, wireType: tag & 0x7);
  }

  int readVarint() {
    var shift = 0;
    var result = 0;
    while (true) {
      if (_offset >= _bytes.length) break;
      final byte = _bytes[_offset++];
      result |= (byte & 0x7F) << shift;
      if (byte < 0x80) break;
      shift += 7;
    }
    return result;
  }

  int readSint32() => _decodeZigZag32(readVarint());

  int readFixed32() {
    final value = ByteData.sublistView(_bytes, _offset, _offset + 4)
        .getUint32(0, Endian.little);
    _offset += 4;
    return value;
  }

  Uint8List readBytes() {
    final length = readVarint();
    final end = _offset + length;
    final slice = _bytes.sublist(_offset, end);
    _offset = end;
    return slice;
  }

  void skipField(_FieldTag field) {
    switch (field.wireType) {
      case 0:
        readVarint();
      case 1:
        _offset += 8;
      case 2:
        _offset += readVarint();
      case 5:
        _offset += 4;
      default:
        break;
    }
  }
}

int _encodeZigZag32(int value) => (value << 1) ^ (value >> 31);

int _decodeZigZag32(int value) => (value >> 1) ^ (-(value & 1));
