import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';
import '../models/connection_history.dart';
import '../providers/connection_provider.dart';
import '../widgets/status_lamp.dart';
import '../widgets/analog_button.dart';

enum _DevicesTab { connections, ruview, firmware, baofeng }

class DevicesPage extends StatefulWidget {
  const DevicesPage({super.key});

  @override
  State<DevicesPage> createState() => _DevicesPageState();
}

class _DevicesPageState extends State<DevicesPage> {
  _DevicesTab _tab = _DevicesTab.connections;

  // Connection form state
  bool _autoDetect = true;
  final _tcpHostController = TextEditingController(text: '10.0.0.100');
  final _tcpPortController = TextEditingController(text: '4403');
  final _serialPortController = TextEditingController(text: '/dev/ttyUSB0');
  final _bleIdController = TextEditingController();

  // RuView form state
  final _ruviewHostController = TextEditingController(text: 'localhost');
  final _ruviewPortController = TextEditingController(text: '3001');

  // Error state
  String? _lastError;

  @override
  void dispose() {
    _tcpHostController.dispose();
    _tcpPortController.dispose();
    _serialPortController.dispose();
    _bleIdController.dispose();
    _ruviewHostController.dispose();
    _ruviewPortController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionProvider>();

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header + tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'DEVICES',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: OcpColors.ocpBright,
                ),
              ),
              Row(
                children: _DevicesTab.values.map((t) {
                  final isActive = _tab == t;
                  final label = t.name[0].toUpperCase() + t.name.substring(1);
                  return Padding(
                    padding: const EdgeInsets.only(left: 6),
                    child: GestureDetector(
                      onTap: () => setState(() => _tab = t),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: isActive ? OcpColors.ocpPanel2 : Colors.transparent,
                          borderRadius: BorderRadius.circular(4),
                          border: Border.all(
                            color: isActive ? OcpColors.ocpBright : OcpColors.ocpBorder,
                          ),
                        ),
                        child: Text(
                          label,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1,
                            color: isActive ? OcpColors.ocpBright : OcpColors.ocpDim,
                          ),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          // Error banner
          if (_lastError != null)
            Container(
              width: double.infinity,
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: OcpColors.ocpRed.withAlpha(26),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: OcpColors.ocpRed.withAlpha(77)),
              ),
              child: Text(
                _lastError!,
                style: const TextStyle(
                  fontSize: 12,
                  fontFamily: 'JetBrainsMono',
                  color: OcpColors.ocpRed,
                ),
              ),
            ),
          // Tab content
          Expanded(
            child: SingleChildScrollView(
              child: _buildTabContent(context, conn),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(BuildContext context, ConnectionProvider conn) {
    switch (_tab) {
      case _DevicesTab.connections:
        return _buildConnectionsTab(context, conn);
      case _DevicesTab.ruview:
        return _buildRuViewTab(context, conn);
      case _DevicesTab.firmware:
        return _buildFirmwareTab(context);
      case _DevicesTab.baofeng:
        return _buildBaofengTab(context, conn);
    }
  }

  Widget _buildConnectionsTab(BuildContext context, ConnectionProvider conn) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Meshtastic connection panel
          _buildPanel(
            title: 'Meshtastic Connection',
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'STATUS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: OcpColors.ocpDim),
                  ),
                  Row(
                    children: [
                      StatusLamp(connected: conn.connected, connecting: conn.connecting),
                      const SizedBox(width: 8),
                      Text(
                        conn.connected
                            ? 'Connected · ${conn.transportKind ?? "unknown"}'
                            : conn.connecting ? 'Connecting...' : 'Disconnected',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'JetBrainsMono',
                          color: conn.connected ? OcpColors.ocpGreen : OcpColors.ocpDim,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // Auto-detect toggle
              _buildToggle('Auto-detect transport', _autoDetect, (v) => setState(() => _autoDetect = v)),
              const SizedBox(height: 12),
              // TCP inputs
              Row(
                children: [
                  Expanded(child: _buildTextField('TCP Host', _tcpHostController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('TCP Port', _tcpPortController)),
                ],
              ),
              const SizedBox(height: 12),
              // Serial / BLE inputs
              Row(
                children: [
                  Expanded(child: _buildTextField('Serial Port', _serialPortController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('BLE Device ID', _bleIdController, hint: 'aa:bb:cc:dd:ee:ff')),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  AnalogButton(
                    onPressed: conn.connecting || conn.connected ? () {} : _handleConnect,
                    child: Text(
                      conn.connecting ? 'Connecting...' : 'Connect',
                      style: TextStyle(
                        fontSize: 12,
                        color: conn.connecting || conn.connected ? OcpColors.ocpBg.withAlpha(128) : OcpColors.ocpBg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnalogButton(
                    onPressed: conn.connected ? _handleDisconnect : () {},
                    child: Text(
                      'Disconnect',
                      style: TextStyle(
                        fontSize: 12,
                        color: conn.connected ? OcpColors.ocpBg : OcpColors.ocpBg.withAlpha(128),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Status panel
          _buildPanel(
            title: 'Status',
            children: [
              _buildStatusRow('Transport', conn.transportKind ?? '—'),
              _buildStatusRow('Connected', conn.connected ? 'yes' : 'no'),
              _buildStatusRow('Mesh nodes', '${conn.nodeCount}'),
            ],
          ),
          // Recent connections
          if (conn.recentConnections.isNotEmpty) ...[
            const SizedBox(height: 12),
            _buildRecentConnectionsPanel(context, conn),
          ],
        ],
      ),
    );
  }

  Widget _buildRuViewTab(BuildContext context, ConnectionProvider conn) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildPanel(
            title: 'RuView Presence Sensor',
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'STATUS',
                    style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: OcpColors.ocpDim),
                  ),
                  Row(
                    children: [
                      StatusLamp(connected: conn.ruViewConnected),
                      const SizedBox(width: 8),
                      Text(
                        conn.ruViewConnected ? 'Streaming' : 'Standby',
                        style: TextStyle(
                          fontSize: 11,
                          fontFamily: 'JetBrainsMono',
                          color: conn.ruViewConnected ? OcpColors.ocpGreen : OcpColors.ocpDim,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(child: _buildTextField('Host', _ruviewHostController)),
                  const SizedBox(width: 12),
                  Expanded(child: _buildTextField('WebSocket Port', _ruviewPortController)),
                ],
              ),
              const SizedBox(height: 8),
              const Text(
                'Requires the RuView sensing server. Run the Docker simulator with: bash scripts/run-ruview-simulator.sh',
                style: TextStyle(fontSize: 10, color: OcpColors.ocpDim, height: 1.4),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  AnalogButton(
                    onPressed: conn.ruViewConnected ? () {} : _handleStartRuView,
                    child: Text(
                      'Start RuView',
                      style: TextStyle(
                        fontSize: 12,
                        color: conn.ruViewConnected ? OcpColors.ocpBg.withAlpha(128) : OcpColors.ocpBg,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  AnalogButton(
                    onPressed: conn.ruViewConnected ? _handleStopRuView : () {},
                    child: Text(
                      'Stop RuView',
                      style: TextStyle(
                        fontSize: 12,
                        color: conn.ruViewConnected ? OcpColors.ocpBg : OcpColors.ocpBg.withAlpha(128),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          _buildPanel(
            title: 'Targets',
            children: [
              _buildStatusRow('Active targets', '${conn.ruViewTargetCount}'),
              if (conn.ruViewError != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    'Error: ${conn.ruViewError}',
                    style: const TextStyle(fontSize: 12, color: OcpColors.ocpRed, fontFamily: 'JetBrainsMono'),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFirmwareTab(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: _buildPanel(
        title: 'Meshtastic Firmware Updater',
        children: [
          const Text(
            'Use the CLI script to list releases, download assets, and flash firmware with external tools.',
            style: TextStyle(fontSize: 12, color: OcpColors.ocpDim, height: 1.4),
          ),
          const SizedBox(height: 16),
          _buildCodeBlock('npm run firmware:list'),
          const SizedBox(height: 8),
          _buildCodeBlock('npm run firmware:flash -- --board rak4631 --tag v2.3.13.1 --port COM3'),
          const SizedBox(height: 16),
          const Text(
            'Requires esptool.py for ESP32 boards or nrfutil for nRF52/RAK4631 boards.',
            style: TextStyle(fontSize: 10, color: OcpColors.ocpDim, height: 1.4),
          ),
        ],
      ),
    );
  }

  Widget _buildBaofengTab(BuildContext context, ConnectionProvider conn) {
    return ConstrainedBox(
      constraints: const BoxConstraints(maxWidth: 600),
      child: _buildPanel(
        title: 'Baofeng Channel Editor',
        children: [
          Row(
            children: [
              StatusLamp(connected: conn.baofengConnected),
              const SizedBox(width: 8),
              Text(
                conn.baofengConnected ? 'Connected · ${conn.baofengPortName ?? ""}' : 'Not connected',
                style: TextStyle(
                  fontSize: 12,
                  fontFamily: 'JetBrainsMono',
                  color: conn.baofengConnected ? OcpColors.ocpGreen : OcpColors.ocpDim,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Text(
            'Baofeng UV-5R series channel editor for programming frequencies, CTCSS/DCS tones, and power settings.',
            style: TextStyle(fontSize: 12, color: OcpColors.ocpDim, height: 1.4),
          ),
          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: OcpColors.ocpBg,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: OcpColors.ocpBorder),
            ),
            child: const Column(
              children: [
                Icon(Icons.radio, size: 32, color: OcpColors.ocpAmber),
                SizedBox(height: 8),
                Text(
                  'Channel editor coming soon',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600, color: OcpColors.ocpAmber),
                ),
                SizedBox(height: 4),
                Text(
                  'Full Baofeng programming requires serial cable access\nand is currently available in the desktop (Electron) app only.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 10, color: OcpColors.ocpDim, height: 1.4),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Reusable panel widget
  Widget _buildPanel({required String title, required List<Widget> children}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: OcpColors.ocpPanel,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: OcpColors.ocpBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: const TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: OcpColors.ocpDim,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: OcpColors.ocpDim),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          style: const TextStyle(fontSize: 12, fontFamily: 'JetBrainsMono', color: OcpColors.ocpText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: OcpColors.ocpDim.withAlpha(128), fontSize: 12),
            filled: true,
            fillColor: OcpColors.ocpBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            isDense: true,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: OcpColors.ocpBorder),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: OcpColors.ocpBorder),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(4),
              borderSide: const BorderSide(color: OcpColors.ocpBright),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggle(String label, bool value, ValueChanged<bool> onChanged) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12, color: OcpColors.ocpText)),
        GestureDetector(
          onTap: () => onChanged(!value),
          child: Container(
            width: 40,
            height: 22,
            decoration: BoxDecoration(
              color: value ? OcpColors.ocpGreen : OcpColors.ocpPanel2,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: value ? OcpColors.ocpGreen : OcpColors.ocpBorder),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
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
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontFamily: 'JetBrainsMono', color: OcpColors.ocpDim)),
          Text(value, style: const TextStyle(fontSize: 12, fontFamily: 'JetBrainsMono', color: OcpColors.ocpText)),
        ],
      ),
    );
  }

  Widget _buildCodeBlock(String code) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: OcpColors.ocpBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: OcpColors.ocpBorder),
      ),
      child: Text(
        code,
        style: const TextStyle(fontSize: 10, fontFamily: 'JetBrainsMono', color: OcpColors.ocpBright),
      ),
    );
  }

  Widget _buildRecentConnectionsPanel(BuildContext context, ConnectionProvider conn) {
    return _buildPanel(
      title: 'Recent Connections',
      children: [
        ...conn.recentConnections.map((rc) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 3),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  rc.toString(),
                  style: const TextStyle(fontSize: 11, fontFamily: 'JetBrainsMono', color: OcpColors.ocpText),
                ),
              ),
              Text(
                _formatLastUsed(rc.lastUsed),
                style: const TextStyle(fontSize: 10, fontFamily: 'JetBrainsMono', color: OcpColors.ocpDim),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _handleRecentConnect(rc),
                child: const Text(
                  'CONNECT',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: OcpColors.ocpGreen, letterSpacing: 1),
                ),
              ),
            ],
          ),
        )),
        const SizedBox(height: 8),
        GestureDetector(
          onTap: () => conn.clearRecentConnections(),
          child: const Text(
            'CLEAR HISTORY',
            style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: OcpColors.ocpRed, letterSpacing: 1),
          ),
        ),
      ],
    );
  }

  String _formatLastUsed(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return 'just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  void _handleRecentConnect(RecentConnection rc) {
    final conn = context.read<ConnectionProvider>();
    setState(() => _lastError = null);
    conn.connect(ConnectionOptions(
      tcpHost: rc.transportKind == 'TCP' ? rc.host : null,
      tcpPort: rc.port,
    ));
  }

  void _handleConnect() {
    final conn = context.read<ConnectionProvider>();
    setState(() => _lastError = null);
    conn.connect(ConnectionOptions(
      tcpHost: _autoDetect || _tcpHostController.text.isNotEmpty ? _tcpHostController.text : null,
      tcpPort: _autoDetect || _tcpPortController.text.isNotEmpty ? int.tryParse(_tcpPortController.text) ?? 4403 : null,
      serialPort: _autoDetect || _serialPortController.text.isNotEmpty ? _serialPortController.text : null,
      bleDeviceId: _bleIdController.text.isNotEmpty ? _bleIdController.text : null,
    ));
  }

  void _handleDisconnect() {
    final conn = context.read<ConnectionProvider>();
    conn.disconnect();
  }

  void _handleStartRuView() {
    final conn = context.read<ConnectionProvider>();
    conn.startRuView(
      host: _ruviewHostController.text,
      port: int.tryParse(_ruviewPortController.text) ?? 3001,
    );
  }

  void _handleStopRuView() {
    final conn = context.read<ConnectionProvider>();
    conn.stopRuView();
  }
}