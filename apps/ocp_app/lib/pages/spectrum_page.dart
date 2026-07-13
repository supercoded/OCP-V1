import 'package:flutter/material.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';

class SpectrumPage extends StatelessWidget {
  const SpectrumPage({super.key});

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.waves, size: 48, color: OcpColors.ocpAccent),
          SizedBox(height: 16),
          Text('Spectrum', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: OcpColors.ocpText)),
          SizedBox(height: 8),
          Text('RTL-SDR spectrum analyzer', style: TextStyle(color: OcpColors.ocpTextMuted, fontFamily: 'JetBrainsMono')),
        ],
      ),
    );
  }
}