import 'dart:async';
import 'dart:math' show cos;
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:provider/provider.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';
import '../providers/network_provider.dart';
import '../providers/connection_provider.dart';
import '../widgets/status_lamp.dart';

/// Default center: continental US (matches desktop MapCanvas).
const _defaultCenter = LatLng(39.5, -98.5);

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final MapController _mapController = MapController();
  double _zoom = 4.0;
  LatLng _center = _defaultCenter;
  bool _showNodes = true;
  bool _showSensing = true;
  bool _showOfflineTiles = false;
  Timer? _cameraDebounce;

  @override
  void dispose() {
    _cameraDebounce?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkProvider>();
    final conn = context.watch<ConnectionProvider>();

    final positionedNodes = network.nodes.where((n) => n.hasPosition).toList();
    final sensingMarkers = _showSensing ? _projectSensing(conn, positionedNodes) : const <_ProjectedSensing>[];

    return Column(
      children: [
        Container(
          height: 44,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          decoration: const BoxDecoration(
            color: OcpColors.ocpPanel,
            border: Border(bottom: BorderSide(color: OcpColors.ocpBorder)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'MAP',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: OcpColors.ocpBright,
                ),
              ),
              Row(
                children: [
                  StatusLamp(connected: conn.connected),
                  const SizedBox(width: 8),
                  Text(
                    conn.connected ? 'Mesh linked' : 'Mesh standby',
                    style: TextStyle(
                      fontSize: 11,
                      fontFamily: 'JetBrainsMono',
                      color: conn.connected ? OcpColors.ocpGreen : OcpColors.ocpDim,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Text(
                    '${positionedNodes.length} nodes · ${sensingMarkers.length} targets',
                    style: const TextStyle(fontSize: 11, fontFamily: 'JetBrainsMono', color: OcpColors.ocpDim),
                  ),
                ],
              ),
            ],
          ),
        ),
        Expanded(
          child: Row(
            children: [
              Expanded(
                child: Stack(
                  children: [
                    FlutterMap(
                      mapController: _mapController,
                      options: MapOptions(
                        initialCenter: _center,
                        initialZoom: _zoom,
                        minZoom: 1,
                        maxZoom: 18,
                        backgroundColor: OcpColors.ocpBg,
                        onPositionChanged: (camera, hasGesture) {
                          if (!hasGesture) return;
                          _cameraDebounce?.cancel();
                          _cameraDebounce = Timer(const Duration(milliseconds: 80), () {
                            if (!mounted) return;
                            setState(() {
                              _zoom = camera.zoom;
                              _center = camera.center;
                            });
                          });
                        },
                      ),
                      children: [
                        Opacity(
                          opacity: _showOfflineTiles ? 0.55 : 1.0,
                          child: TileLayer(
                            // flutter_map renders raster tiles. Offline PMTiles/MVT is desktop MapLibre.
                            // Offline toggle dims attribution and keeps CARTO dark until a raster pack ships.
                            urlTemplate: 'https://{s}.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png',
                            subdomains: const ['a', 'b', 'c'],
                            userAgentPackageName: 'com.ocp.ocp_v1',
                            tileProvider: NetworkTileProvider(),
                          ),
                        ),
                        if (_showNodes)
                          MarkerLayer(
                            markers: positionedNodes.map((node) {
                              final name = node.shortName.isNotEmpty ? node.shortName : node.longName;
                              return Marker(
                                point: LatLng(node.lat!, node.lon!),
                                width: 88,
                                height: 44,
                                alignment: Alignment.topCenter,
                                child: _NodeMarker(label: name.isNotEmpty ? name : 'N${node.id}'),
                              );
                            }).toList(),
                          ),
                        if (_showSensing)
                          MarkerLayer(
                            markers: sensingMarkers
                                .map(
                                  (t) => Marker(
                                    point: t.point,
                                    width: 72,
                                    height: 40,
                                    alignment: Alignment.topCenter,
                                    child: _SensingMarker(label: 'RV-${t.nodeId}'),
                                  ),
                                )
                                .toList(),
                          ),
                      ],
                    ),
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: OcpColors.ocpBg.withAlpha(204),
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(color: OcpColors.ocpBorder),
                        ),
                        child: Text(
                          _statusText(conn, positionedNodes, sensingMarkers.length),
                          style: const TextStyle(fontSize: 10, fontFamily: 'JetBrainsMono', color: OcpColors.ocpDim),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 220,
                decoration: const BoxDecoration(
                  color: OcpColors.ocpPanel,
                  border: Border(left: BorderSide(color: OcpColors.ocpBorder)),
                ),
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'LAYER CONTROLS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: OcpColors.ocpDim,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildLayerToggle('Mesh Nodes', _showNodes, (v) => setState(() => _showNodes = v)),
                      _buildLayerToggle('Sensing Targets', _showSensing, (v) => setState(() => _showSensing = v)),
                      _buildLayerToggle('Offline Preview', _showOfflineTiles, (v) {
                        setState(() => _showOfflineTiles = v);
                        if (v) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                'Offline PMTiles/MVT is served on desktop MapLibre. Mobile uses dark online tiles until a raster pack is added.',
                              ),
                              backgroundColor: OcpColors.ocpPanel2,
                            ),
                          );
                        }
                      }),
                      const SizedBox(height: 16),
                      const Text(
                        'ZOOM',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: OcpColors.ocpDim,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          _buildZoomButton(Icons.add, () => _setZoom(_zoom + 1)),
                          const SizedBox(width: 8),
                          _buildZoomButton(Icons.remove, () => _setZoom(_zoom - 1)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: OcpColors.ocpBg,
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: OcpColors.ocpBorder),
                              ),
                              child: Text(
                                'z${_zoom.round()}',
                                style: const TextStyle(fontSize: 11, fontFamily: 'JetBrainsMono', color: OcpColors.ocpCyan),
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: _buildMapButton('Center on Self', Icons.my_location, () => _handleCenterSelf(positionedNodes)),
                      ),
                      const SizedBox(height: 8),
                      SizedBox(
                        width: double.infinity,
                        child: _buildMapButton('Import Offline Tiles', Icons.download, _handleImportTiles),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'NODE MARKERS',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.2,
                          color: OcpColors.ocpDim,
                        ),
                      ),
                      const SizedBox(height: 8),
                      if (positionedNodes.isEmpty)
                        const Text(
                          'No nodes with position data',
                          style: TextStyle(fontSize: 10, color: OcpColors.ocpDim),
                        )
                      else
                        ...positionedNodes.map((node) => Padding(
                              padding: const EdgeInsets.symmetric(vertical: 3),
                              child: InkWell(
                                onTap: () => _focusNode(node),
                                child: Row(
                                  children: [
                                    Container(
                                      width: 8,
                                      height: 8,
                                      decoration: const BoxDecoration(
                                        color: OcpColors.ocpGreen,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            node.shortName.isNotEmpty ? node.shortName : node.longName,
                                            style: const TextStyle(fontSize: 11, color: OcpColors.ocpText),
                                          ),
                                          Text(
                                            '${node.lat!.toStringAsFixed(4)}, ${node.lon!.toStringAsFixed(4)}',
                                            style: const TextStyle(fontSize: 9, fontFamily: 'JetBrainsMono', color: OcpColors.ocpDim),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )),
                      if (sensingMarkers.isNotEmpty) ...[
                        const SizedBox(height: 16),
                        const Text(
                          'SENSING TARGETS',
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.2,
                            color: OcpColors.ocpDim,
                          ),
                        ),
                        const SizedBox(height: 8),
                        ...sensingMarkers.map(
                          (t) => Padding(
                            padding: const EdgeInsets.symmetric(vertical: 3),
                            child: InkWell(
                              onTap: () {
                                _mapController.move(t.point, 14);
                                setState(() {
                                  _center = t.point;
                                  _zoom = 14;
                                });
                              },
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: const BoxDecoration(
                                      color: OcpColors.ocpAmber,
                                      shape: BoxShape.circle,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Expanded(
                                    child: Text(
                                      'RV-${t.nodeId}',
                                      style: const TextStyle(fontSize: 11, color: OcpColors.ocpText),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  List<_ProjectedSensing> _projectSensing(ConnectionProvider conn, List<MeshNode> positionedNodes) {
    // Match desktop MapPage: project local x/y meters from own node (id 0) GPS.
    final ownIdx = positionedNodes.indexWhere((n) => n.id == '0');
    final ownNode = ownIdx >= 0 ? positionedNodes[ownIdx] : null;
    final refLat = ownNode?.lat ?? _defaultCenter.latitude;
    final refLon = ownNode?.lon ?? _defaultCenter.longitude;
    const metersPerDegree = 111320.0;

    return conn.ruViewSensing.map((s) {
      final lat = refLat + (s.y / metersPerDegree);
      final lon = refLon + (s.x / (metersPerDegree * cos(refLat * 3.141592653589793 / 180)));
      return _ProjectedSensing(nodeId: s.nodeId, point: LatLng(lat, lon));
    }).toList();
  }

  void _setZoom(double next) {
    final zoom = next.clamp(1.0, 18.0);
    _mapController.move(_center, zoom);
    setState(() => _zoom = zoom);
  }

  void _focusNode(MeshNode node) {
    if (!node.hasPosition) return;
    final point = LatLng(node.lat!, node.lon!);
    _mapController.move(point, 14);
    setState(() {
      _center = point;
      _zoom = 14;
    });
  }

  Widget _buildLayerToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, color: OcpColors.ocpText)),
          GestureDetector(
            onTap: () => onChanged(!value),
            child: Container(
              width: 36,
              height: 20,
              decoration: BoxDecoration(
                color: value ? OcpColors.ocpGreen : OcpColors.ocpPanel2,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: value ? OcpColors.ocpGreen : OcpColors.ocpBorder),
              ),
              child: AnimatedAlign(
                duration: const Duration(milliseconds: 150),
                alignment: value ? Alignment.centerRight : Alignment.centerLeft,
                child: Container(
                  width: 14,
                  height: 14,
                  margin: const EdgeInsets.symmetric(horizontal: 3),
                  decoration: BoxDecoration(
                    color: value ? OcpColors.ocpBg : OcpColors.ocpDim,
                    shape: BoxShape.circle,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildZoomButton(IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 36,
        height: 36,
        decoration: BoxDecoration(
          color: OcpColors.ocpPanel2,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: OcpColors.ocpBorder),
        ),
        child: Icon(icon, size: 18, color: OcpColors.ocpText),
      ),
    );
  }

  Widget _buildMapButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: OcpColors.ocpPanel2,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: OcpColors.ocpBorder),
        ),
        child: Row(
          children: [
            Icon(icon, size: 14, color: OcpColors.ocpBright),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, color: OcpColors.ocpText),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusText(ConnectionProvider conn, List positionedNodes, int sensingCount) {
    final offlineNote = _showOfflineTiles ? ' · offline preview' : '';
    if (conn.connected || sensingCount > 0) {
      return 'Live · ${positionedNodes.length} nodes · $sensingCount targets$offlineNote';
    }
    return 'Ready — dark basemap · connect for live nodes$offlineNote';
  }

  void _handleCenterSelf(List<MeshNode> positionedNodes) {
    if (positionedNodes.isEmpty) {
      _mapController.move(_defaultCenter, 4);
      setState(() {
        _center = _defaultCenter;
        _zoom = 4;
      });
      return;
    }
    _focusNode(positionedNodes.first);
  }

  void _handleImportTiles() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Offline vector PMTiles run on desktop MapLibre. Flutter map uses raster basemaps for now.',
        ),
        backgroundColor: OcpColors.ocpPanel2,
      ),
    );
  }
}

class _ProjectedSensing {
  final int nodeId;
  final LatLng point;
  const _ProjectedSensing({required this.nodeId, required this.point});
}

class _NodeMarker extends StatelessWidget {
  final String label;

  const _NodeMarker({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: OcpColors.ocpGreen,
            shape: BoxShape.circle,
            border: Border.all(color: OcpColors.ocpBright, width: 1.5),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: OcpColors.ocpBg.withAlpha(230),
            border: Border.all(color: OcpColors.ocpBorder),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontFamily: 'JetBrainsMono',
              letterSpacing: 0.5,
              color: OcpColors.ocpText,
            ),
          ),
        ),
      ],
    );
  }
}

class _SensingMarker extends StatelessWidget {
  final String label;

  const _SensingMarker({required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(
            color: OcpColors.ocpAmber,
            shape: BoxShape.circle,
            border: Border.all(color: OcpColors.ocpBright, width: 1.5),
          ),
        ),
        const SizedBox(height: 2),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
          decoration: BoxDecoration(
            color: OcpColors.ocpBg.withAlpha(230),
            border: Border.all(color: OcpColors.ocpBorder),
            borderRadius: BorderRadius.circular(2),
          ),
          child: Text(
            label.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 9,
              fontFamily: 'JetBrainsMono',
              letterSpacing: 0.5,
              color: OcpColors.ocpAmber,
            ),
          ),
        ),
      ],
    );
  }
}
