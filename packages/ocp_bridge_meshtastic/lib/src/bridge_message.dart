import 'package:ocp_bridge_meshtastic/src/meshtastic_position.dart';

/// A decoded application message crossing the bridge in either direction.
sealed class BridgeMessage {
  const BridgeMessage();
}

/// A text message (Meshtastic `TEXT_MESSAGE_APP`).
class TextBridgeMessage extends BridgeMessage {
  const TextBridgeMessage(this.text);

  final String text;
}

/// A position report (Meshtastic `POSITION_APP`).
class PositionBridgeMessage extends BridgeMessage {
  const PositionBridgeMessage(this.position);

  final MeshtasticPosition position;
}
