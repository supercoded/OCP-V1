import 'package:meta/meta.dart';
import 'package:ocp_maps/src/geo/geo_point.dart';
import 'package:ocp_maps/src/tiles/tile_coordinate.dart';

/// Source of raw tile bytes for the offline map view.
///
/// Kept as an interface so the source (files on disk, memory, test fixtures)
/// can be swapped without touching projection or coverage logic.
abstract interface class TileProvider {
  /// Returns the encoded tile bytes for [coordinate], or `null` if the tile is
  /// not cached.
  Future<List<int>?> readTile(TileCoordinate coordinate);
}

/// Bounds + zoom coverage of a cached tile pack (`MapRegion`).
@immutable
class MapRegionCoverage {
  const MapRegionCoverage({
    required this.minLatitude,
    required this.minLongitude,
    required this.maxLatitude,
    required this.maxLongitude,
    required this.minZoom,
    required this.maxZoom,
  });

  final double minLatitude;
  final double minLongitude;
  final double maxLatitude;
  final double maxLongitude;
  final int minZoom;
  final int maxZoom;

  /// Whether this pack has tiles for [point] at zoom [zoom].
  bool covers(GeoPoint point, int zoom) {
    if (zoom < minZoom || zoom > maxZoom) return false;
    return point.latitude >= minLatitude &&
        point.latitude <= maxLatitude &&
        point.longitude >= minLongitude &&
        point.longitude <= maxLongitude;
  }
}
