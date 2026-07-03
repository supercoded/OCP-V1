import 'dart:math' as math;

import 'package:ocp_maps/src/geo/geo_point.dart';
import 'package:ocp_maps/src/tiles/tile_coordinate.dart';

/// Slippy-map (XYZ) tile addressing math.
///
/// See `specs/maps-spec.md` §3.1. Pure math — no I/O.
abstract final class TileMath {
  /// Number of tiles per axis at zoom [z] (`2^z`).
  static int tileCount(int z) => 1 << z;

  static double _degToRad(double degrees) => degrees * math.pi / 180.0;

  /// The tile that contains [point] at zoom [z].
  static TileCoordinate tileForGeo(GeoPoint point, int z) {
    final n = tileCount(z);
    final latRad = _degToRad(point.latitude);

    var x = ((point.longitude + 180.0) / 360.0 * n).floor();
    var y =
        ((1 - _asinh(math.tan(latRad)) / math.pi) / 2 * n).floor();

    x = x.clamp(0, n - 1);
    y = y.clamp(0, n - 1);
    return TileCoordinate(z: z, x: x, y: y);
  }

  /// The north-west (top-left) corner of [tile].
  static GeoPoint northWestCorner(TileCoordinate tile) {
    final n = tileCount(tile.z);
    final lon = tile.x / n * 360.0 - 180.0;
    final latRad = math.atan(_sinh(math.pi * (1 - 2 * tile.y / n)));
    final lat = latRad * 180.0 / math.pi;
    return GeoPoint(latitude: lat, longitude: lon);
  }

  /// Resolves the on-disk path for [tile] under a tile-pack [storagePath].
  static String tilePath(String storagePath, TileCoordinate tile) {
    final root = storagePath.endsWith('/')
        ? storagePath.substring(0, storagePath.length - 1)
        : storagePath;
    return '$root/${tile.relativePath}';
  }

  static double _asinh(double x) => math.log(x + math.sqrt(x * x + 1));

  static double _sinh(double x) => (math.exp(x) - math.exp(-x)) / 2;
}
