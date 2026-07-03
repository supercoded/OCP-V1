import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:mock_position_feed/mock_position_feed.dart';
import 'package:ocp_app/app/ocp_app_coordinator.dart';
import 'package:ocp_app/widgets/sonar_view.dart';
import 'package:ocp_core/ocp_core.dart';
import 'package:ocp_maps/ocp_maps.dart';

/// Which of the two Maps views is showing.
enum MapsViewMode { sonar, tiles }

/// Maps workspace — an offline tile map and a self-centered sonar/radar view,
/// toggled over the same node data (build-plan-v2 §1, maps-spec §4).
///
/// For the Phase 1 MVP this is driven by the coordinator's synthetic
/// [MockPositionFeed]; each tick ingests fixes through the core Location
/// Manager, exercising the real storage path before GPS hardware exists.
class MapsWorkspace extends StatefulWidget {
  const MapsWorkspace({required this.coordinator, super.key});

  final OcpAppCoordinator coordinator;

  @override
  State<MapsWorkspace> createState() => _MapsWorkspaceState();
}

class _MapsWorkspaceState extends State<MapsWorkspace> {
  static const _tickInterval = Duration(seconds: 1);
  static const _simStep = Duration(seconds: 5);
  static const _historyWindow = Duration(minutes: 2);
  static const _projector = SonarProjector();

  Timer? _timer;
  late DateTime _simTime;
  MapsViewMode _mode = MapsViewMode.sonar;
  Map<String, List<SonarSample>> _samplesByNode = const {};
  bool _hasData = false;

  MockPositionFeed get _feed => widget.coordinator.positionFeed;

  @override
  void initState() {
    super.initState();
    _simTime = _feed.epoch;
    _advance();
    _timer = Timer.periodic(_tickInterval, (_) => _advance());
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _advance() async {
    _simTime = _simTime.add(_simStep);
    final windowStart = _simTime.subtract(_historyWindow);
    final history = _feed.history(
      from: windowStart.isBefore(_feed.epoch) ? _feed.epoch : windowStart,
      to: _simTime,
      interval: const Duration(seconds: 10),
    );

    // Ingest the latest fix per node through the real Location Manager.
    for (final samples in history.values) {
      if (samples.isEmpty) continue;
      final latest = samples.last;
      await widget.coordinator.core.locationService.ingest(
        NodePosition(
          nodeId: latest.nodeId,
          latitude: latest.latitude,
          longitude: latest.longitude,
          altitude: latest.altitudeMeters,
          heading: latest.headingDegrees,
          speedMps: latest.speedMps,
          timestamp: latest.timestamp,
        ),
      );
    }

    if (!mounted) return;
    setState(() {
      _hasData = true;
      _samplesByNode = {
        for (final entry in history.entries)
          entry.key: [
            for (final p in entry.value)
              SonarSample(
                nodeId: p.nodeId,
                position:
                    GeoPoint(latitude: p.latitude, longitude: p.longitude),
                timestamp: p.timestamp,
                headingDegrees: p.headingDegrees,
                speedMps: p.speedMps,
              ),
          ],
      };
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
        final scene = _projector.project(
          self: widget.coordinator.selfPosition,
          samplesByNode: _samplesByNode,
          center: center,
          radiusPixels: radius,
          now: _simTime,
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
              '${scene.blips.length} node(s) tracked · '
              'range ${_formatRange(scene.maxRangeMeters)} · north-up',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        );
      },
    );
  }

  Widget _buildTiles() {
    return FutureBuilder<List<MapRegion>>(
      future: widget.coordinator.core.mapRegions.findAll(),
      builder: (context, snapshot) {
        final regions = snapshot.data ?? const [];
        if (regions.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(24),
              child: Text(
                'No offline tile pack downloaded yet.\n\n'
                'Tile packs are pre-fetched in one online session, then served '
                'from disk off-grid. The sonar view already works offline from '
                'live node positions.',
                textAlign: TextAlign.center,
              ),
            ),
          );
        }
        return ListView.builder(
          itemCount: regions.length,
          itemBuilder: (context, index) {
            final region = regions[index];
            return ListTile(
              leading: const Icon(Icons.layers),
              title: Text('${region.style} · z${region.minZoom}-${region.maxZoom}'),
              subtitle: Text(
                '${(region.sizeBytes / 1024).toStringAsFixed(0)} KiB · '
                '${region.storagePath}',
              ),
            );
          },
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
