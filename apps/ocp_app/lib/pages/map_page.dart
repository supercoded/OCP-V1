import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';
import '../providers/network_provider.dart';
import '../providers/connection_provider.dart';
import '../widgets/status_lamp.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  double _zoom = 4.0;
  bool _showNodes = true;
  bool _showSensing = true;
  bool _showOfflineTiles = false;

  @override
  Widget build(BuildContext context) {
    final network = context.watch<NetworkProvider>();
    final conn = context.watch<ConnectionProvider>();

    // Nodes with positions
    final positionedNodes = network.nodes.where((n) => n.hasPosition).toList();

    return Column(
      children: [
        // Header bar
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
                    '${positionedNodes.length} nodes',
                    style: const TextStyle(fontSize: 11, fontFamily: 'JetBrainsMono', color: OcpColors.ocpDim),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Main content
        Expanded(
          child: Row(
            children: [
              // Map area
              Expanded(
                child: Stack(
                  children: [
                    // Map placeholder
                    Container(
                      color: OcpColors.ocpBg,
                      child: CustomPaint(
                        painter: _MapPlaceholderPainter(positionedNodes),
                        size: Size.infinite,
                      ),
                    ),
                    // Status overlay
                    Positioned(
                      bottom: 12,
                      left: 12,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: OcpColors.ocpBg.withAlpha(204),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          _statusText(conn, positionedNodes),
                          style: const TextStyle(fontSize: 10, fontFamily: 'JetBrainsMono', color: OcpColors.ocpDim),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Controls sidebar
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
                      _buildLayerToggle('Offline Tiles', _showOfflineTiles, (v) => setState(() => _showOfflineTiles = v)),
                      const SizedBox(height: 16),
                      // Zoom controls
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
                          _buildZoomButton(Icons.add, () => setState(() => _zoom = (_zoom + 1).clamp(1, 18))),
                          const SizedBox(width: 8),
                          _buildZoomButton(Icons.remove, () => setState(() => _zoom = (_zoom - 1).clamp(1, 18))),
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
                      // Center on self
                      SizedBox(
                        width: double.infinity,
                        child: _buildMapButton('Center on Self', Icons.my_location, _handleCenterSelf),
                      ),
                      const SizedBox(height: 8),
                      // Import tiles
                      SizedBox(
                        width: double.infinity,
                        child: _buildMapButton('Import Offline Tiles', Icons.download, _handleImportTiles),
                      ),
                      const SizedBox(height: 16),
                      // Node markers list
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
                              child: Row(
                                children: [
                                  Container(
                                    width: 8,
                                    height: 8,
                                    decoration: BoxDecoration(
                                      color: OcpColors.ocpBright,
                                      shape: BoxShape.circle,
                                      boxShadow: [],
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
                            )),
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

  String _statusText(ConnectionProvider conn, List positionedNodes) {
    if (conn.connected) {
      return 'Online · ${positionedNodes.length} nodes positioned';
    }
    return 'Ready — load tiles or connect for live data';
  }

  void _handleCenterSelf() {
    // Placeholder — would center on own node position
    setState(() {
      _zoom = 14.0;
    });
  }

  void _handleImportTiles() {
    // Placeholder — would open file dialog for offline tile import
  }
}

/// Placeholder map painter showing a dark grid with node markers
class _MapPlaceholderPainter extends CustomPainter {
  final List<MeshNode> nodes;

  _MapPlaceholderPainter(this.nodes);

  @override
  void paint(Canvas canvas, Size size) {
    // Dark background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = OcpColors.ocpBg);

    // Grid
    final gridPaint = Paint()
      ..color = OcpColors.ocpBorder.withAlpha(51)
      ..strokeWidth = 0.5;

    final gridSize = 40.0;
    for (double x = 0; x < size.width; x += gridSize) {
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }
    for (double y = 0; y < size.height; y += gridSize) {
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    // Center text
    final textPainter = TextPainter(
      text: const TextSpan(
        text: 'MapLibre GL integration requires flutter_map package',
        style: TextStyle(color: OcpColors.ocpDim, fontSize: 14, fontFamily: 'JetBrainsMono'),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2 - 30));

    // Place node markers in a grid pattern on the placeholder
    if (nodes.isNotEmpty) {
      final markerPaint = Paint()..color = OcpColors.ocpGreen;
      final glowPaint = Paint()
        ..color = OcpColors.ocpGreen.withAlpha(51)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 2;

      // Distribute nodes across the map area
      final cols = (size.width / 120).floor().clamp(1, 10);
      final rows = (nodes.length / cols).ceil();

      for (int i = 0; i < nodes.length && i < rows * cols; i++) {
        final row = i ~/ cols;
        final col = i % cols;
        final x = 80.0 + col * ((size.width - 160) / cols.clamp(1, cols));
        final y = 80.0 + row * 60.0;

        canvas.drawCircle(Offset(x, y), 5, markerPaint);
        canvas.drawCircle(Offset(x, y), 10, glowPaint);

        // Label
        final name = nodes[i].shortName.isNotEmpty ? nodes[i].shortName : nodes[i].longName;
        final tp = TextPainter(
          text: TextSpan(text: name, style: const TextStyle(color: OcpColors.ocpText, fontSize: 10, fontFamily: 'JetBrainsMono')),
          textDirection: TextDirection.ltr,
        );
        tp.layout();
        tp.paint(canvas, Offset(x - tp.width / 2, y + 14));
      }
    }
  }

  @override
  bool shouldRepaint(covariant _MapPlaceholderPainter oldDelegate) {
    return oldDelegate.nodes != nodes;
  }
}