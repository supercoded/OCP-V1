import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:ocp_app/app/ocp_app_coordinator.dart';
import 'package:ocp_app/maps/demo_tile_pack.dart';
import 'package:ocp_app/widgets/offline_tile_map_view.dart';
import 'package:ocp_app/widgets/sonar_view.dart';
import 'package:ocp_core/ocp_core.dart';
import 'package:ocp_maps/ocp_maps.dart';

/// Which of the two Maps views is showing.
enum MapsViewMode { sonar, tiles }

/// Maps workspace — sonar/tile views driven by wire-sourced [NodePosition]
/// history in [LocationService] (mock-first: POSITION frames over ODP).
class MapsWorkspace extends StatefulWidget {
  const MapsWorkspace({required this.coordinator, super.key});

  final OcpAppCoordinator coordinator;

  @override
  State<MapsWorkspace> createState() => _MapsWorkspaceState();
}

class _MapsWorkspaceState extends State<MapsWorkspace> {
  static const _historyWindow = Duration(minutes: 2);
  static const _projector = SonarProjector();

  StreamSubscription<NodePosition>? _positionSub;
  StreamSubscription<SessionState>? _sessionSub;
  MapsViewMode _mode = MapsViewMode.sonar;
  Map<String, List<SonarSample>> _samplesByNode = const {};
  bool _hasData = false;
  Future<MapRegion>? _tilePack;

  LocationService get _location => widget.coordinator.core.locationService;

  @override
  void initState() {
    super.initState();
    _positionSub = _location.positionUpdates.listen((_) => _refresh());
    _sessionSub =
        widget.coordinator.core.sessionService.stateChanges.listen((_) {
      _refresh();
    });
    _refresh();
  }

  Future<MapRegion> _ensureTilePack() {
    return _tilePack ??= DemoTilePackBuilder.ensure(
      cache: widget.coordinator.core.mapCacheService,
      baseDir: widget.coordinator.baseDirectory,
      center: widget.coordinator.selfPosition,
    );
  }

  @override
  void dispose() {
    _positionSub?.cancel();
    _sessionSub?.cancel();
    super.dispose();
  }

  Future<void> _refresh() async {
    if (!widget.coordinator.hasActiveSession) {
      if (!mounted) return;
      setState(() {
        _hasData = false;
        _samplesByNode = const {};
      });
      return;
    }

    final now = DateTime.now().toUtc();
    final cutoff = now.subtract(_historyWindow);
    final latest = await _location.latestPerNode();
    final samples = <String, List<SonarSample>>{};

    for (final fix in latest) {
      if (fix.timestamp.isBefore(cutoff)) continue;
      final history = await _location.history(fix.nodeId, limit: 30);
      final windowed = history.where((p) => !p.timestamp.isBefore(cutoff)).toList();
      if (windowed.isEmpty) continue;
      samples[fix.nodeId] = [
        for (final p in windowed)
          SonarSample(
            nodeId: p.nodeId,
            label: p.nodeId,
            position: GeoPoint(latitude: p.latitude, longitude: p.longitude),
            timestamp: p.timestamp,
            headingDegrees: p.heading,
            speedMps: p.speedMps,
          ),
      ];
    }

    if (!mounted) return;
    setState(() {
      _hasData = samples.isNotEmpty;
      _samplesByNode = samples;
    });
  }

  void _showNodeDetail(SonarBlip blip) {
    showModalBottomSheet<void>(
      context: context,
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(blip.label, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 8),
              Text('Distance: ${_formatRange(blip.rangeMeters)}'),
              Text('Bearing: ${blip.bearingDegrees.toStringAsFixed(0)}° true'),
              Text('Last heard: ${_formatAge(blip.ageSeconds)} ago'),
              Text(blip.isMoving ? 'Moving' : 'Stationary'),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SegmentedButton<MapsViewMode>(
            segments: const [
              ButtonSegment(
                value: MapsViewMode.sonar,
                label: Text('Sonar'),
                icon: Icon(Icons.radar),
              ),
              ButtonSegment(
                value: MapsViewMode.tiles,
                label: Text('Tile map'),
                icon: Icon(Icons.map),
              ),
            ],
            selected: {_mode},
            onSelectionChanged: (selection) =>
                setState(() => _mode = selection.first),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: _mode == MapsViewMode.sonar
                ? _buildSonar()
                : _buildTiles(),
          ),
        ],
      ),
    );
  }

  Widget _buildSonar() {
    if (!widget.coordinator.hasActiveSession) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text(
            'Pair a device in Devices to receive live POSITION frames over ODP.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }
    if (!_hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    return LayoutBuilder(
      builder: (context, constraints) {
        final side = constraints.biggest.shortestSide;
        final radius = math.max(0.0, side / 2 - 12);
        final center = ScreenOffset(
          constraints.maxWidth / 2,
          (constraints.maxHeight - 24) / 2,
        );
        final now = DateTime.now().toUtc();
        final scene = _projector.project(
          self: widget.coordinator.selfPosition,
          samplesByNode: _samplesByNode,
          center: center,
          radiusPixels: radius,
          now: now,
        );
        return Column(
          children: [
            Expanded(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SonarView(
                  viewModel: scene,
                  onBlipTap: _showNodeDetail,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '${scene.blips.length} node(s) over ODP · '
              'range ${_formatRange(scene.maxRangeMeters)} · north-up',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTiles() {
    return FutureBuilder<MapRegion>(
      future: _ensureTilePack(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Tile pack error: ${snapshot.error}'));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final region = snapshot.data!;
        return Column(
          children: [
            Expanded(
              child: OfflineTileMapView(
                tileProvider: FileTileProvider(region.storagePath),
                center: widget.coordinator.selfPosition,
                zoom: region.maxZoom,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Offline pack "${region.regionId}" · z${region.maxZoom} · '
              '${(region.sizeBytes / 1024).toStringAsFixed(0)} KiB · served from disk',
              style: Theme.of(context).textTheme.bodySmall,
              textAlign: TextAlign.center,
            ),
          ],
        );
      },
    );
  }

  static String _formatRange(double meters) {
    if (meters >= 1000) {
      return '${(meters / 1000).toStringAsFixed(meters % 1000 == 0 ? 0 : 1)} km';
    }
    return '${meters.toStringAsFixed(0)} m';
  }

  static String _formatAge(double seconds) {
    if (seconds < 60) return '${seconds.toStringAsFixed(0)} s';
    return '${(seconds / 60).toStringAsFixed(0)} min';
  }
}
