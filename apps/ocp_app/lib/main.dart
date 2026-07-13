import 'package:flutter/material.dart';
import 'services/service_locator.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the platform service locator before running the app.
  // On desktop this connects to the WebSocket bridge; on mobile it sets up
  // MethodChannel communication with native code.
  await ServiceLocator.initialize();

  runApp(const OcpApp());
}