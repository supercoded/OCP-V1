import 'package:logging/logging.dart';
import 'package:ocp_core/src/logging/ocp_logger.dart';
import 'package:ocp_core/src/models/map_region.dart';
import 'package:ocp_core/src/repositories/map_region_repository.dart';

/// Manages the set of cached offline tile packs (build-plan-v2 Phase 2).
///
/// Tracks registered [MapRegion] packs, resolves which pack covers a
/// coordinate, and enforces a storage budget by evicting the oldest packs.
class MapCacheService {
  MapCacheService(this._regions, {Logger? logger})
      : _logger = logger ?? ocpLogger('map-cache');

  final MapRegionRepository _regions;
  final Logger _logger;

  /// Registers (or updates) a downloaded tile pack.
  Future<void> register(MapRegion region) => _regions.save(region);

  /// All registered packs.
  Future<List<MapRegion>> regions() => _regions.findAll();

  /// Total on-disk size of all packs, in bytes.
  Future<int> totalSizeBytes() async {
    final all = await _regions.findAll();
    return all.fold<int>(0, (sum, region) => sum + region.sizeBytes);
  }

  /// The pack covering (`latitude`, `longitude`) at [zoom], if any. Prefers the
  /// smallest covering pack (most specific).
  Future<MapRegion?> coveringRegion({
    required double latitude,
    required double longitude,
    required int zoom,
  }) async {
    final all = await _regions.findAll();
    MapRegion? best;
    for (final region in all) {
      if (!region.covers(latitude, longitude, zoom)) continue;
      if (best == null || region.sizeBytes < best.sizeBytes) {
        best = region;
      }
    }
    return best;
  }

  /// Evicts the oldest packs until the total size is within [maxBytes].
  ///
  /// Returns the evicted region ids (oldest first).
  Future<List<String>> enforceBudget(int maxBytes) async {
    final all = await _regions.findAll()
      ..sort((a, b) => a.downloadedAt.compareTo(b.downloadedAt));
    var total = all.fold<int>(0, (sum, region) => sum + region.sizeBytes);
    final evicted = <String>[];
    for (final region in all) {
      if (total <= maxBytes) break;
      await _regions.delete(region.regionId);
      total -= region.sizeBytes;
      evicted.add(region.regionId);
      _logger.info('Evicted tile pack ${region.regionId} (budget enforcement)');
    }
    return evicted;
  }
}
