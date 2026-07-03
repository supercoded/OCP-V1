import 'dart:io';

import 'package:ocp_maps/src/tiles/tile_coordinate.dart';
import 'package:ocp_maps/src/tiles/tile_math.dart';
import 'package:ocp_maps/src/tiles/tile_provider.dart';

/// Reads tile bytes from an on-disk tile pack laid out as `{root}/{z}/{x}/{y}.png`.
///
/// This is the offline-first read path (DG-001): tiles are served straight from
/// a pre-fetched pack with zero runtime network dependency.
class FileTileProvider implements TileProvider {
  const FileTileProvider(this.storagePath);

  /// Root directory of the tile pack (a `MapRegion.storagePath`).
  final String storagePath;

  @override
  Future<List<int>?> readTile(TileCoordinate coordinate) async {
    final file = File(TileMath.tilePath(storagePath, coordinate));
    if (!await file.exists()) return null;
    return file.readAsBytes();
  }
}
