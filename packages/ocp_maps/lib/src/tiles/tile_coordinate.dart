import 'package:meta/meta.dart';

/// A slippy-map (XYZ) tile address.
@immutable
class TileCoordinate {
  const TileCoordinate({required this.z, required this.x, required this.y});

  /// Zoom level.
  final int z;

  /// Column.
  final int x;

  /// Row.
  final int y;

  /// Path of this tile relative to a tile-pack root, e.g. `12/655/1583.png`.
  String get relativePath => '$z/$x/$y.png';

  @override
  bool operator ==(Object other) =>
      other is TileCoordinate && other.z == z && other.x == x && other.y == y;

  @override
  int get hashCode => Object.hash(z, x, y);

  @override
  String toString() => 'TileCoordinate($z/$x/$y)';
}
