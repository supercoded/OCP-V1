import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';
import '../models/app_settings.dart';
import '../providers/connection_provider.dart';
import '../providers/settings_provider.dart';
import '../providers/spectrum_provider.dart';
import '../widgets/analog_button.dart';
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
    final settings = context.watch<SettingsProvider>().settings;

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
                            Expanded(child: _buildLeftColumn(context, conn, settings)),
                            const SizedBox(width: 16),
                            Expanded(child: _buildRightColumn(context, conn)),
                          ],
                        )
                      : Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLeftColumn(context, conn, settings),
                            const SizedBox(height: 16),
                            _buildRightColumn(context, conn),
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

  Widget _buildLeftColumn(BuildContext context, ConnectionProvider conn, AppSettings settings) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSonarSection(context, settings),
        const SizedBox(height: 16),
        _buildMeshtasticSection(context, settings),
        const SizedBox(height: 16),
        _buildRtlSdrSection(context, settings),
        const SizedBox(height: 16),
        _buildRuViewSection(context, settings),
      ],
    );
  }

  Widget _buildRightColumn(BuildContext context, ConnectionProvider conn) {
    final settings = context.watch<SettingsProvider>().settings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSpectrumSection(context, settings),
        const SizedBox(height: 16),
        _buildConnectionStatus(context, conn),
        const SizedBox(height: 16),
        _buildExternalTools(context),
      ],
    );
  }

  // ── Sonar Settings ──────────────────────────────────────────────────

  Widget _buildSonarSection(BuildContext context, AppSettings settings) {
    final prov = context.read<SettingsProvider>();
    return _buildPanel('Sonar', [
      _buildSliderRow(
        label: 'Range',
        value: settings.sonarRangeKm,
        min: 1,
        max: 100,
        divisions: 99,
        unit: 'km',
        onChanged: (v) => prov.updateSonarRange(v),
      ),
      const SizedBox(height: 8),
      _buildSliderRow(
        label: 'Sweep Speed',
        value: settings.sonarSweepSpeed,
        min: 1,
        max: 10,
        divisions: 18,
        unit: 's/rev',
        onChanged: (v) => prov.updateSweepSpeed(v),
      ),
    ]);
  }

  // ── Meshtastic Settings ─────────────────────────────────────────────

  Widget _buildMeshtasticSection(BuildContext context, AppSettings settings) {
    final prov = context.read<SettingsProvider>();
    final hostCtrl = TextEditingController(text: settings.meshtasticHost);
    final portCtrl = TextEditingController(text: settings.meshtasticPort.toString());
    return _buildPanel('Meshtastic', [
      Row(
        children: [
          Expanded(child: _buildTextField('Host', hostCtrl, onChanged: (v) => prov.updateMeshtasticHost(v))),
          const SizedBox(width: 12),
          Expanded(child: _buildTextField('Port', portCtrl, onChanged: (v) {
            final p = int.tryParse(v);
            if (p != null) prov.updateMeshtasticPort(p);
          })),
        ],
      ),
    ]);
  }

  // ── RTL-SDR Settings ────────────────────────────────────────────────

  Widget _buildRtlSdrSection(BuildContext context, AppSettings settings) {
    final prov = context.read<SettingsProvider>();
    final hostCtrl = TextEditingController(text: settings.rtlSdrHost);
    final portCtrl = TextEditingController(text: settings.rtlSdrPort.toString());
    return _buildPanel('RTL-SDR', [
      Row(
        children: [
          Expanded(child: _buildTextField('Host', hostCtrl, onChanged: (v) => prov.updateRtlSdrHost(v))),
          const SizedBox(width: 12),
          Expanded(child: _buildTextField('Port', portCtrl, onChanged: (v) {
            final p = int.tryParse(v);
            if (p != null) prov.updateRtlSdrPort(p);
          })),
        ],
      ),
      const SizedBox(height: 8),
      _buildSliderRow(
        label: 'Center Freq',
        value: settings.rtlSdrCenterFreq,
        min: 24,
        max: 1766,
        divisions: 1742,
        unit: 'MHz',
        decimals: 3,
        onChanged: (v) => prov.updateRtlSdrCenterFreq(v),
      ),
      const SizedBox(height: 8),
      _buildSliderRow(
        label: 'Gain',
        value: settings.rtlSdrGain,
        min: 0,
        max: 49.6,
        divisions: 496,
        unit: 'dB',
        decimals: 1,
        onChanged: (v) => prov.updateRtlSdrGain(v),
      ),
      const SizedBox(height: 8),
      _buildGainModeToggle(context, settings, prov),
    ]);
  }

  Widget _buildGainModeToggle(BuildContext context, AppSettings settings, SettingsProvider prov) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        const Text('Gain Mode', style: TextStyle(fontSize: 12, color: OcpColors.ocpText)),
        Row(
          children: ['auto', 'manual'].map((mode) {
            final isActive = settings.rtlSdrGainMode == mode;
            return Padding(
              padding: const EdgeInsets.only(left: 6),
              child: GestureDetector(
                onTap: () => prov.updateRtlSdrGainMode(mode),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isActive ? OcpColors.ocpAccent : Colors.transparent,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(
                      color: isActive ? OcpColors.ocpAccent : OcpColors.ocpBorder,
                    ),
                  ),
                  child: Text(
                    mode.toUpperCase(),
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                      color: isActive ? OcpColors.ocpBg : OcpColors.ocpTextMuted,
                    ),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ── RuView Settings ─────────────────────────────────────────────────

  Widget _buildRuViewSection(BuildContext context, AppSettings settings) {
    final prov = context.read<SettingsProvider>();
    final hostCtrl = TextEditingController(text: settings.ruViewHost);
    final portCtrl = TextEditingController(text: settings.ruViewPort.toString());
    return _buildPanel('RuView', [
      Row(
        children: [
          Expanded(child: _buildTextField('Host', hostCtrl, onChanged: (v) => prov.updateRuViewHost(v))),
          const SizedBox(width: 12),
          Expanded(child: _buildTextField('Port', portCtrl, onChanged: (v) {
            final p = int.tryParse(v);
            if (p != null) prov.updateRuViewPort(p);
          })),
        ],
      ),
    ]);
  }

  // ── Spectrum Settings ────────────────────────────────────────────────

  Widget _buildSpectrumSection(BuildContext context, AppSettings settings) {
    final prov = context.read<SettingsProvider>();
    return _buildPanel('Spectrum', [
      _buildToggle('Peak Hold', settings.peakHoldEnabled, (v) => prov.updatePeakHoldEnabled(v)),
      const SizedBox(height: 8),
      _buildToggle('VFO', settings.vfoEnabled, (v) => prov.updateVfoEnabled(v)),
      if (settings.vfoEnabled) ...[
        const SizedBox(height: 8),
        _buildSliderRow(
          label: 'VFO Freq',
          value: settings.vfoFreq,
          min: 24,
          max: 1766,
          divisions: 1742,
          unit: 'MHz',
          decimals: 3,
          onChanged: (v) => prov.updateVfoFreq(v),
        ),
        const SizedBox(height: 8),
        _buildSliderRow(
          label: 'VFO BW',
          value: settings.vfoBandwidth,
          min: 1,
          max: 200,
          divisions: 199,
          unit: 'kHz',
          decimals: 1,
          onChanged: (v) => prov.updateVfoBandwidth(v),
        ),
      ],
    ]);
  }

  // ── Connection Status ───────────────────────────────────────────────

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

  // ── External Tools ──────────────────────────────────────────────────

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

  // ── About ──────────────────────────────────────────────────────────

  Widget _buildAbout(BuildContext context) {
    final prov = context.read<SettingsProvider>();
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
      const SizedBox(height: 12),
      // Reset to defaults
      AnalogButton(
        onPressed: () {
          prov.resetToDefaults();
        },
        child: const Text(
          'RESET TO DEFAULTS',
          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 1, color: OcpColors.ocpBg),
        ),
      ),
    ]);
  }

  // ── Reusable builders ───────────────────────────────────────────────

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

  Widget _buildSliderRow({
    required String label,
    required double value,
    required double min,
    required double max,
    required int divisions,
    required String unit,
    int decimals = 1,
    required ValueChanged<double> onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontSize: 12, color: OcpColors.ocpText)),
            Text(
              '${value.toStringAsFixed(decimals)} $unit',
              style: const TextStyle(fontSize: 11, fontFamily: 'JetBrainsMono', color: OcpColors.ocpAccent),
            ),
          ],
        ),
        SliderTheme(
          data: SliderThemeData(
            activeTrackColor: OcpColors.ocpAccent,
            inactiveTrackColor: OcpColors.ocpBorder,
            thumbColor: OcpColors.ocpAccent,
            overlayColor: OcpColors.ocpAccent.withAlpha(26),
            trackHeight: 3,
          ),
          child: Slider(
            value: value.clamp(min, max),
            min: min,
            max: max,
            divisions: divisions > 0 ? divisions : null,
            onChanged: onChanged,
          ),
        ),
      ],
    );
  }

  Widget _buildTextField(String label, TextEditingController controller, {String? hint, ValueChanged<String>? onChanged}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label.toUpperCase(),
          style: const TextStyle(fontSize: 9, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: OcpColors.ocpTextMuted),
        ),
        const SizedBox(height: 4),
        TextField(
          controller: controller,
          onChanged: onChanged,
          style: const TextStyle(fontSize: 12, fontFamily: 'JetBrainsMono', color: OcpColors.ocpText),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(color: OcpColors.ocpTextMuted.withAlpha(128), fontSize: 12),
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
              borderSide: const BorderSide(color: OcpColors.ocpAccent),
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
              color: value ? OcpColors.ocpAccent : OcpColors.ocpPanel2,
              borderRadius: BorderRadius.circular(11),
              border: Border.all(color: value ? OcpColors.ocpAccent : OcpColors.ocpBorder),
            ),
            child: AnimatedAlign(
              duration: const Duration(milliseconds: 150),
              alignment: value ? Alignment.centerRight : Alignment.centerLeft,
              child: Container(
                width: 16,
                height: 16,
                margin: const EdgeInsets.symmetric(horizontal: 3),
                decoration: BoxDecoration(
                  color: value ? OcpColors.ocpBg : OcpColors.ocpTextMuted,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ),
        ),
      ],
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