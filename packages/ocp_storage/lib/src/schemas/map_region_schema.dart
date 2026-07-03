import 'package:isar/isar.dart';

part 'map_region_schema.g.dart';

/// Metadata for a downloaded offline tile pack.
///
/// The tiles themselves live as files on disk (`{z}/{x}/{y}.png` under
/// [storagePath]); Isar only tracks what is cached and where.
@collection
class MapRegionSchema {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String regionId;

  late double minLat;
  late double minLon;
  late double maxLat;
  late double maxLon;

  late int minZoom;
  late int maxZoom;

  late String style;
  late int sizeBytes;
  late DateTime downloadedAt;
  late String storagePath;
}
