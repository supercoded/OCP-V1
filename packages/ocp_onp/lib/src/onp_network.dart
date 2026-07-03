import 'package:ocp_onp/src/onp_codec.dart';
import 'package:ocp_onp/src/onp_peer.dart';

/// Tracks peers, last-heard, and routing statistics.
class OnpNetwork {
  OnpNetwork({OnpCodec? codec}) : _codec = codec ?? OnpCodec();

  final OnpCodec _codec;
  final Map<String, OnpPeer> _peers = {};
  int _packetsRouted = 0;

  Map<String, OnpPeer> get peers => Map.unmodifiable(_peers);
  int get packetsRouted => _packetsRouted;

  void announcePeer(String peerId, {int linkQuality = 100}) {
    _peers[peerId] = OnpPeer(
      peerId: peerId,
      lastHeardAt: DateTime.now().toUtc(),
      linkQuality: linkQuality,
    );
  }

  List<int> buildPeerHeard(String peerId, int linkQuality) =>
      _codec.encodePeerHeard(peerId: peerId, linkQuality: linkQuality);

  void ingestPayload(List<int> payload) {
    if (payload.isEmpty) return;
    final type = payload[0];
    if (type == 0x02) {
      final peer = _codec.decodePeerHeard(payload);
      if (peer != null) {
        _peers[peer.peerId] = peer;
        _packetsRouted++;
      }
    }
  }

  List<OnpPeer> sortedByLastHeard() {
    final list = _peers.values.toList()
      ..sort((a, b) => b.lastHeardAt.compareTo(a.lastHeardAt));
    return list;
  }
}
