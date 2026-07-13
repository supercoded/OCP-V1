import 'package:flutter/material.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.settings, size: 48, color: OcpColors.ocpAccent),
          SizedBox(height: 16),
          Text('Settings', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: OcpColors.ocpText)),
          SizedBox(height: 8),
          Text('App configuration', style: TextStyle(color: OcpColors.ocpTextMuted, fontFamily: 'JetBrainsMono')),
        ],
      ),
    );
  }
}