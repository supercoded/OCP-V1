import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';
import '../providers/connection_provider.dart';
import '../widgets/status_lamp.dart';

const _appVersion = '0.1.0';
const _buildDate = '2026-07-12';

const _deps = [
  _DepInfo(
    name: 'esptool.py',
    purpose: 'Flash Meshtastic firmware to ESP32 boards',
    install: 'pip install esptool',
  ),
  _DepInfo(
    name: 'nrfutil',
    purpose: 'Flash Meshtastic firmware to nRF52 / RAK4631 boards',
    install: 'pip install nrfutil',
  ),
  _DepInfo(
    name: 'rtl_tcp / RTL-SDR drivers',
    purpose: 'Stream SDR spectrum data to OCP-V1',
    install: 'https://rtl-sdr.com/',
  ),
  _DepInfo(
    name: 'RuView Docker simulator',
    purpose: 'Through-wall presence/vitals sensing via Wi-Fi CSI',
    install: 'bash scripts/run-ruview-simulator.sh (Docker required)',
  ),
];

class _DepInfo {
  final String name;
  final String purpose;
  final String install;
  const _DepInfo({required this.name, required this.purpose, required this.install});
}

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    final conn = context.watch<ConnectionProvider>();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'SETTINGS',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              letterSpacing: 2,
              color: OcpColors.ocpAccent,
            ),
          ),
          const SizedBox(height: 20),
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final useGrid = constraints.maxWidth > 700;
                return SingleChildScrollView(
                  child: useGrid
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(child: _buildConnectionStatus(context, conn)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildExternalTools(context)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildConnectionStatus(context, conn),
                            const SizedBox(height: 16),
                            _buildExternalTools(context),
                          ],
                        ),
                );
              },
            ),
          ),
          const SizedBox(height: 16),
          _buildAbout(context),
        ],
      ),
    );
  }

  Widget _buildConnectionStatus(BuildContext context, ConnectionProvider conn) {
    return _buildPanel('Connection Status', [
      _buildStatusRow('Meshtastic connected', conn.connected ? 'YES' : 'NO', highlight: conn.connected),
      _buildStatusRow('Transport kind', conn.transportKind ?? '—'),
      _buildStatusRow('Mesh nodes', '${conn.nodeCount}'),
      _buildStatusRow('RuView connected', conn.ruViewConnected ? 'YES' : 'NO', highlight: conn.ruViewConnected),
      _buildStatusRow('RuView targets', '${conn.ruViewTargetCount}'),
      _buildStatusRow('RTL-SDR connected', conn.rtlConnected ? 'YES' : 'NO', highlight: conn.rtlConnected),
    ]);
  }

  Widget _buildExternalTools(BuildContext context) {
    return _buildPanel('External Tools', [
      ..._deps.map((d) => Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(d.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: OcpColors.ocpText)),
                    Text(d.purpose, style: const TextStyle(fontSize: 10, color: OcpColors.ocpTextMuted)),
                  ],
                ),
                const SizedBox(height: 4),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: OcpColors.ocpBg,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: OcpColors.ocpBorder),
                  ),
                  child: Text(d.install, style: const TextStyle(fontSize: 10, fontFamily: 'JetBrainsMono', color: OcpColors.ocpAccent)),
                ),
              ],
            ),
          )),
      const SizedBox(height: 12),
      const Text(
        'OCP-V1 does not bundle these tools because their licenses and architectures vary. '
        'The installer will prompt you to install missing tools on first run in a future update.',
        style: TextStyle(fontSize: 10, color: OcpColors.ocpTextMuted, height: 1.4),
      ),
    ]);
  }

  Widget _buildAbout(BuildContext context) {
    return _buildPanel('About', [
      _buildStatusRow('Version', _appVersion),
      _buildStatusRow('Build date', _buildDate),
      const SizedBox(height: 12),
      // Theme toggle (dark mode only for now)
      Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('Dark Mode', style: TextStyle(fontSize: 12, color: OcpColors.ocpText)),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: OcpColors.ocpAccent,
              borderRadius: BorderRadius.circular(4),
            ),
            child: const Text(
              'ON',
              style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: OcpColors.ocpBg),
            ),
          ),
        ],
      ),
      const SizedBox(height: 8),
      const Text(
        'Dark mode is the only supported theme. Light mode is planned for a future release.',
        style: TextStyle(fontSize: 10, color: OcpColors.ocpTextMuted, height: 1.4),
      ),
    ]);
  }

  Widget _buildPanel(String title, List<Widget> children) {
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
              color: OcpColors.ocpTextMuted,
            ),
          ),
          const SizedBox(height: 12),
          ...children,
        ],
      ),
    );
  }

  Widget _buildStatusRow(String label, String value, {bool highlight = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 12, fontFamily: 'JetBrainsMono', color: OcpColors.ocpTextMuted)),
          Text(
            value,
            style: TextStyle(
              fontSize: 12,
              fontFamily: 'JetBrainsMono',
              color: highlight ? OcpColors.ocpAccent : OcpColors.ocpText,
            ),
          ),
        ],
      ),
    );
  }
}