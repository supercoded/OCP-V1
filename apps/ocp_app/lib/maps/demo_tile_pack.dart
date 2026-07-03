import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:ocp_core/ocp_core.dart';
import 'package:ocp_maps/ocp_maps.dart';

/// Builds a small offline tile pack on disk for the MVP tile view.
///
/// No real tile server is available off-grid, so this renders synthetic slippy
/// tiles (colored, labeled `z/x/y`) to `{baseDir}/tiles/{regionId}/{z}/{x}/{y}.png`
/// once, then registers a [MapRegion]. The app then reads and renders them via
/// [FileTileProvider] — exercising the genuine offline read path end to end.
abstract final class DemoTilePackBuilder {
  static const String regionId = 'demo-sf';
  static const int tilePixels = 256;

  /// Ensures the pack exists and is registered, returning its [MapRegion].
  static Future<MapRegion> ensure({
    required MapCacheService cache,
    required Directory baseDir,
    required GeoPoint center,
    int zoom = 13,
    int radius = 2,
  }) async {
    final packDir = Directory('${baseDir.path}/tiles/$regionId');
    final centerTile = TileMath.tileForGeo(center, zoom);
    final minX = centerTile.x - radius;
    final maxX = centerTile.x + radius;
    final minY = centerTile.y - radius;
    final maxY = centerTile.y + radius;

    // Bounds: NW corner of the top-left tile → N/W; NW corner of one tile
    // past the bottom-right → S/E.
    final topLeft = TileMath.northWestCorner(
      TileCoordinate(z: zoom, x: minX, y: minY),
    );
    final bottomRight = TileMath.northWestCorner(
      TileCoordinate(z: zoom, x: maxX + 1, y: maxY + 1),
    );

    final existing = await _registeredRegion(cache);
    final centerFile = File(TileMath.tilePath(packDir.path, centerTile));
    if (existing != null && await centerFile.exists()) {
      return existing;
    }

    var sizeBytes = 0;
    for (var x = minX; x <= maxX; x++) {
      for (var y = minY; y <= maxY; y++) {
        final tile = TileCoordinate(z: zoom, x: x, y: y);
        final bytes = await _renderTile(tile);
        final file = File(TileMath.tilePath(packDir.path, tile));
        await file.parent.create(recursive: true);
        await file.writeAsBytes(bytes);
        sizeBytes += bytes.length;
      }
    }

    final region = MapRegion(
      regionId: regionId,
      minLatitude: bottomRight.latitude,
      maxLatitude: topLeft.latitude,
      minLongitude: topLeft.longitude,
      maxLongitude: bottomRight.longitude,
      minZoom: zoom,
      maxZoom: zoom,
      style: 'demo',
      sizeBytes: sizeBytes,
      downloadedAt: DateTime.now().toUtc(),
      storagePath: packDir.path,
    );
    await cache.register(region);
    return region;
  }

  static Future<MapRegion?> _registeredRegion(MapCacheService cache) async {
    final all = await cache.regions();
    for (final region in all) {
      if (region.regionId == regionId) return region;
    }
    return null;
  }

  static Future<Uint8List> _renderTile(TileCoordinate tile) async {
    final recorder = ui.PictureRecorder();
    final canvas = Canvas(recorder);
    final size = tilePixels.toDouble();
    final rect = Rect.fromLTWH(0, 0, size, size);

    final hue = ((tile.x * 53 + tile.y * 97) % 360).toDouble();
    final background = HSLColor.fromAHSL(1, hue, 0.30, 0.82).toColor();
    canvas.drawRect(rect, Paint()..color = background);

    final grid = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1
      ..color = Colors.white.withValues(alpha: 0.6);
    for (var i = 1; i < 4; i++) {
      final o = size / 4 * i;
      canvas.drawLine(Offset(o, 0), Offset(o, size), grid);
      canvas.drawLine(Offset(0, o), Offset(size, o), grid);
    }
    canvas.drawRect(
      rect.deflate(1),
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2
        ..color = Colors.black.withValues(alpha: 0.35),
    );

    final builder = ui.ParagraphBuilder(
      ui.ParagraphStyle(fontSize: 15, textAlign: TextAlign.center),
    )
      ..pushStyle(ui.TextStyle(color: Colors.black.withValues(alpha: 0.8)))
      ..addText('${tile.z}/${tile.x}/${tile.y}');
    final paragraph = builder.build()
      ..layout(ui.ParagraphConstraints(width: size));
    canvas.drawParagraph(paragraph, Offset(0, size / 2 - paragraph.height / 2));

    final picture = recorder.endRecording();
    final image = await picture.toImage(tilePixels, tilePixels);
    final data = await image.toByteData(format: ui.ImageByteFormat.png);
    image.dispose();
    picture.dispose();
    return data!.buffer.asUint8List();
  }
}
