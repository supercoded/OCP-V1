import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:ocp_maps/ocp_maps.dart';

/// Renders a self-centered offline map from tiles served by a [TileProvider].
///
/// Presentation only: it asks [TileGridPlanner] which tiles cover the viewport,
/// loads their bytes from the provider, and lays them out. No network, no
/// business logic.
class OfflineTileMapView extends StatefulWidget {
  const OfflineTileMapView({
    required this.tileProvider,
    required this.center,
    required this.zoom,
    this.radius = 1,
    super.key,
  });

  final TileProvider tileProvider;
  final GeoPoint center;
  final int zoom;
  final int radius;

  @override
  State<OfflineTileMapView> createState() => _OfflineTileMapViewState();
}

class _OfflineTileMapViewState extends State<OfflineTileMapView> {
  late Future<_LoadedGrid> _grid;

  @override
  void initState() {
    super.initState();
    _grid = _load();
  }

  @override
  void didUpdateWidget(OfflineTileMapView oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.center != widget.center ||
        oldWidget.zoom != widget.zoom ||
        oldWidget.radius != widget.radius ||
        oldWidget.tileProvider != widget.tileProvider) {
      _grid = _load();
    }
  }

  Future<_LoadedGrid> _load() async {
    final plan = TileGridPlanner.around(
      widget.center,
      widget.zoom,
      radius: widget.radius,
    );
    final bytes = <TileCoordinate, Uint8List>{};
    for (final tile in plan.tiles) {
      final data = await widget.tileProvider.readTile(tile.coordinate);
      if (data != null) bytes[tile.coordinate] = Uint8List.fromList(data);
    }
    return _LoadedGrid(plan: plan, bytes: bytes);
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<_LoadedGrid>(
      future: _grid,
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final grid = snapshot.data!;
        if (grid.bytes.isEmpty) {
          return const Center(
            child: Text('Tile pack has no tiles for this location.'),
          );
        }
        return ClipRRect(
          borderRadius: BorderRadius.circular(12),
          child: FittedBox(
            child: SizedBox(
              width: grid.plan.width,
              height: grid.plan.height,
              child: Stack(
                children: [
                  for (final placed in grid.plan.tiles)
                    if (grid.bytes[placed.coordinate] != null)
                      Positioned(
                        left: placed.left,
                        top: placed.top,
                        width: grid.plan.tileSize,
                        height: grid.plan.tileSize,
                        child: Image.memory(
                          grid.bytes[placed.coordinate]!,
                          fit: BoxFit.fill,
                          gaplessPlayback: true,
                        ),
                      ),
                  // Self marker at the grid center.
                  Positioned(
                    left: grid.plan.width / 2 - 8,
                    top: grid.plan.height / 2 - 8,
                    child: const _SelfMarker(),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

class _SelfMarker extends StatelessWidget {
  const _SelfMarker();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 16,
      height: 16,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primary,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.white, width: 2),
      ),
    );
  }
}

class _LoadedGrid {
  const _LoadedGrid({required this.plan, required this.bytes});

  final TileGridPlan plan;
  final Map<TileCoordinate, Uint8List> bytes;
}
