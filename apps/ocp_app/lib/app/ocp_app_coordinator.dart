import 'dart:io';

import 'package:mock_position_feed/mock_position_feed.dart';
import 'package:ocp_core/ocp_core.dart';
import 'package:ocp_maps/ocp_maps.dart';
import 'package:ocp_plugin_api/ocp_plugin_api.dart';
import 'package:ocp_plugin_example/ocp_plugin_example.dart';
import 'package:ocp_storage/ocp_storage.dart';
import 'package:path_provider/path_provider.dart';

/// Thin app-layer coordinator — wires UI to [OcpCore] services only.
class OcpAppCoordinator {
  OcpAppCoordinator._({
    required this.core,
    required this.plugins,
    required this.positionFeed,
    required this.selfPosition,
    required this.baseDirectory,
  });

  final OcpCore core;
  final PluginRegistry plugins;

  /// App storage root (used for the offline tile pack, among others).
  final Directory baseDirectory;

  /// MVP-only synthetic node feed driving the Maps workspace before real GPS
  /// hardware is wired in (see build-plan-v2 Phase 1).
  final MockPositionFeed positionFeed;

  /// Self position for the self-centered sonar view (base-camp for the demo).
  final GeoPoint selfPosition;

  static Future<OcpAppCoordinator> create() async {
    final dir = await getApplicationDocumentsDirectory();
    final database = await OcpDatabase.open(dir.path);
    final core = await OcpCore.create(database);
    final plugins = PluginRegistry();
    await plugins.install(ExamplePlugin());
    return OcpAppCoordinator._(
      core: core,
      plugins: plugins,
      positionFeed: MockPositionFeed.demo(),
      selfPosition: const GeoPoint(latitude: 37.7749, longitude: -122.4194),
      baseDirectory: dir,
    );
  }

  Future<void> dispose() => core.dispose();
}
