import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';
import '../providers/network_provider.dart';
import '../providers/connection_provider.dart';
import '../providers/sonar_provider.dart';
import '../models/blip.dart';
import '../widgets/status_lamp.dart';

class NetworkPage extends StatelessWidget {
  const NetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkProvider>();
    final conn = context.watch<ConnectionProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'NETWORK',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: OcpColors.ocpAccent,
                ),
              ),
              Row(
                children: [
                  StatusLamp(connected: conn.connected),
                  const SizedBox(width: 8),
                  Text(
                    conn.connected
                        ? 'Connected · ${conn.transportKind ?? "unknown"}'
                        : 'Disconnected',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'JetBrainsMono',
                      color: conn.connected ? OcpColors.ocpAccent : OcpColors.ocpRed,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${network.nodeCount} nodes',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'JetBrainsMono',
                      color: OcpColors.ocpTextMuted,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Node table
          Expanded(
            child: _buildNodeTable(context, network),
          ),
        ],
      ),
    );
  }

  Widget _buildNodeTable(BuildContext context, NetworkProvider network) {
    if (network.nodes.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.hub, size: 48, color: OcpColors.ocpTextMuted),
            const SizedBox(height: 16),
            Text(
              network.connected ? 'Waiting for mesh nodes...' : 'Connect a Meshtastic device to view nodes',
              style: const TextStyle(
                fontSize: 13,
                color: OcpColors.ocpTextMuted,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: OcpColors.ocpPanel,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: OcpColors.ocpBorder),
      ),
      child: Column(
        children: [
          // Header row
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: const BoxDecoration(
              color: OcpColors.ocpPanel2,
              border: Border(bottom: BorderSide(color: OcpColors.ocpBorder)),
              borderRadius: BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(4),
              ),
            ),
            child: const Row(
              children: [
                SizedBox(
                  width: 160,
                  child: Text('NODE ID', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: OcpColors.ocpTextMuted)),
                ),
                SizedBox(
                  width: 80,
                  child: Text('SHORT', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: OcpColors.ocpTextMuted)),
                ),
                Expanded(
                  child: Text('LONG NAME', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: OcpColors.ocpTextMuted)),
                ),
                SizedBox(
                  width: 80,
                  child: Text('ROLE', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: OcpColors.ocpTextMuted)),
                ),
                SizedBox(
                  width: 70,
                  child: Text('SNR', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: OcpColors.ocpTextMuted, textAlign: TextAlign.right)),
                ),
                SizedBox(
                  width: 90,
                  child: Text('LAST HEARD', style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: OcpColors.ocpTextMuted, textAlign: TextAlign.right)),
                ),
              ],
            ),
          ),
          // Data rows
          Expanded(
            child: ListView.builder(
              itemCount: network.nodes.length,
              itemBuilder: (context, index) {
                final node = network.nodes[index];
                final isSelected = network.selectedNodeId == node.id;

                return GestureDetector(
                  onTap: () => _selectNode(context, network, node),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    decoration: BoxDecoration(
                      color: isSelected ? OcpColors.ocpAccent.withAlpha(26) : Colors.transparent,
                      border: Border(
                        bottom: BorderSide(color: OcpColors.ocpBorder.withAlpha(128)),
                      ),
                    ),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 160,
                          child: Text(
                            node.id,
                            style: const TextStyle(
                              fontSize: 12,
                              fontFamily: 'JetBrainsMono',
                              color: OcpColors.ocpCyan,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Text(
                            node.shortName,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'JetBrainsMono',
                              color: node.shortName.isNotEmpty ? OcpColors.ocpText : OcpColors.ocpTextMuted,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            node.longName,
                            style: TextStyle(
                              fontSize: 12,
                              color: node.longName.isNotEmpty ? OcpColors.ocpText : OcpColors.ocpTextMuted,
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 80,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(
                              color: _roleColor(node.role).withAlpha(26),
                              borderRadius: BorderRadius.circular(3),
                              border: Border.all(color: _roleColor(node.role).withAlpha(77)),
                            ),
                            child: Text(
                              node.role.toUpperCase(),
                              style: TextStyle(
                                fontSize: 9,
                                fontFamily: 'JetBrainsMono',
                                fontWeight: FontWeight.w600,
                                color: _roleColor(node.role),
                              ),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 70,
                          child: Text(
                            node.snr.toStringAsFixed(1),
                            textAlign: TextAlign.right,
                            style: TextStyle(
                              fontSize: 12,
                              fontFamily: 'JetBrainsMono',
                              color: node.snr > 5 ? OcpColors.ocpAccent : (node.snr > 0 ? OcpColors.ocpAmber : OcpColors.ocpRed),
                            ),
                          ),
                        ),
                        SizedBox(
                          width: 90,
                          child: Text(
                            node.timeSinceLastHeard,
                            textAlign: TextAlign.right,
                            style: const TextStyle(
                              fontSize: 11,
                              fontFamily: 'JetBrainsMono',
                              color: OcpColors.ocpTextMuted,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color _roleColor(String role) {
    switch (role.toLowerCase()) {
      case 'router':
        return OcpColors.ocpAmber;
      case 'repeater':
        return OcpColors.ocpCyan;
      case 'client':
        return OcpColors.ocpAccent;
      default:
        return OcpColors.ocpTextMuted;
    }
  }

  void _selectNode(BuildContext context, NetworkProvider network, MeshNode node) {
    network.selectNode(network.selectedNodeId == node.id ? null : node.id);

    // If node has position, also highlight a blip on the sonar
    if (node.hasPosition && node.lat != null && node.lon != null) {
      final sonar = context.read<SonarProvider>();
      sonar.addBlip(Blip(
        id: node.id,
        label: node.shortName.isNotEmpty ? node.shortName : node.longName,
        bearing: 0,
        range: 0.5,
        timestamp: DateTime.now(),
        isHighlighted: true,
      ));
    }
  }
}