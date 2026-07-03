import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:ocp_app/widgets/offline_tile_map_view.dart';
import 'package:ocp_maps/ocp_maps.dart';

/// A 1×1 transparent PNG — enough for `Image.memory` to accept the bytes.
final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAYAAAAfFcSJAAAAC0lEQVR42mNk'
  '+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

void main() {
  testWidgets('renders tiles from the provider for the viewport',
      (tester) async {
    const center = GeoPoint(latitude: 37.7749, longitude: -122.4194);
    const zoom = 13;
    final provider = MemoryTileProvider();
    final plan = TileGridPlanner.around(center, zoom);
    for (final placed in plan.tiles) {
      provider.put(placed.coordinate, _pngBytes);
    }

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: OfflineTileMapView(
              tileProvider: provider,
              center: center,
              zoom: zoom,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.byType(Image), findsNWidgets(plan.tiles.length));
  });

  testWidgets('shows a message when the pack has no tiles for the location',
      (tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: SizedBox(
            width: 300,
            height: 300,
            child: OfflineTileMapView(
              tileProvider: MemoryTileProvider(),
              center: const GeoPoint(latitude: 37.7749, longitude: -122.4194),
              zoom: 13,
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Tile pack has no tiles for this location.'), findsOneWidget);
  });
}
