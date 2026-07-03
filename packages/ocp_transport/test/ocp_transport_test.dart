import 'package:ocp_transport/ocp_transport.dart';
import 'package:test/test.dart';

void main() {
  test('mock transport delivers to peer', () async {
    final app = MockTransport(name: 'app');
    final device = MockTransport(name: 'device');
    app.peer = device;
    device.peer = app;
    await app.connect();
    await device.connect();
    await app.send([1, 2, 3]);
    expect(device.sent, isEmpty);
    expect(app.sent, hasLength(1));
  });
}
