import 'package:ocp_plugin_api/ocp_plugin_api.dart';
import 'package:ocp_plugin_example/ocp_plugin_example.dart';
import 'package:test/test.dart';

void main() {
  test('example plugin satisfies contract', () async {
    final plugin = ExamplePlugin();
    final registry = PluginRegistry();
    await registry.install(plugin);
    expect(registry.withCapability('example.device'), hasLength(1));
  });
}
