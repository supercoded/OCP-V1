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

  test('mock BLE scanner emits the scripted devices', () async {
    final scanner = MockBleScanner();
    final found = await scanner.scan().toList();
    expect(found, hasLength(3));
    expect(found.map((d) => d.name), contains('Meshtastic_RAK4631'));
  });

  test('auto-detects Meshtastic boards by advertised service UUID', () async {
    final scanner = MockBleScanner();
    final found = await scanner.scan().toList();
    final meshtastic = found.where(MeshtasticBle.isMeshtastic).toList();
    expect(meshtastic, hasLength(2));
    expect(
      meshtastic.map((d) => d.name),
      containsAll(['Meshtastic_RAK4631', 'Meshtastic_LilyGo_TBeam']),
    );
  });
}
