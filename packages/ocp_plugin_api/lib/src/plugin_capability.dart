import 'package:ocp_plugin_api/src/plugin_permission.dart';

/// Registered plugin capability.
class PluginCapability {
  const PluginCapability({
    required this.id,
    required this.name,
    required this.permissions,
  });

  final String id;
  final String name;
  final Set<PluginPermission> permissions;
}
