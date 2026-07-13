import 'package:flutter/material.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';

class NetworkPage extends StatelessWidget {
  const NetworkPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.hub, size: 48, color: OcpColors.ocpAccent),
          SizedBox(height: 16),
          Text('Network', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: OcpColors.ocpText)),
          SizedBox(height: 8),
          Text('Mesh network visualization', style: TextStyle(color: OcpColors.ocpTextMuted, fontFamily: 'JetBrainsMono')),
        ],
      ),
    );
  }
}