import 'package:flutter/material.dart';
import 'package:ocp_app/app/ocp_app_coordinator.dart';

/// Network workspace — transport and routing visibility.
class NetworkWorkspace extends StatelessWidget {
  const NetworkWorkspace({required this.coordinator, super.key});

  final OcpAppCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Network', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
          SizedBox(height: 8),
          Text('Transports: BLE, USB Serial, Mock (simulator)'),
          Text('ONP peer stats available when connected.'),
        ],
      ),
    );
  }
}
