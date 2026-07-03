import 'package:ocp_plugin_api/ocp_plugin_api.dart';

/// Throwaway example plugin for SDK validation.
class ExamplePlugin implements OcpPlugin {
  @override
  String get id => 'ocp.example';

  @override
  String get name => 'Example Plugin';

  @override
  String get version => '0.1.0';

  @override
  PluginCapability get capability => const PluginCapability(
        id: 'example.device',
        name: 'Example Device Adapter',
        permissions: {
          PluginPermission.accessDevices,
          PluginPermission.readMessages,
        },
      );

  @override
  Future<void> onInstall() async {}

  @override
  Future<void> onUninstall() async {}
}
