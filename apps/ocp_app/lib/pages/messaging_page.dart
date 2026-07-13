import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';
import '../providers/connection_provider.dart';
import '../widgets/status_lamp.dart';

class MessagingPage extends StatelessWidget {
  const MessagingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionProvider>();

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.message, size: 48, color: OcpColors.ocpAccent),
          const SizedBox(height: 16),
          const Text(
            'Messaging',
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: OcpColors.ocpText,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              StatusLamp(connected: conn.connected),
              const SizedBox(width: 8),
              Text(
                conn.connected ? 'Connected (${conn.transportKind})' : 'Offline',
                style: TextStyle(
                  color: conn.connected ? OcpColors.ocpAccent : OcpColors.ocpRed,
                  fontFamily: 'JetBrainsMono',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}