import 'package:ocp_bridge_meshtastic/ocp_bridge_meshtastic.dart';
import 'package:test/test.dart';

void main() {
  test('round trips meshtastic payload through ODP', () {
    final bridge = MeshtasticBridge();
    final original = [0xDE, 0xAD, 0xBE, 0xEF];
    final odp = bridge.toOdp(original);
    expect(bridge.fromOdp(odp), original);
  });

  test('translates a text message to and from an ODP frame', () {
    final bridge = MeshtasticBridge();
    final frame = bridge.encodeToOdp(const TextBridgeMessage('hi mesh'));
    final decoded = bridge.decodeFromOdp(frame);
    expect(decoded, isA<TextBridgeMessage>());
    expect((decoded! as TextBridgeMessage).text, 'hi mesh');
  });

  test('translates a position to and from an ODP frame', () {
    final bridge = MeshtasticBridge();
    final original = MeshtasticPosition(
      latitude: 37.7749,
      longitude: -122.4194,
      altitudeMeters: 52,
      time: DateTime.utc(2026, 1, 1, 12),
    );
    final frame = bridge.encodeToOdp(PositionBridgeMessage(original));
    final decoded = bridge.decodeFromOdp(frame);
    expect(decoded, isA<PositionBridgeMessage>());
    final position = (decoded! as PositionBridgeMessage).position;
    expect(position.latitude, closeTo(37.7749, 1e-7));
    expect(position.longitude, closeTo(-122.4194, 1e-7));
    expect(position.altitudeMeters, 52);
    expect(position.time, DateTime.utc(2026, 1, 1, 12));
  });

  test('maps Meshtastic portnums to bridge messages', () {
    final bridge = MeshtasticBridge();
    final text = bridge.meshtasticToBridge(
      MeshtasticPortnum.textMessage.code,
      'ping'.codeUnits,
    );
    expect((text! as TextBridgeMessage).text, 'ping');

    final positionPayload = MeshtasticBridge.encodePositionPayload(
      const MeshtasticPosition(latitude: 1.5, longitude: -2.5),
    );
    final position = bridge.meshtasticToBridge(
      MeshtasticPortnum.position.code,
      positionPayload,
    );
    expect((position! as PositionBridgeMessage).position.latitude,
        closeTo(1.5, 1e-7));

    // Unmapped portnum (e.g. telemetry) is ignored for now.
    expect(bridge.meshtasticToBridge(67, const [0, 1, 2]), isNull);
  });

  test('rejects malformed position payloads', () {
    expect(MeshtasticBridge.decodePositionPayload(const [1, 2, 3]), isNull);
  });

  test('round-trips optional nodeId tail on position payloads', () {
    const position = MeshtasticPosition(latitude: 1, longitude: 2);
    final bytes = MeshtasticBridge.encodePositionPayload(
      position,
      nodeId: 'hiker',
    );
    expect(MeshtasticBridge.decodePositionNodeId(bytes), 'hiker');
    expect(
      MeshtasticBridge.decodePositionPayload(bytes)!.latitude,
      closeTo(1, 1e-7),
    );
  });
}
