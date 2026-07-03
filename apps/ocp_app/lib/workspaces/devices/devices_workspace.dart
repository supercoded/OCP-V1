import 'package:flutter/material.dart';
import 'package:mock_device/mock_device.dart';
import 'package:ocp_app/app/ocp_app_coordinator.dart';
import 'package:ocp_app/pairing/device_pairing_controller.dart';
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
  static const _workspaceId = 'default';

  late final DevicePairingController _pairing;
  List<BleDiscoveredDevice> _discovered = const [];
  final Set<String> _pairingIds = {};
  bool _scanning = false;

  @override
  void initState() {
    super.initState();
    _pairing = DevicePairingController(
      scanner: MockBleScanner(),
      devices: widget.coordinator.core.devices,
      workspaceId: _workspaceId,
      scanTimeout: const Duration(milliseconds: 400),
    );
  }

  Future<void> _scan() async {
    setState(() => _scanning = true);
    await widget.coordinator.core.workspaceService.create(
      workspaceId: _workspaceId,
      name: 'Default',
    );
    final found = await _pairing.scanForMeshtastic();
    if (!mounted) return;
    setState(() {
      _discovered = found;
      _scanning = false;
    });
  }

  Future<void> _pair(BleDiscoveredDevice device) async {
    setState(() => _pairingIds.add(device.id));
    // MVP: run the ODP handshake against an in-process mock device. The real
    // build swaps this exchange for BLE characteristic writes/notifications.
    final mock = MockOdpDevice();
    final result = await _pairing.pair(
      device,
      exchange: (outgoing) async => mock.handle(outgoing) ?? const <int>[],
    );
    if (!mounted) return;
    setState(() => _pairingIds.remove(device.id));
    final messenger = ScaffoldMessenger.of(context);
    messenger.showSnackBar(
      SnackBar(
        content: Text(
          result.success
              ? 'Paired ${device.name}'
              : 'Pairing failed: ${result.reason}',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
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
              future: widget.coordinator.core.devices.findByWorkspace(_workspaceId),
              builder: (context, snapshot) {
                final devices = snapshot.data ?? const [];
                if (devices.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.only(top: 12),
                    child: Text('No paired devices yet.'),
                  );
                }
                return ListView.builder(
                  itemCount: devices.length,
                  itemBuilder: (context, index) {
                    final device = devices[index];
                    return ListTile(
                      leading: const Icon(Icons.router),
                      title: Text(device.name),
                      subtitle: Text(
                        '${device.transportType} · '
                        '${device.firmwareVersion ?? 'unknown fw'}',
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
