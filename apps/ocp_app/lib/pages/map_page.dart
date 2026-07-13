import 'package:flutter/material.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';

class MapPage extends StatelessWidget {
  const MapPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.map, size: 48, color: OcpColors.ocpAccent),
          SizedBox(height: 16),
          Text('Map', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: OcpColors.ocpText)),
          SizedBox(height: 8),
          Text('Offline map view', style: TextStyle(color: OcpColors.ocpTextMuted, fontFamily: 'JetBrainsMono')),
        ],
      ),
    );
  }
}