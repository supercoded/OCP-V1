import 'package:meta/meta.dart';
import 'package:ocp_maps/src/geo/geo_point.dart';
import 'package:ocp_maps/src/tiles/tile_coordinate.dart';
import 'package:ocp_maps/src/tiles/tile_math.dart';

/// A tile placed at a pixel offset inside a rendered grid.
@immutable
class PlacedTile {
  const PlacedTile({
    required this.coordinate,
    required this.left,
    required this.top,
  });

  final TileCoordinate coordinate;
  final double left;
  final double top;
}

/// A laid-out grid of tiles that fills a rendered viewport.
@immutable
class TileGridPlan {
  const TileGridPlan({
    required this.tiles,
    required this.width,
    required this.height,
    required this.tileSize,
  });

  final List<PlacedTile> tiles;
  final double width;
  final double height;
  final double tileSize;
}

/// Plans the set of tiles (and pixel offsets) needed to render a self-centered
/// offline map view. Pure math — no I/O, no widgets.
abstract final class TileGridPlanner {
  /// Builds a `(2*radius+1)`-square grid of [tileSize] tiles centered on the
  /// tile containing [center] at [zoom]. Off-map tiles (beyond `2^z`) are
  /// skipped, keeping their pixel slot empty.
  static TileGridPlan around(
    GeoPoint center,
    int zoom, {
    int radius = 1,
    double tileSize = 256,
  }) {
    final centerTile = TileMath.tileForGeo(center, zoom);
    final n = TileMath.tileCount(zoom);
    final tiles = <PlacedTile>[];
    for (var dy = -radius; dy <= radius; dy++) {
      for (var dx = -radius; dx <= radius; dx++) {
        final x = centerTile.x + dx;
        final y = centerTile.y + dy;
        if (x < 0 || y < 0 || x >= n || y >= n) continue;
        tiles.add(
          PlacedTile(
            coordinate: TileCoordinate(z: zoom, x: x, y: y),
            left: (dx + radius) * tileSize,
            top: (dy + radius) * tileSize,
          ),
        );
      }
    }
    final span = (2 * radius + 1) * tileSize;
    return TileGridPlan(
      tiles: tiles,
      width: span,
      height: span,
      tileSize: tileSize,
    );
  }
}
