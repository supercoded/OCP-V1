import 'package:flutter/material.dart';
import 'package:ocp_app/app/ocp_app_coordinator.dart';
import 'package:ocp_app/app/ocp_app_shell.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final coordinator = await OcpAppCoordinator.create();
  runApp(OcpApp(coordinator: coordinator));
}
