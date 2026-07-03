import 'package:flutter/material.dart';
import 'package:ocp_app/app/ocp_app_coordinator.dart';
import 'package:ocp_core/ocp_core.dart';
import 'package:ocp_transport/ocp_transport.dart';

/// Devices workspace — scan, auto-detect Meshtastic boards, and one-tap pair.
class DevicesWorkspace extends StatefulWidget {
  const DevicesWorkspace({required this.coordinator, super.key});

  final OcpAppCoordinator coordinator;

  @override
  State<DevicesWorkspace> createState() => _DevicesWorkspaceState();
}

class _DevicesWorkspaceState extends State<DevicesWorkspace> {
  static const _workspaceId = OcpAppCoordinator.defaultWorkspaceId;

  List<BleDiscoveredDevice> _discovered = const [];
  final Set<String> _pairingIds = {};
  bool _scanning = false;
  int _listVersion = 0;

  Future<void> _scan() async {
    setState(() => _scanning = true);
    await widget.coordinator.core.workspaceService.create(
      workspaceId: _workspaceId,
      name: 'Default',
    );
    final found = await widget.coordinator.scanForMeshtastic();
    if (!mounted) return;
    setState(() {
      _discovered = found;
      _scanning = false;
    });
  }

  Future<void> _pair(BleDiscoveredDevice device) async {
    setState(() => _pairingIds.add(device.id));
    final result = await widget.coordinator.pairDiscovered(device);
    if (!mounted) return;

    final message = result.success
        ? 'Paired and connected to ${device.name}'
        : 'Pairing failed: ${result.reason ?? 'unknown error'}';

    setState(() {
      _pairingIds.remove(device.id);
      _listVersion++;
    });
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final session = widget.coordinator.core.sessionService;
    final bleMode = widget.coordinator.useBleHardware;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Session: ${session.state.name} · '
            '${session.activeDeviceId ?? 'none'}'
            '${bleMode ? ' · BLE hardware' : ' · mock demo'}',
            style: Theme.of(context).textTheme.labelMedium,
          ),
          const SizedBox(height: 8),
          FilledButton.icon(
            onPressed: _scanning ? null : _scan,
            icon: _scanning
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.bluetooth_searching),
            label: Text(_scanning ? 'Scanning…' : 'Scan for Meshtastic devices'),
          ),
          const SizedBox(height: 8),
          if (_discovered.isNotEmpty) ...[
            Text(
              'Discovered',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            for (final device in _discovered)
              ListTile(
                leading: const Icon(Icons.sensors),
                title: Text(device.name),
                subtitle: Text('${device.id} · ${device.rssi ?? '?'} dBm'),
                trailing: _pairingIds.contains(device.id)
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : TextButton(
                        onPressed: () => _pair(device),
                        child: const Text('Pair'),
                      ),
              ),
            const Divider(),
          ],
          Text('Paired', style: Theme.of(context).textTheme.labelLarge),
          Expanded(
            child: FutureBuilder<List<Device>>(
              key: ValueKey(_listVersion),
              future: widget.coordinator.core.devices.findByWorkspace(_workspaceId),
              builder: (context, snapshot) {
                final devices = snapshot.data ?? const [];
                if (devices.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text(
                      'No paired devices yet. Pair a board to open an ODP '
                      'session for messaging and live positions.',
                    ),
                  );
                }
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    final isActive = session.activeDeviceId == device.deviceId &&
                        session.state == SessionState.connected;
                    return ListTile(
                      leading: Icon(
                        isActive ? Icons.link : Icons.router,
                        color: isActive
                            ? Theme.of(context).colorScheme.primary
                            : null,
                      ),
                      title: Text(device.name),
                      subtitle: Text(
                        '${device.transportType} · '
                        '${device.firmwareVersion ?? 'unknown fw'}'
                        '${isActive ? ' · connected' : ''}',
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
