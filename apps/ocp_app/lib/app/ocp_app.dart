import 'package:flutter/material.dart';
import 'package:ocp_app/app/ocp_app_coordinator.dart';
import 'package:ocp_app/app/ocp_app_shell.dart';

/// Root widget for the OCP application.
class OcpApp extends StatelessWidget {
  const OcpApp({required this.coordinator, super.key});

  final OcpAppCoordinator coordinator;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'OCP',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.teal),
        useMaterial3: true,
      ),
      home: OcpAppShell(coordinator: coordinator),
    );
  }
}
