import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:ocp_flutter_core/theme/ocp_colors.dart';
import '../models/baofeng_channel.dart';

/// Offline Baofeng channel memory editor (CSV import/export).
/// Serial read/write is desktop-first; mobile edits locally until USB OTG is wired.
class BaofengChannelEditor extends StatefulWidget {
  const BaofengChannelEditor({super.key});

  @override
  State<BaofengChannelEditor> createState() => _BaofengChannelEditorState();
}

class _BaofengChannelEditorState extends State<BaofengChannelEditor> {
  late List<ChannelData> _channels;
  int _selected = 0;
  String? _status;

  @override
  void initState() {
    super.initState();
    _channels = createDefaultChannels();
  }

  ChannelData get _current => _channels[_selected];

  void _updateCurrent(ChannelData next) {
    setState(() {
      _channels[_selected] = next;
      _status = null;
    });
  }

  Future<void> _exportCsv() async {
    final csv = channelsToCsv(_channels);
    await Clipboard.setData(ClipboardData(text: csv));
    setState(() => _status = 'CSV copied to clipboard (${_channels.length} channels)');
  }

  Future<void> _importCsv() async {
    final controller = TextEditingController();
    try {
      final imported = await showDialog<String>(
        context: context,
        builder: (ctx) => AlertDialog(
          backgroundColor: OcpColors.ocpPanel,
          title: const Text('Import CSV', style: TextStyle(color: OcpColors.ocpBright, fontSize: 14)),
          content: TextField(
            controller: controller,
            maxLines: 8,
            style: const TextStyle(fontFamily: 'JetBrainsMono', fontSize: 11, color: OcpColors.ocpText),
            decoration: const InputDecoration(
              hintText: 'Paste CHIRP-style CSV here...',
              hintStyle: TextStyle(color: OcpColors.ocpMuted),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel', style: TextStyle(color: OcpColors.ocpDim)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, controller.text),
              child: const Text('Import', style: TextStyle(color: OcpColors.ocpCyan)),
            ),
          ],
        ),
      );
      if (imported == null || imported.trim().isEmpty) return;
      final parsed = channelsFromCsv(imported);
      if (parsed.isEmpty) {
        setState(() => _status = 'Import failed — no valid channel rows');
        return;
      }
      setState(() {
        final next = createDefaultChannels();
        for (final ch in parsed) {
          next[ch.index] = ch;
        }
        _channels = next;
        _status = 'Imported ${parsed.length} channels';
      });
    } finally {
      controller.dispose();
    }
  }

  List<String> get _toneLabels {
    if (_current.toneMode == 'CTCSS') {
      return List.generate(ctcssTones.length, (i) => '${ctcssTones[i].toStringAsFixed(1)} Hz');
    }
    if (_current.toneMode == 'DCS') {
      return List.generate(dcsCodes.length, (i) => 'D${dcsCodes[i].toString().padLeft(3, '0')}');
    }
    return const ['—'];
  }

  int get _toneOptionCount {
    if (_current.toneMode == 'CTCSS') return ctcssTones.length;
    if (_current.toneMode == 'DCS') return dcsCodes.length;
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    final warnings = validateChannel(_current);
    final toneEnabled = _current.toneMode != 'None';
    final toneCount = _toneOptionCount;
    final rxTone = _current.rxToneCode.clamp(0, toneCount - 1);
    final txTone = _current.txToneCode.clamp(0, toneCount - 1);
    final labels = _toneLabels;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Icon(Icons.radio, size: 18, color: OcpColors.ocpAmber),
            const SizedBox(width: 8),
            const Expanded(
              child: Text(
                'Channel memory editor (offline CSV). Serial read/write stays on desktop for now.',
                style: TextStyle(fontSize: 11, color: OcpColors.ocpDim, height: 1.3),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            _actionBtn('Import CSV', Icons.upload, _importCsv),
            const SizedBox(width: 8),
            _actionBtn('Copy CSV', Icons.copy, _exportCsv),
          ],
        ),
        if (_status != null) ...[
          const SizedBox(height: 8),
          Text(_status!, style: const TextStyle(fontSize: 10, fontFamily: 'JetBrainsMono', color: OcpColors.ocpCyan)),
        ],
        const SizedBox(height: 12),
        SizedBox(
          height: 160,
          child: ListView.builder(
            itemCount: 128,
            itemBuilder: (context, i) {
              final ch = _channels[i];
              final active = i == _selected;
              final filled = ch.rxFreq > 0;
              return InkWell(
                onTap: () => setState(() => _selected = i),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                  color: active ? OcpColors.ocpPanel2 : Colors.transparent,
                  child: Row(
                    children: [
                      SizedBox(
                        width: 36,
                        child: Text(
                          'CH${(i + 1).toString().padLeft(3, '0')}',
                          style: TextStyle(
                            fontSize: 10,
                            fontFamily: 'JetBrainsMono',
                            color: active ? OcpColors.ocpCyan : OcpColors.ocpDim,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Text(
                          filled
                              ? '${ch.rxFreq.toStringAsFixed(3)}  ${ch.name.isEmpty ? '' : ch.name}'
                              : '— empty —',
                          style: TextStyle(
                            fontSize: 11,
                            fontFamily: 'JetBrainsMono',
                            color: filled ? OcpColors.ocpText : OcpColors.ocpMuted,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      if (filled)
                        Text(
                          ch.power[0],
                          style: const TextStyle(fontSize: 10, fontFamily: 'JetBrainsMono', color: OcpColors.ocpAmber),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'EDIT CH${(_selected + 1).toString().padLeft(3, '0')}',
          style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700, letterSpacing: 1.2, color: OcpColors.ocpDim),
        ),
        const SizedBox(height: 8),
        _numField('RX MHz', _current.rxFreq, (v) => _updateCurrent(_current.copyWith(rxFreq: v))),
        const SizedBox(height: 8),
        _numField('TX MHz', _current.txFreq, (v) => _updateCurrent(_current.copyWith(txFreq: v))),
        const SizedBox(height: 8),
        _textField(
          'Name',
          _current.name,
          (v) => _updateCurrent(_current.copyWith(name: v.length > 7 ? v.substring(0, 7) : v)),
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(child: _dropdown('Duplex', duplexModes, _current.duplex, (v) => _updateCurrent(_current.copyWith(duplex: v)))),
            const SizedBox(width: 8),
            Expanded(child: _dropdown('Power', powerLevels, _current.power, (v) => _updateCurrent(_current.copyWith(power: v)))),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _dropdown('Tone', toneModes, _current.toneMode, (v) {
                _updateCurrent(_current.copyWith(toneMode: v, rxToneCode: 0, txToneCode: 0));
              }),
            ),
            const SizedBox(width: 8),
            Expanded(child: _dropdown('BW', bandwidthOptions, _current.bandwidth, (v) => _updateCurrent(_current.copyWith(bandwidth: v)))),
          ],
        ),
        if (toneEnabled) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _dropdown(
                  'RX Tone',
                  labels,
                  labels[rxTone],
                  (v) {
                    final idx = labels.indexOf(v);
                    if (idx >= 0) _updateCurrent(_current.copyWith(rxToneCode: idx));
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _dropdown(
                  'TX Tone',
                  labels,
                  labels[txTone],
                  (v) {
                    final idx = labels.indexOf(v);
                    if (idx >= 0) _updateCurrent(_current.copyWith(txToneCode: idx));
                  },
                ),
              ),
            ],
          ),
        ],
        if (warnings.isNotEmpty) ...[
          const SizedBox(height: 8),
          ...warnings.map(
            (w) => Text(w, style: const TextStyle(fontSize: 10, color: OcpColors.ocpAmber, height: 1.3)),
          ),
        ],
      ],
    );
  }

  Widget _actionBtn(String label, IconData icon, VoidCallback onTap) {
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 8),
          decoration: BoxDecoration(
            color: OcpColors.ocpPanel2,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: OcpColors.ocpBorder),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 14, color: OcpColors.ocpBright),
              const SizedBox(width: 6),
              Text(label, style: const TextStyle(fontSize: 11, color: OcpColors.ocpText)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _numField(String label, double value, ValueChanged<double> onChanged) {
    return _textField(
      label,
      value > 0 ? value.toStringAsFixed(3) : '',
      (raw) => onChanged(double.tryParse(raw) ?? 0),
      keyboard: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _textField(String label, String value, ValueChanged<String> onChanged, {TextInputType? keyboard}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, letterSpacing: 1.2, color: OcpColors.ocpDim)),
        const SizedBox(height: 4),
        TextFormField(
          key: ValueKey('$label-$_selected-$value'),
          initialValue: value,
          keyboardType: keyboard,
          style: const TextStyle(fontSize: 12, fontFamily: 'JetBrainsMono', color: OcpColors.ocpText),
          onChanged: onChanged,
          decoration: InputDecoration(
            isDense: true,
            filled: true,
            fillColor: OcpColors.ocpBg,
            contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: OcpColors.ocpBorder)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(4), borderSide: const BorderSide(color: OcpColors.ocpBorder)),
          ),
        ),
      ],
    );
  }

  Widget _dropdown(String label, List<String> items, String value, ValueChanged<String> onChanged) {
    final safeValue = items.contains(value) ? value : items.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label.toUpperCase(), style: const TextStyle(fontSize: 9, letterSpacing: 1.2, color: OcpColors.ocpDim)),
        const SizedBox(height: 4),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8),
          decoration: BoxDecoration(
            color: OcpColors.ocpBg,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: OcpColors.ocpBorder),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: safeValue,
              isExpanded: true,
              dropdownColor: OcpColors.ocpPanel2,
              style: const TextStyle(fontSize: 12, fontFamily: 'JetBrainsMono', color: OcpColors.ocpText),
              items: items.map((e) => DropdownMenuItem(value: e, child: Text(e))).toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
