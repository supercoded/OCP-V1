import 'package:ocp_odp/ocp_odp.dart';
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

  test('round-trips a port-tagged text DATA frame', () {
    final bytes = codec.encodePortData(
      sequence: 7,
      port: OdpPort.textMessage,
      bytes: 'hello'.codeUnits,
    );
    final payload = codec.decodePortData(bytes);
    expect(payload, isNotNull);
    expect(payload!.port, OdpPort.textMessage);
    expect(String.fromCharCodes(payload.bytes), 'hello');
  });

  test('round-trips a port-tagged position DATA frame', () {
    final bytes = codec.encodePortData(
      sequence: 8,
      port: OdpPort.position,
      bytes: const [1, 2, 3, 4],
    );
    final payload = codec.decodePortData(bytes);
    expect(payload!.port, OdpPort.position);
    expect(payload.bytes, const [1, 2, 3, 4]);
  });

  test('unknown port code decodes as unknown', () {
    expect(OdpPort.fromCode(0x99), OdpPort.unknown);
    expect(OdpDataPayload.decode(const []), isNull);
  });

  test('feedIncoming emits port-tagged DATA frames when connected', () async {
    final connection = OdpConnection();
    connection.beginHandshake();
    connection.feedIncoming(codec.encodeHelloAck(sequence: 1, selectedVersion: 1));
    expect(connection.state, OdpState.connected);

    final payloadFuture = connection.dataFrames.first;
    final inbound = codec.encodePortData(
      sequence: 99,
      port: OdpPort.textMessage,
      bytes: 'pong'.codeUnits,
    );
    connection.feedIncoming(inbound);

    final received = await payloadFuture;
    expect(received.port, OdpPort.textMessage);
    connection.dispose();
  });

  test('reconnect runs a fresh handshake after error', () async {
    final connection = OdpConnection();
    connection.feedIncoming(const [0x00]); // decode failure → error
    expect(connection.state, OdpState.error);

    final ok = await connection.reconnect((outgoing) async {
      if (codec.decode(outgoing)?.type == OdpMessageType.hello) {
        return codec.encodeHelloAck(sequence: 1, selectedVersion: 1);
      }
      return codec.encode(
        OdpFrame(
          version: OdpCodec.protocolVersion,
          type: OdpMessageType.capabilityRsp,
          sequence: 1,
          payload: const [1],
        ),
      );
    });

    expect(ok, isTrue);
    expect(connection.state, OdpState.connected);
    connection.dispose();
  });
}
