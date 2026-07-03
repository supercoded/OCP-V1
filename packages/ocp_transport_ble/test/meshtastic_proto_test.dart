import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';
import 'package:ocp_bridge_meshtastic/ocp_bridge_meshtastic.dart';
import 'package:ocp_transport_ble/src/meshtastic_proto.dart';

void main() {
  group('MeshtasticProto', () {
    test('encodeWantConfig produces non-empty ToRadio', () {
      final bytes = MeshtasticProto.encodeWantConfig(configId: 42);
      expect(bytes, isNotEmpty);
    });

    test('round-trip text through decodeMeshPacket', () {
      final toRadio = MeshtasticProto.encodeTextToRadio(
        'hello mesh',
        packetId: 7,
      );
      final mesh = _readToRadioPacket(toRadio);
      final payloads = MeshtasticProto.decodeMeshPacket(mesh);
      expect(payloads, hasLength(1));
      expect(payloads.first.portnum, MeshtasticProto.portText);
      expect(utf8.decode(payloads.first.payload), 'hello mesh');
    });

    test('round-trip position through decodeMeshPacket', () {
      const position = MeshtasticPosition(
        latitude: 37.7749,
        longitude: -122.4194,
        altitudeMeters: 10,
      );
      final toRadio = MeshtasticProto.encodePositionToRadio(
        position,
        packetId: 3,
      );
      final mesh = _readToRadioPacket(toRadio);
      final payloads = MeshtasticProto.decodeMeshPacket(mesh);
      expect(payloads, hasLength(1));
      expect(payloads.first.portnum, MeshtasticProto.portPosition);

      final decoded = MeshtasticProto.decodePositionPayload(
        payloads.first.payload,
      );
      expect(decoded, isNotNull);
      expect(decoded!.latitude, closeTo(37.7749, 0.0001));
      expect(decoded.longitude, closeTo(-122.4194, 0.0001));
    });

    test('decodeFromRadio extracts fromNode on mesh packets', () {
      final data = _ProtoWriter()
        ..writeVarintField(1, MeshtasticProto.portText)
        ..writeBytesField(2, utf8.encode('ping'));

      final mesh = _ProtoWriter()
        ..writeFixed32Field(1, 0x12345678)
        ..writeBytesField(4, data.build());

      final fromRadio = _ProtoWriter()..writeBytesField(2, mesh.build());
      final payloads = MeshtasticProto.decodeFromRadio(fromRadio.build());
      expect(payloads.first.fromNode, 0x12345678);
    });
  });
}

// Minimal writer mirror for constructing synthetic FromRadio test blobs.
class _ProtoWriter {
  final BytesBuilder _builder = BytesBuilder();

  Uint8List build() => _builder.toBytes();

  void writeVarintField(int fieldNumber, int value) {
    _writeTag(fieldNumber, 0);
    _writeVarint(value);
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

Uint8List _readToRadioPacket(Uint8List toRadio) {
  var offset = 0;
  while (offset < toRadio.length) {
    final tag = toRadio[offset++];
    final fieldNumber = tag >> 3;
    final wireType = tag & 0x7;
    if (fieldNumber == 1 && wireType == 2) {
      var length = 0;
      var shift = 0;
      while (true) {
        final byte = toRadio[offset++];
        length |= (byte & 0x7F) << shift;
        if (byte < 0x80) break;
        shift += 7;
      }
      return Uint8List.fromList(toRadio.sublist(offset, offset + length));
    }
    if (wireType == 2) {
      var length = 0;
      var shift = 0;
      while (true) {
        final byte = toRadio[offset++];
        length |= (byte & 0x7F) << shift;
        if (byte < 0x80) break;
        shift += 7;
      }
      offset += length;
    }
  }
  throw StateError('ToRadio packet field missing');
}
