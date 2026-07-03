import 'dart:io';

import 'package:ocp_maps/ocp_maps.dart';
import 'package:test/test.dart';

void main() {
  group('FileTileProvider', () {
    late Directory root;

    setUp(() async {
      root = await Directory.systemTemp.createTemp('ocp_tiles_');
    });

    tearDown(() async {
      if (await root.exists()) await root.delete(recursive: true);
    });

    test('reads tile bytes from an on-disk pack', () async {
      const tile = TileCoordinate(z: 12, x: 655, y: 1583);
      final file = File(TileMath.tilePath(root.path, tile));
      await file.parent.create(recursive: true);
      await file.writeAsBytes(const [1, 2, 3, 4]);

      final provider = FileTileProvider(root.path);
      expect(await provider.readTile(tile), const [1, 2, 3, 4]);
    });

    test('returns null for a tile not present in the pack', () async {
      final provider = FileTileProvider(root.path);
      expect(
        await provider.readTile(const TileCoordinate(z: 12, x: 1, y: 1)),
        isNull,
      );
    });
  });

  group('TileGridPlanner', () {
    test('centers a 3x3 grid on the tile containing the point', () {
      const center = GeoPoint(latitude: 37.7749, longitude: -122.4194);
      final plan = TileGridPlanner.around(center, 12);
      expect(plan.tiles, hasLength(9));
      expect(plan.width, 768);
      expect(plan.height, 768);

      final centerTile = TileMath.tileForGeo(center, 12);
      final middle = plan.tiles.firstWhere(
        (t) => t.left == 256 && t.top == 256,
      );
      expect(middle.coordinate, centerTile);
    });

    test('skips tiles beyond the world bounds at low zoom', () {
      // Zoom 0 has a single tile; a 3x3 grid keeps only the one valid tile.
      const center = GeoPoint(latitude: 0, longitude: 0);
      final plan = TileGridPlanner.around(center, 0);
      expect(plan.tiles, hasLength(1));
      expect(plan.tiles.single.coordinate, const TileCoordinate(z: 0, x: 0, y: 0));
    });
  });
}
