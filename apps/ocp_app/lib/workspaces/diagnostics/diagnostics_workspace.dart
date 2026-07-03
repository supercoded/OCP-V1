import 'package:flutter/material.dart';
import 'package:ocp_app/app/ocp_app_coordinator.dart';

/// Diagnostics workspace — session and plugin health.
class DiagnosticsWorkspace extends StatelessWidget {
  const DiagnosticsWorkspace({required this.coordinator, super.key});

  final OcpAppCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    final session = coordinator.core.sessionService;
    final plugins = coordinator.plugins.plugins.length;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Session: ${session.state.name}'),
          Text('Active device: ${session.activeDeviceId ?? 'none'}'),
          Text('Installed plugins: $plugins'),
          Text(
            'DB encrypted: ${coordinator.core.securityService.isDatabaseEncrypted}',
          ),
          Text('PIN enabled: ${coordinator.core.securityService.isPinEnabled}'),
        ],
      ),
    );
  }
}
