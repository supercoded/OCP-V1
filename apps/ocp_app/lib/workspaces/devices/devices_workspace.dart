import 'package:flutter/material.dart';
import 'package:ocp_app/app/ocp_app_coordinator.dart';
import 'package:ocp_core/ocp_core.dart';

/// Devices workspace — discovery, pairing, firmware info.
class DevicesWorkspace extends StatefulWidget {
  const DevicesWorkspace({required this.coordinator, super.key});

  final OcpAppCoordinator coordinator;

  @override
  State<DevicesWorkspace> createState() => _DevicesWorkspaceState();
}

class _DevicesWorkspaceState extends State<DevicesWorkspace> {
  Future<void> _addMockDevice() async {
    final now = DateTime.now().toUtc();
    await widget.coordinator.core.workspaceService.create(
      workspaceId: 'default',
      name: 'Default',
    );
    await widget.coordinator.core.devices.save(
      Device(
        deviceId: 'mock-${now.microsecondsSinceEpoch}',
        workspaceId: 'default',
        name: 'Mock Radio',
        transportType: 'mock',
        capabilities: const ['lora', 'ble'],
        firmwareVersion: '1.0.0',
        isPaired: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FilledButton(
            onPressed: _addMockDevice,
            child: const Text('Add mock device'),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: FutureBuilder(
              future: widget.coordinator.core.devices.findByWorkspace('default'),
              builder: (context, snapshot) {
                final devices = snapshot.data ?? [];
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      title: Text(device.name),
                      subtitle: Text(
                        '${device.transportType} · fw ${device.firmwareVersion}',
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
