import 'package:ocp_bridge_meshtastic/ocp_bridge_meshtastic.dart';
import 'package:test/test.dart';

void main() {
  test('round trips meshtastic payload through ODP', () {
    final bridge = MeshtasticBridge();
    final original = [0xDE, 0xAD, 0xBE, 0xEF];
    final odp = bridge.toOdp(original);
    expect(bridge.fromOdp(odp), original);
  });
}
