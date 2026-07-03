import 'package:flutter/material.dart';
import 'package:ocp_app/app/ocp_app_coordinator.dart';

/// Dashboard workspace — workspace overview.
class DashboardWorkspace extends StatelessWidget {
  const DashboardWorkspace({required this.coordinator, super.key});

  final OcpAppCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: coordinator.core.workspaceService.list(),
      builder: (context, snapshot) {
        final workspaces = snapshot.data ?? [];
        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            Text('Workspaces', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            if (workspaces.isEmpty)
              const Text('No workspaces yet. Create one from Devices.'),
            ...workspaces.map(
              (ws) => ListTile(
                title: Text(ws.name),
                subtitle: Text('${ws.assignedDeviceIds.length} devices'),
              ),
            ),
          ],
        );
      },
    );
  }
}
