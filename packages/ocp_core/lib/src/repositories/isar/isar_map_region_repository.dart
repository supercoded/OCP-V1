import 'package:ocp_core/src/models/map_region.dart';
import 'package:ocp_core/src/repositories/map_region_repository.dart';
import 'package:ocp_storage/ocp_storage.dart';

/// Isar-backed [MapRegionRepository].
class IsarMapRegionRepository implements MapRegionRepository {
  IsarMapRegionRepository(OcpDatabase database) : _stores = OcpStores(database);

  final OcpStores _stores;

  @override
  Future<void> delete(String regionId) async {
    final existing = await _stores.mapRegionById(regionId);
    if (existing != null) {
      await _stores.deleteMapRegion(existing.id);
    }
  }

  @override
  Future<MapRegion?> findById(String regionId) async {
    final schema = await _stores.mapRegionById(regionId);
    return schema == null ? null : _toModel(schema);
  }

  @override
  Future<List<MapRegion>> findAll() async {
    final schemas = await _stores.allMapRegions();
    return schemas.map(_toModel).toList();
  }

  @override
  Future<void> save(MapRegion region) async {
    final existing = await _stores.mapRegionById(region.regionId);
    final schema = _toSchema(region);
    if (existing != null) {
      schema.id = existing.id;
    }
    await _stores.putMapRegion(schema);
  }

  MapRegion _toModel(MapRegionSchema schema) => MapRegion(
        regionId: schema.regionId,
        minLatitude: schema.minLat,
        minLongitude: schema.minLon,
        maxLatitude: schema.maxLat,
        maxLongitude: schema.maxLon,
        minZoom: schema.minZoom,
        maxZoom: schema.maxZoom,
        style: schema.style,
        sizeBytes: schema.sizeBytes,
        downloadedAt: schema.downloadedAt,
        storagePath: schema.storagePath,
      );

  MapRegionSchema _toSchema(MapRegion region) => MapRegionSchema()
    ..regionId = region.regionId
    ..minLat = region.minLatitude
    ..minLon = region.minLongitude
    ..maxLat = region.maxLatitude
    ..maxLon = region.maxLongitude
    ..minZoom = region.minZoom
    ..maxZoom = region.maxZoom
    ..style = region.style
    ..sizeBytes = region.sizeBytes
    ..downloadedAt = region.downloadedAt.toUtc()
    ..storagePath = region.storagePath;
}
