import 'package:ocp_plugin_api/src/ocp_plugin.dart';

/// Installs, uninstalls, and looks up plugins by capability.
class PluginRegistry {
  final Map<String, OcpPlugin> _plugins = {};

  Iterable<OcpPlugin> get plugins => _plugins.values;

  Future<void> install(OcpPlugin plugin) async {
    await plugin.onInstall();
    _plugins[plugin.id] = plugin;
  }

  Future<void> uninstall(String pluginId) async {
    final plugin = _plugins.remove(pluginId);
    await plugin?.onUninstall();
  }

  OcpPlugin? findById(String id) => _plugins[id];

  List<OcpPlugin> withCapability(String capabilityId) => _plugins.values
      .where((plugin) => plugin.capability.id == capabilityId)
      .toList();
}
