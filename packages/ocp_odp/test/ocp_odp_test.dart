import 'package:ocp_odp/ocp_odp.dart';
import 'package:ocp_odp/src/codec/odp_frame.dart';
import 'package:test/test.dart';

void main() {
  final codec = OdpCodec();

  test('round-trip hello frame', () {
    final bytes = codec.encodeHello(sequence: 1);
    final frame = codec.decode(bytes);
    expect(frame?.type, OdpMessageType.hello);
    expect(frame?.sequence, 1);
  });

  test('connection completes handshake', () async {
    final connection = OdpConnection();
    final success = await connection.runHandshake((outgoing) async {
      final frame = codec.decode(outgoing);
      if (frame?.type == OdpMessageType.hello) {
        return codec.encodeHelloAck(sequence: frame!.sequence, selectedVersion: 1);
      }
      return codec.encode(
        OdpFrame(
          version: OdpCodec.protocolVersion,
          type: OdpMessageType.capabilityRsp,
          sequence: frame!.sequence,
          payload: [1, 2, 3],
        ),
      );
    });
    expect(success, isTrue);
    connection.dispose();
  });

  test('hello ack connects', () {
    final connection = OdpConnection();
    connection.beginHandshake();
    final ack = codec.encodeHelloAck(sequence: 1, selectedVersion: 1);
    expect(connection.handleFrame(ack), isTrue);
    expect(connection.state, OdpState.connected);
    connection.dispose();
  });
}
