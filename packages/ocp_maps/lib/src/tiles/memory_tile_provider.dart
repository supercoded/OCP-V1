import 'package:ocp_maps/src/tiles/tile_coordinate.dart';
import 'package:ocp_maps/src/tiles/tile_provider.dart';

/// In-memory [TileProvider] backed by a map of tile bytes.
///
/// Useful for tests and for previewing the map view without touching disk.
class MemoryTileProvider implements TileProvider {
  MemoryTileProvider([Map<TileCoordinate, List<int>>? tiles])
      : _tiles = {...?tiles};

  final Map<TileCoordinate, List<int>> _tiles;

  void put(TileCoordinate coordinate, List<int> bytes) {
    _tiles[coordinate] = bytes;
  }

  int get tileCount => _tiles.length;

  @override
  Future<List<int>?> readTile(TileCoordinate coordinate) async =>
      _tiles[coordinate];
}
