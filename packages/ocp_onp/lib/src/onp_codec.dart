import 'package:ocp_onp/src/onp_peer.dart';

/// Encodes/decodes ONP payloads inside ODP DATA frames.
class OnpCodec {
  List<int> encodePeerHeard({
    required String peerId,
    required int linkQuality,
    int hopCount = 0,
  }) {
    final idBytes = peerId.codeUnits.take(16).toList();
    while (idBytes.length < 16) {
      idBytes.add(0);
    }
    return [
      0x02,
      hopCount,
      ...idBytes,
      linkQuality.clamp(0, 100),
    ];
  }

  OnpPeer? decodePeerHeard(List<int> payload) {
    if (payload.length < 19) return null;
    final hopCount = payload[1];
    final idBytes = payload.sublist(2, 18);
    final peerId = String.fromCharCodes(idBytes.where((b) => b != 0));
    final linkQuality = payload[18];
    return OnpPeer(
      peerId: peerId,
      lastHeardAt: DateTime.now().toUtc(),
      linkQuality: linkQuality,
      hopCount: hopCount,
    );
  }
}
