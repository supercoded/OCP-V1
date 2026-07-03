import 'package:mock_device/mock_device.dart';
import 'package:ocp_odp/ocp_odp.dart';
import 'package:ocp_transport/ocp_transport.dart';
import 'package:test/test.dart';

void main() {
  test('mock device responds to hello', () {
    final codec = OdpCodec();
    final mock = MockOdpDevice(codec: codec);
    final hello = codec.encodeHello(sequence: 1);
    final ack = mock.handle(hello);
    expect(ack, isNotNull);
    final frame = codec.decode(ack!);
    expect(frame?.type, OdpMessageType.helloAck);
  });

  test('mock device echoes TEXT DATA with an echo prefix', () {
    final codec = OdpCodec();
    final mock = MockOdpDevice(codec: codec);
    final frame = codec.encodePortData(
      sequence: 1,
      port: OdpPort.textMessage,
      bytes: 'hello'.codeUnits,
    );
    final response = mock.handle(frame);
    expect(response, isNotNull);
    final payload = codec.decodePortData(response!);
    expect(payload!.port, OdpPort.textMessage);
    expect(String.fromCharCodes(payload.bytes), 'echo: hello');
    expect(mock.lastReceivedText, 'hello');
  });

  test('mock device loop delivers echo over transport peers', () async {
    final app = MockTransport(name: 'app');
    final device = MockTransport(name: 'device');
    app.peer = device;
    device.peer = app;

    final mock = MockOdpDevice();
    final loop = MockOdpDeviceLoop(device: mock, transport: device);
    loop.start();
    await app.connect();
    await device.connect();

    final responseFuture = app.incoming.first;
    await app.send(
      OdpCodec().encodePortData(
        sequence: 1,
        port: OdpPort.textMessage,
        bytes: 'from-app'.codeUnits,
      ),
    );

    final response = await responseFuture;
    final payload = OdpCodec().decodePortData(response);
    expect(String.fromCharCodes(payload!.bytes), 'echo: from-app');

    await loop.stop();
    app.dispose();
    device.dispose();
  });
}
