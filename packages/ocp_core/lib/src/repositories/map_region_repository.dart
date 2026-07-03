import 'package:ocp_core/src/models/map_region.dart';

/// Tile-pack metadata storage contract.
abstract class MapRegionRepository {
  Future<void> save(MapRegion region);
  Future<MapRegion?> findById(String regionId);
  Future<List<MapRegion>> findAll();
  Future<void> delete(String regionId);
}
