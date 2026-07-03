/// ONP route types per specs/onp-spec.md.
enum OnpRouteType {
  peerAnnounce(0x01),
  peerHeard(0x02),
  routeStats(0x03);

  const OnpRouteType(this.code);
  final int code;
}

/// Known peer on the mesh/network.
class OnpPeer {
  const OnpPeer({
    required this.peerId,
    required this.lastHeardAt,
    required this.linkQuality,
    this.hopCount = 0,
  });

  final String peerId;
  final DateTime lastHeardAt;
  final int linkQuality;
  final int hopCount;
}
