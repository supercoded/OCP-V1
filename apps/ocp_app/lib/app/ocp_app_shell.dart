import 'package:flutter/material.dart';
import 'package:ocp_app/app/ocp_app_coordinator.dart';
import 'package:ocp_app/workspaces/dashboard/dashboard_workspace.dart';
import 'package:ocp_app/workspaces/devices/devices_workspace.dart';
import 'package:ocp_app/workspaces/diagnostics/diagnostics_workspace.dart';
import 'package:ocp_app/workspaces/maps/maps_workspace.dart';
import 'package:ocp_app/workspaces/messaging/messaging_workspace.dart';
import 'package:ocp_app/workspaces/network/network_workspace.dart';

/// Main navigation shell with workspace tabs.
class OcpAppShell extends StatefulWidget {
  const OcpAppShell({required this.coordinator, super.key});

  final OcpAppCoordinator coordinator;

  @override
  State<OcpAppShell> createState() => _OcpAppShellState();
}

class _OcpAppShellState extends State<OcpAppShell> {
  int _index = 0;

  @override
  Widget build(BuildContext context) {
    final pages = [
      DashboardWorkspace(coordinator: widget.coordinator),
      MessagingWorkspace(coordinator: widget.coordinator),
      NetworkWorkspace(coordinator: widget.coordinator),
      DevicesWorkspace(coordinator: widget.coordinator),
      MapsWorkspace(coordinator: widget.coordinator),
      DiagnosticsWorkspace(coordinator: widget.coordinator),
    ];

    return Scaffold(
      appBar: AppBar(title: const Text('OCP')),
      body: IndexedStack(index: _index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: (value) => setState(() => _index = value),
        destinations: const [
          NavigationDestination(icon: Icon(Icons.dashboard), label: 'Dashboard'),
          NavigationDestination(icon: Icon(Icons.message), label: 'Messaging'),
          NavigationDestination(icon: Icon(Icons.hub), label: 'Network'),
          NavigationDestination(icon: Icon(Icons.devices), label: 'Devices'),
          NavigationDestination(icon: Icon(Icons.radar), label: 'Maps'),
          NavigationDestination(
            icon: Icon(Icons.bug_report),
            label: 'Diagnostics',
          ),
        ],
      ),
    );
  }
}
