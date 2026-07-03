import 'package:ocp_maps/ocp_maps.dart';
import 'package:test/test.dart';

void main() {
  group('TileMath', () {
    test('tile count doubles per zoom level', () {
      expect(TileMath.tileCount(0), 1);
      expect(TileMath.tileCount(1), 2);
      expect(TileMath.tileCount(12), 4096);
    });

    test('the equator/prime-meridian sits at the center tile', () {
      const origin = GeoPoint(latitude: 0, longitude: 0);
      expect(
        TileMath.tileForGeo(origin, 1),
        const TileCoordinate(z: 1, x: 1, y: 1),
      );
    });

    test('known San Francisco tile at zoom 12', () {
      const sf = GeoPoint(latitude: 37.7749, longitude: -122.4194);
      expect(
        TileMath.tileForGeo(sf, 12),
        const TileCoordinate(z: 12, x: 655, y: 1583),
      );
    });

    test('north-west corner round-trips back to the same tile', () {
      const sf = GeoPoint(latitude: 37.7749, longitude: -122.4194);
      final tile = TileMath.tileForGeo(sf, 14);
      final corner = TileMath.northWestCorner(tile);
      expect(TileMath.tileForGeo(corner, 14), tile);
    });

    test('resolves an on-disk tile path under a storage root', () {
      const tile = TileCoordinate(z: 12, x: 655, y: 1583);
      expect(
        TileMath.tilePath('/tiles/bay-area', tile),
        '/tiles/bay-area/12/655/1583.png',
      );
      expect(
        TileMath.tilePath('/tiles/bay-area/', tile),
        '/tiles/bay-area/12/655/1583.png',
      );
    });

    test('MapRegionCoverage respects bounds and zoom range', () {
      const coverage = MapRegionCoverage(
        minLatitude: 37.0,
        minLongitude: -123.0,
        maxLatitude: 38.0,
        maxLongitude: -122.0,
        minZoom: 8,
        maxZoom: 14,
      );
      const inside = GeoPoint(latitude: 37.5, longitude: -122.5);
      const outside = GeoPoint(latitude: 39.0, longitude: -122.5);
      expect(coverage.covers(inside, 12), isTrue);
      expect(coverage.covers(inside, 15), isFalse);
      expect(coverage.covers(outside, 12), isFalse);
    });
  });
}
