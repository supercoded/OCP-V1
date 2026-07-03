import 'package:mock_device/mock_device.dart';
import 'package:ocp_odp/ocp_odp.dart';
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
}
