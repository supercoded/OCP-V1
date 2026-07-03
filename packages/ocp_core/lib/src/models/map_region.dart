/// Metadata for a downloaded offline tile pack (domain model).
///
/// The tiles themselves are files on disk under [storagePath]; this record just
/// tracks what is cached and where.
class MapRegion {
  const MapRegion({
    required this.regionId,
    required this.minLatitude,
    required this.minLongitude,
    required this.maxLatitude,
    required this.maxLongitude,
    required this.minZoom,
    required this.maxZoom,
    required this.style,
    required this.sizeBytes,
    required this.downloadedAt,
    required this.storagePath,
  });

  final String regionId;
  final double minLatitude;
  final double minLongitude;
  final double maxLatitude;
  final double maxLongitude;
  final int minZoom;
  final int maxZoom;
  final String style;
  final int sizeBytes;
  final DateTime downloadedAt;
  final String storagePath;

  /// Whether this pack has tiles for (`latitude`, `longitude`) at [zoom].
  bool covers(double latitude, double longitude, int zoom) =>
      zoom >= minZoom &&
      zoom <= maxZoom &&
      latitude >= minLatitude &&
      latitude <= maxLatitude &&
      longitude >= minLongitude &&
      longitude <= maxLongitude;
}
