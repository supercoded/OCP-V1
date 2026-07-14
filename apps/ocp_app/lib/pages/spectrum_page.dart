import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';
import '../providers/spectrum_provider.dart';
import '../providers/connection_provider.dart';
import '../models/bookmark.dart';
import '../widgets/status_lamp.dart';
import '../widgets/analog_button.dart';

class SpectrumPage extends StatefulWidget {
  const SpectrumPage({super.key});

  @override
  State<SpectrumPage> createState() => _SpectrumPageState();
}

class _SpectrumPageState extends State<SpectrumPage> {
  // Form controllers
  final _hostController = TextEditingController(text: 'localhost');
  final _portController = TextEditingController(text: '1234');
  final _centerFreqController = TextEditingController(text: '100.000');
  final _gainValueController = TextEditingController(text: '0.0');

  // Bookmark form
  final _bmLabelController = TextEditingController();
  final _bmFreqController = TextEditingController();
  final _bmBwController = TextEditingController(text: '12.5');
  final _bmModController = TextEditingController(text: 'FM');

  bool _showBookmarkForm = false;
  int? _editingBookmarkIndex;

  @override
  void dispose() {
    _hostController.dispose();
    _portController.dispose();
    _centerFreqController.dispose();
    _gainValueController.dispose();
    _bmLabelController.dispose();
    _bmFreqController.dispose();
    _bmBwController.dispose();
    _bmModController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final spectrum = context.watch<SpectrumProvider>();
    final conn = context.watch<ConnectionProvider>();

    return Padding(
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'SPECTRUM',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 2,
                  color: OcpColors.ocpBright,
                ),
              ),
              Row(
                children: [
                  // Recording indicator
                  if (spectrum.isRecording) ...[
                    Container(
                      width: 10,
                      height: 10,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'REC ${_formatDuration(spectrum.recordingDuration)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontFamily: 'JetBrainsMono',
                        color: Colors.red,
                      ),
                    ),
                    const SizedBox(width: 12),
                  ],
                  StatusLamp(connected: spectrum.rtlConnected),
                  const SizedBox(width: 8),
                  Text(
                    spectrum.rtlConnected
                        ? '${spectrum.centerFreqMHz.toStringAsFixed(3)} MHz · ${(spectrum.sampleRate / 1e6).toStringAsFixed(3)} MSPS · ${spectrum.fftSize} bins'
                        : 'No source',
                    style: const TextStyle(
                      fontSize: 11,
                      fontFamily: 'JetBrainsMono',
                      color: OcpColors.ocpDim,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Main content: spectrum + waterfall on left, controls on right
          Expanded(
            child: LayoutBuilder(
              builder: (context, constraints) {
                final wide = constraints.maxWidth > 900;
                return wide
                    ? Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(child: _buildSpectrumArea(spectrum)),
                          const SizedBox(width: 12),
                          SizedBox(width: 280, child: _buildControls(spectrum, conn)),
                        ],
                      )
                    : Column(
                        children: [
                          Expanded(child: _buildSpectrumArea(spectrum)),
                          const SizedBox(height: 12),
                          SizedBox(
                            height: 300,
                            child: SingleChildScrollView(child: _buildControls(spectrum, conn)),
                          ),
                        ],
                      );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSpectrumArea(SpectrumProvider spectrum) {
    return Column(
      children: [
        // Spectrum FFT
        Expanded(
          flex: 3,
          child: GestureDetector(
            onTapUp: (details) => _handleSpectrumTap(details, spectrum),
            child: Container(
              decoration: BoxDecoration(
                color: OcpColors.ocpPanel,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: OcpColors.ocpBorder),
              ),
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: CustomPaint(
                      painter: SpectrumPainter(spectrum),
                      size: Size.infinite,
                    ),
                  ),
                  if (spectrum.showVfo)
                    Positioned(
                      bottom: 4,
                      right: 8,
                      child: Text(
                        'Click to set VFO',
                        style: TextStyle(
                          fontSize: 9,
                          fontFamily: 'JetBrainsMono',
                          color: OcpColors.ocpDim.withAlpha(153),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Waterfall
        Expanded(
          flex: 2,
          child: Container(
            decoration: BoxDecoration(
              color: OcpColors.ocpPanel,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: OcpColors.ocpBorder),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: CustomPaint(
                painter: WaterfallPainter(spectrum),
                size: Size.infinite,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildControls(SpectrumProvider spectrum, ConnectionProvider conn) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // RTL Source
          _buildControlPanel('rtl_tcp Source', [
            _buildField('Host', _hostController),
            const SizedBox(height: 8),
            _buildField('Port', _portController),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: AnalogButton(
                    onPressed: spectrum.rtlConnected ? () {} : _handleConnectRtl,
                    child: Text(
                      'Connect',
                      style: TextStyle(fontSize: 11, color: spectrum.rtlConnected ? OcpColors.ocpBg.withAlpha(128) : OcpColors.ocpBg),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: AnalogButton(
                    onPressed: spectrum.rtlConnected ? _handleDisconnectRtl : () {},
                    child: Text(
                      'Disconnect',
                      style: TextStyle(fontSize: 11, color: spectrum.rtlConnected ? OcpColors.ocpBg : OcpColors.ocpBg.withAlpha(128)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Run rtl_tcp -a 0.0.0.0 -p 1234 on the host, then connect.',
              style: TextStyle(fontSize: 10, color: OcpColors.ocpDim, height: 1.4),
            ),
          ]),
          const SizedBox(height: 8),
          // Mock Source
          _buildControlPanel('Mock Source', [
            const Text(
              'For UI testing without an RTL-SDR dongle.',
              style: TextStyle(fontSize: 10, color: OcpColors.ocpDim, height: 1.4),
            ),
            const SizedBox(height: 8),
            AnalogButton(
              onPressed: spectrum.rtlConnected ? () {} : _handleStartMock,
              child: Text(
                'Start Mock Signal',
                style: TextStyle(fontSize: 11, color: spectrum.rtlConnected ? OcpColors.ocpBg.withAlpha(128) : OcpColors.ocpBg),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          // Receiver settings
          _buildControlPanel('Receiver Settings', [
            _buildField('Center Freq (MHz)', _centerFreqController),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: AnalogButton(onPressed: _handleApplyFreq, child: const Text('Set Freq', style: TextStyle(fontSize: 11)))),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildDropdown(
                    value: spectrum.gainMode,
                    items: const ['auto', 'manual'],
                    onChanged: (v) => spectrum.setGainMode(v ?? 'auto'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(child: _buildField('Gain dB', _gainValueController)),
              ],
            ),
            const SizedBox(height: 8),
            AnalogButton(onPressed: _handleApplyGain, child: const Text('Set Gain', style: TextStyle(fontSize: 11))),
          ]),
          const SizedBox(height: 8),
          // Display controls
          _buildControlPanel('Display', [
            _buildToggle('Peak Hold', spectrum.peakHoldEnabled, (v) => spectrum.setPeakHoldEnabled(v)),
            const SizedBox(height: 6),
            _buildToggle('VFO Band', spectrum.showVfo, (v) => spectrum.setShowVfo(v)),
          ]),
          const SizedBox(height: 8),
          // VFO readout
          if (spectrum.showVfo)
            _buildControlPanel('VFO', [
              _buildStatusRow('Center', '${spectrum.vfoFreqMHz.toStringAsFixed(3)} MHz'),
              _buildStatusRow('Bandwidth', '${(spectrum.vfoBandwidthHz / 1000).toStringAsFixed(1)} kHz'),
            ]),
          const SizedBox(height: 8),
          // Recording
          _buildControlPanel('I/Q Recording', [
            const Text(
              'Capture raw I/Q data to ~/ocp-recordings/',
              style: TextStyle(fontSize: 10, color: OcpColors.ocpDim, height: 1.4),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: AnalogButton(
                onPressed: spectrum.rtlConnected ? _handleToggleRecording : () {},
                child: Text(
                  spectrum.isRecording ? '■ Stop Recording' : '● Start Recording',
                  style: TextStyle(
                    fontSize: 11,
                    color: spectrum.isRecording ? OcpColors.ocpRed : (spectrum.rtlConnected ? OcpColors.ocpBg : OcpColors.ocpBg.withAlpha(128)),
                  ),
                ),
              ),
            ),
          ]),
          const SizedBox(height: 8),
          // Bookmarks
          _buildBookmarksPanel(spectrum),
          // RTL error
          if (spectrum.rtlError != null) ...[
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: OcpColors.ocpRed.withAlpha(26),
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: OcpColors.ocpRed.withAlpha(77)),
              ),
              child: Text(
                spectrum.rtlError!,
                style: const TextStyle(fontSize: 11, fontFamily: 'JetBrainsMono', color: OcpColors.ocpRed),
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildControlPanel(String title, List<Widget> children) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OcpColors.ocpPanel,
        borderRadius: BorderRadius.circular(4),
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
          const SizedBox(height: 8),
          ...children,
        ],
      ),
    );
  }

  Widget _buildField(String label, TextEditingController controller) {
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
            filled: true,
            fillColor: OcpColors.ocpBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
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

  Widget _buildDropdown({required String value, required List<String> items, required ValueChanged<String?> onChanged}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: OcpColors.ocpBg,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: OcpColors.ocpBorder),
      ),
      child: DropdownButton<String>(
        value: value,
        items: items.map((e) => DropdownMenuItem(value: e, child: Text(e, style: const TextStyle(fontSize: 12, fontFamily: 'JetBrainsMono', color: OcpColors.ocpText)))).toList(),
        onChanged: onChanged,
        underline: const SizedBox.shrink(),
        isExpanded: true,
        style: const TextStyle(fontSize: 12, fontFamily: 'JetBrainsMono', color: OcpColors.ocpText),
        dropdownColor: OcpColors.ocpPanel2,
      ),
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
    );
  }

  Widget _buildStatusRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontFamily: 'JetBrainsMono', color: OcpColors.ocpDim)),
          Text(value, style: const TextStyle(fontSize: 11, fontFamily: 'JetBrainsMono', color: OcpColors.ocpCyan)),
        ],
      ),
    );
  }

  Widget _buildBookmarksPanel(SpectrumProvider spectrum) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: OcpColors.ocpPanel,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: OcpColors.ocpBorder),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'BOOKMARKS',
                style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: OcpColors.ocpDim),
              ),
              GestureDetector(
                onTap: () => setState(() {
                  _showBookmarkForm = !_showBookmarkForm;
                  _editingBookmarkIndex = null;
                  _bmLabelController.clear();
                  _bmFreqController.clear();
                  _bmBwController.text = '12.5';
                  _bmModController.text = 'FM';
                }),
                child: const Text(
                  '+ Add',
                  style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: OcpColors.ocpBright),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Bookmark form
          if (_showBookmarkForm) ...[
            _buildField('Label', _bmLabelController),
            const SizedBox(height: 6),
            _buildField('Freq (MHz)', _bmFreqController),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(child: _buildField('BW (kHz)', _bmBwController)),
                const SizedBox(width: 8),
                Expanded(child: _buildField('Mod', _bmModController)),
              ],
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                AnalogButton(
                  onPressed: _handleSaveBookmark,
                  child: const Text('Save', style: TextStyle(fontSize: 11)),
                ),
                const SizedBox(width: 8),
                GestureDetector(
                  onTap: () => setState(() => _showBookmarkForm = false),
                  child: const Text('Cancel', style: TextStyle(fontSize: 11, color: OcpColors.ocpDim)),
                ),
              ],
            ),
            const SizedBox(height: 8),
          ],
          // Bookmark list
          if (spectrum.bookmarks.isEmpty)
            const Text('No bookmarks yet', style: TextStyle(fontSize: 10, color: OcpColors.ocpDim))
          else
            ...spectrum.bookmarks.asMap().entries.map((entry) {
              final i = entry.key;
              final bm = entry.value;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 2),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => _handleTuneToBookmark(bm, spectrum),
                      child: Text(
                        bm.label,
                        style: const TextStyle(fontSize: 11, color: OcpColors.ocpBright),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${bm.frequency.toStringAsFixed(3)} MHz',
                      style: const TextStyle(fontSize: 10, fontFamily: 'JetBrainsMono', color: OcpColors.ocpCyan),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      bm.modulation,
                      style: const TextStyle(fontSize: 10, fontFamily: 'JetBrainsMono', color: OcpColors.ocpDim),
                    ),
                    const SizedBox(width: 4),
                    GestureDetector(
                      onTap: () => spectrum.removeBookmarkAt(i),
                      child: const Icon(Icons.close, size: 12, color: OcpColors.ocpRed),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }

  void _handleSpectrumTap(TapUpDetails details, SpectrumProvider spectrum) {
    if (!spectrum.showVfo || spectrum.spectrumData.isEmpty) return;
    // Calculate frequency from tap position
    final RenderBox box = context.findRenderObject() as RenderBox;
    final localPos = details.localPosition;
    final fraction = localPos.dx / box.size.width;
    final startFreq = spectrum.centerFreqHz - spectrum.sampleRate / 2;
    final clickFreq = startFreq + fraction * spectrum.sampleRate;
    spectrum.setVfoFreq(clickFreq);
  }

  void _handleConnectRtl() {
    final spectrum = context.read<SpectrumProvider>();
    spectrum.setRtlHost(_hostController.text);
    spectrum.setRtlPort(int.tryParse(_portController.text) ?? 1234);
    spectrum.setCenterFreqMHz(double.tryParse(_centerFreqController.text) ?? 100.0);
    spectrum.connectRtl();
  }

  void _handleDisconnectRtl() {
    context.read<SpectrumProvider>().disconnectRtl();
  }

  void _handleStartMock() {
    final spectrum = context.read<SpectrumProvider>();
    spectrum.setCenterFreqMHz(double.tryParse(_centerFreqController.text) ?? 100.0);
    spectrum.startMockSource();
  }

  void _handleApplyFreq() {
    final spectrum = context.read<SpectrumProvider>();
    final mHz = double.tryParse(_centerFreqController.text) ?? 100.0;
    spectrum.setCenterFreqMHz(mHz);
    spectrum.setVfoFreq(mHz * 1e6);
  }

  void _handleApplyGain() {
    final spectrum = context.read<SpectrumProvider>();
    spectrum.setGainValue(double.tryParse(_gainValueController.text) ?? 0.0);
  }

  void _handleToggleRecording() {
    final spectrum = context.read<SpectrumProvider>();
    if (spectrum.isRecording) {
      spectrum.stopRecording();
    } else {
      spectrum.startRecording();
    }
  }

  void _handleTuneToBookmark(Bookmark bm, SpectrumProvider spectrum) {
    spectrum.setCenterFreqMHz(bm.frequency);
    spectrum.setVfoFreq(bm.frequencyHz);
    _centerFreqController.text = bm.frequency.toStringAsFixed(3);
  }

  void _handleSaveBookmark() {
    final spectrum = context.read<SpectrumProvider>();
    final label = _bmLabelController.text.trim();
    final freq = double.tryParse(_bmFreqController.text);
    if (label.isEmpty || freq == null) return;

    final bookmark = Bookmark(
      label: label,
      frequency: freq,
      bandwidth: double.tryParse(_bmBwController.text) ?? 12.5,
      modulation: _bmModController.text.trim().isNotEmpty ? _bmModController.text.trim() : 'FM',
    );

    if (_editingBookmarkIndex != null) {
      spectrum.updateBookmark(_editingBookmarkIndex!, bookmark);
    } else {
      spectrum.addBookmark(bookmark);
    }

    setState(() {
      _showBookmarkForm = false;
      _editingBookmarkIndex = null;
    });
  }

  String _formatDuration(Duration d) {
    final m = d.inMinutes.toString().padLeft(2, '0');
    final s = (d.inSeconds % 60).toString().padLeft(2, '0');
    return '$m:$s';
  }
}

/// CustomPainter for the spectrum FFT display
class SpectrumPainter extends CustomPainter {
  final SpectrumProvider spectrum;

  SpectrumPainter(this.spectrum);

  @override
  void paint(Canvas canvas, Size size) {
    final data = spectrum.spectrumData;
    final peakData = spectrum.peakHoldEnabled ? spectrum.peakHoldData : <double>[];

    // Background
    final bgPaint = Paint()..color = OcpColors.ocpPanel;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bgPaint);

    // Grid lines
    final gridPaint = Paint()
      ..color = OcpColors.ocpBorder.withAlpha(77)
      ..strokeWidth = 0.5;
    for (int i = 1; i < 10; i++) {
      final y = size.height * i / 10;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }
    for (int i = 1; i < 10; i++) {
      final x = size.width * i / 10;
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), gridPaint);
    }

    if (data.isEmpty) {
      // Draw "no data" text
      final textPainter = TextPainter(
        text: const TextSpan(text: 'No source', style: TextStyle(color: OcpColors.ocpDim, fontSize: 14, fontFamily: 'JetBrainsMono')),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(canvas, Offset((size.width - textPainter.width) / 2, (size.height - textPainter.height) / 2));
      return;
    }

    // Find min/max for scaling
    const minDb = -120.0;
    const maxDb = -10.0;
    final dbRange = maxDb - minDb;

    // Draw peak hold
    if (spectrum.peakHoldEnabled && peakData.isNotEmpty) {
      final peakPath = Path();
      for (int i = 0; i < peakData.length; i++) {
        final x = (i / peakData.length) * size.width;
        final normalizedDb = (peakData[i] - minDb) / dbRange;
        final y = size.height - (normalizedDb * size.height).clamp(0, size.height);
        if (i == 0) {
          peakPath.moveTo(x, y);
        } else {
          peakPath.lineTo(x, y);
        }
      }
      final peakPaint = Paint()
        ..color = OcpColors.ocpAmber.withAlpha(77)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawPath(peakPath, peakPaint);
    }

    // Draw spectrum fill
    final fillPath = Path();
    fillPath.moveTo(0, size.height);
    for (int i = 0; i < data.length; i++) {
      final x = (i / data.length) * size.width;
      final normalizedDb = (data[i] - minDb) / dbRange;
      final y = size.height - (normalizedDb * size.height).clamp(0, size.height);
      fillPath.lineTo(x, y);
    }
    fillPath.lineTo(size.width, size.height);
    fillPath.close();

    final fillPaint = Paint()
      ..color = OcpColors.ocpBright.withAlpha(26)
      ..style = PaintingStyle.fill;
    canvas.drawPath(fillPath, fillPaint);

    // Draw spectrum line
    final linePath = Path();
    for (int i = 0; i < data.length; i++) {
      final x = (i / data.length) * size.width;
      final normalizedDb = (data[i] - minDb) / dbRange;
      final y = size.height - (normalizedDb * size.height).clamp(0, size.height);
      if (i == 0) {
        linePath.moveTo(x, y);
      } else {
        linePath.lineTo(x, y);
      }
    }

    final linePaint = Paint()
      ..color = OcpColors.ocpGreen
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    canvas.drawPath(linePath, linePaint);

    // Draw VFO indicator
    if (spectrum.showVfo && data.isNotEmpty) {
      final _binSize = spectrum.sampleRate / data.length;
      final startFreq = spectrum.centerFreqHz - spectrum.sampleRate / 2;

      final vfoCenterX = ((spectrum.vfoFreqHz - startFreq) / spectrum.sampleRate) * size.width;
      final vfoLeftX = ((spectrum.vfoFreqHz - spectrum.vfoBandwidthHz / 2 - startFreq) / spectrum.sampleRate) * size.width;
      final vfoRightX = ((spectrum.vfoFreqHz + spectrum.vfoBandwidthHz / 2 - startFreq) / spectrum.sampleRate) * size.width;

      // VFO band
      final vfoPaint = Paint()
        ..color = OcpColors.ocpCyan.withAlpha(26)
        ..style = PaintingStyle.fill;
      canvas.drawRect(
        Rect.fromLTWH(vfoLeftX, 0, vfoRightX - vfoLeftX, size.height),
        vfoPaint,
      );

      // VFO center line
      final vfoLinePaint = Paint()
        ..color = OcpColors.ocpCyan.withAlpha(153)
        ..strokeWidth = 1
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(vfoCenterX, 0), Offset(vfoCenterX, size.height), vfoLinePaint);
    }

    // Frequency labels at bottom
    final _labelPaint = Paint()..color = OcpColors.ocpDim.withAlpha(128);
    final freqTextStyle = TextStyle(color: OcpColors.ocpDim, fontSize: 9, fontFamily: 'JetBrainsMono');
    for (int i = 0; i <= 4; i++) {
      final fraction = i / 4;
      final freq = spectrum.centerFreqHz - spectrum.sampleRate / 2 + fraction * spectrum.sampleRate;
      final x = fraction * size.width;
      final label = '${(freq / 1e6).toStringAsFixed(1)}';
      final tp = TextPainter(text: TextSpan(text: label, style: freqTextStyle), textDirection: TextDirection.ltr);
      tp.layout();
      tp.paint(canvas, Offset(x + 2, size.height - tp.height - 2));
    }
  }

  @override
  bool shouldRepaint(covariant SpectrumPainter oldDelegate) {
    return oldDelegate.spectrum.spectrumData != spectrum.spectrumData ||
        oldDelegate.spectrum.peakHoldEnabled != spectrum.peakHoldEnabled ||
        oldDelegate.spectrum.showVfo != spectrum.showVfo;
  }
}

/// CustomPainter for the waterfall display
class WaterfallPainter extends CustomPainter {
  final SpectrumProvider spectrum;

  WaterfallPainter(this.spectrum);

  @override
  void paint(Canvas canvas, Size size) {
    final waterfall = spectrum.waterfallData;

    // Background
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), Paint()..color = OcpColors.ocpPanel);

    if (waterfall.isEmpty) {
      final tp = TextPainter(
        text: const TextSpan(text: 'No data', style: TextStyle(color: OcpColors.ocpDim, fontSize: 12, fontFamily: 'JetBrainsMono')),
        textDirection: TextDirection.ltr,
      );
      tp.layout();
      tp.paint(canvas, Offset((size.width - tp.width) / 2, (size.height - tp.height) / 2));
      return;
    }

    const minDb = -120.0;
    const maxDb = -10.0;
    final dbRange = maxDb - minDb;

    // Draw waterfall rows from bottom (newest) to top (oldest)
    final rowsToDraw = waterfall.length;
    final rowHeight = size.height / rowsToDraw;

    for (int row = 0; row < rowsToDraw; row++) {
      final data = waterfall[row];
      final binWidth = size.width / data.length;
      final y = size.height - (row + 1) * rowHeight;

      for (int bin = 0; bin < data.length; bin++) {
        final normalizedDb = ((data[bin] - minDb) / dbRange).clamp(0.0, 1.0);
        final color = _dbToColor(normalizedDb);
        canvas.drawRect(
          Rect.fromLTWH(bin * binWidth, y, binWidth + 1, rowHeight + 1),
          Paint()..color = color,
        );
      }
    }
  }

  Color _dbToColor(double normalized) {
    // Blue → Cyan → Green → Yellow → Red
    if (normalized < 0.25) {
      final t = normalized / 0.25;
      return Color.fromARGB(255, 0, (t * 128).round(), (128 + t * 127).round());
    } else if (normalized < 0.5) {
      final t = (normalized - 0.25) / 0.25;
      return Color.fromARGB(255, 0, (128 + t * 127).round(), (255 - t * 55).round());
    } else if (normalized < 0.75) {
      final t = (normalized - 0.5) / 0.25;
      return Color.fromARGB(255, (t * 255).round(), 255, (200 - t * 200).round());
    } else {
      final t = (normalized - 0.75) / 0.25;
      return Color.fromARGB(255, 255, (255 - t * 128).round(), 0);
    }
  }

  @override
  bool shouldRepaint(covariant WaterfallPainter oldDelegate) {
    return oldDelegate.spectrum.waterfallData != spectrum.waterfallData;
  }
}