import 'package:ocp_plugin_api/src/plugin_capability.dart';

/// Base plugin contract.
abstract class OcpPlugin {
  String get id;
  String get name;
  String get version;

  PluginCapability get capability;

  Future<void> onInstall();
  Future<void> onUninstall();
}
