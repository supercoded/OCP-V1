import 'package:ocp_core/ocp_core.dart';
import 'package:ocp_plugin_api/ocp_plugin_api.dart';
import 'package:ocp_plugin_example/ocp_plugin_example.dart';
import 'package:ocp_storage/ocp_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Thin app-layer coordinator — wires UI to [OcpCore] services only.
class OcpAppCoordinator {
  OcpAppCoordinator._({
    required this.core,
    required this.plugins,
  });

  final OcpCore core;
  final PluginRegistry plugins;

  static Future<OcpAppCoordinator> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final database = await OcpDatabase.open(dir.path);
    final core = await OcpCore.create(database);
    final plugins = PluginRegistry();
    await plugins.install(ExamplePlugin());
    return OcpAppCoordinator._(core: core, plugins: plugins);
  }

  Future<void> dispose() => core.dispose();
}
