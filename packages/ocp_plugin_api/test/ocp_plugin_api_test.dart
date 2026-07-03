import 'package:ocp_plugin_api/ocp_plugin_api.dart';
import 'package:test/test.dart';

class _TestPlugin implements OcpPlugin {
  @override
  final String id = 'test';
  @override
  final String name = 'Test Plugin';
  @override
  final String version = '0.0.1';
  @override
  final PluginCapability capability = const PluginCapability(
    id: 'demo',
    name: 'Demo',
    permissions: {PluginPermission.readMessages},
  );
  @override
  Future<void> onInstall() async {}
  @override
  Future<void> onUninstall() async {}
}

void main() {
  test('registry installs and uninstalls plugins', () async {
    final registry = PluginRegistry();
    await registry.install(_TestPlugin());
    expect(registry.findById('test'), isNotNull);
    await registry.uninstall('test');
    expect(registry.findById('test'), isNull);
  });
}
