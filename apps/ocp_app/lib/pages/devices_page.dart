import 'package:flutter/material.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';

class DevicesPage extends StatelessWidget {
  const DevicesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.devices, size: 48, color: OcpColors.ocpAccent),
          SizedBox(height: 16),
          Text('Devices', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: OcpColors.ocpText)),
          SizedBox(height: 8),
          Text('Device management', style: TextStyle(color: OcpColors.ocpTextMuted, fontFamily: 'JetBrainsMono')),
        ],
      ),
    );
  }
}