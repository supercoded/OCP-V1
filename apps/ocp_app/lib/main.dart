import 'package:flutter/material.dart';
import 'services/service_locator.dart';
import 'providers/settings_provider.dart';
import 'app.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize the platform service locator and storage before running the app.
  // On desktop this connects to the WebSocket bridge; on mobile it sets up
  // MethodChannel communication with native code. StorageService initializes
  // SharedPreferences for local persistence.
  await ServiceLocator.initialize();

  // Initialize SettingsProvider and load persisted settings.
  final settingsProvider = SettingsProvider(storage: ServiceLocator.storage);
  await settingsProvider.loadSettings();

  runApp(OcpApp(settingsProvider: settingsProvider));
}