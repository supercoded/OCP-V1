import 'package:ocp_onp/ocp_onp.dart';
import 'package:test/test.dart';

void main() {
  test('tracks peer last heard', () {
    final network = OnpNetwork();
    final payload = network.buildPeerHeard('node-a', 85);
    network.ingestPayload(payload);
    expect(network.peers['node-a']?.linkQuality, 85);
    expect(network.packetsRouted, 1);
  });
}
