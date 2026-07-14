/// Baofeng UV-5RM channel data model and validation (Flutter port of desktop model).

const double vhfMin = 136;
const double vhfMax = 174;
const double uhfMin = 400;
const double uhfMax = 520;

const List<String> duplexModes = ['none', '+', '-', 'split'];
const List<String> toneModes = ['None', 'CTCSS', 'DCS'];
const List<String> powerLevels = ['High', 'Low'];
const List<String> bandwidthOptions = ['Wide', 'Narrow'];

const List<double> ctcssTones = [
  67.0, 69.3, 71.9, 74.4, 77.0, 79.7, 82.5, 85.4,
  88.5, 91.5, 94.8, 97.4, 100.0, 103.5, 107.2, 110.9,
  114.8, 118.8, 123.0, 127.3, 131.8, 136.5, 141.3, 146.2,
  151.4, 156.7, 159.8, 162.2, 165.5, 167.9, 171.3, 173.8,
  177.3, 179.9, 183.5, 186.2, 189.9, 192.8, 196.6, 199.5,
  203.5, 206.5, 210.7, 218.1, 225.7, 229.1, 233.6, 241.8,
  250.3, 254.1,
];

const List<int> dcsCodes = [
  23, 25, 26, 31, 32, 36, 43, 47, 51, 53, 54, 65, 71, 72, 73, 74,
  114, 115, 116, 122, 125, 131, 132, 134, 143, 144, 145, 152, 155, 156, 162, 165,
  172, 174, 205, 212, 223, 225, 226, 243, 244, 245, 246, 251, 252, 255, 261, 263,
  265, 266, 271, 274, 306, 311, 315, 325, 331, 332, 343, 346, 351, 356, 364, 365,
  371, 411, 412, 413, 423, 431, 432, 445, 446, 452, 454, 455, 462, 464, 465, 466,
  503, 506, 516, 523, 526, 532, 546, 565, 606, 612, 624, 627, 631, 632, 654, 662,
  664, 703, 712, 723, 731, 732, 734, 743, 754,
];

class ChannelData {
  final int index;
  double rxFreq;
  double txFreq;
  String duplex;
  String toneMode;
  int rxToneCode;
  int txToneCode;
  String power;
  String bandwidth;
  String name;

  ChannelData({
    required this.index,
    this.rxFreq = 0,
    this.txFreq = 0,
    this.duplex = 'none',
    this.toneMode = 'None',
    this.rxToneCode = 0,
    this.txToneCode = 0,
    this.power = 'High',
    this.bandwidth = 'Wide',
    this.name = '',
  });

  ChannelData copyWith({
    double? rxFreq,
    double? txFreq,
    String? duplex,
    String? toneMode,
    int? rxToneCode,
    int? txToneCode,
    String? power,
    String? bandwidth,
    String? name,
  }) {
    return ChannelData(
      index: index,
      rxFreq: rxFreq ?? this.rxFreq,
      txFreq: txFreq ?? this.txFreq,
      duplex: duplex ?? this.duplex,
      toneMode: toneMode ?? this.toneMode,
      rxToneCode: rxToneCode ?? this.rxToneCode,
      txToneCode: txToneCode ?? this.txToneCode,
      power: power ?? this.power,
      bandwidth: bandwidth ?? this.bandwidth,
      name: name ?? this.name,
    );
  }
}

String? validateFrequency(double freqMhz) {
  if (freqMhz == 0) return null;
  if (freqMhz >= vhfMin && freqMhz <= vhfMax) return null;
  if (freqMhz >= uhfMin && freqMhz <= uhfMax) return null;
  return 'Frequency ${freqMhz.toStringAsFixed(3)} MHz is outside UV-5RM bands '
      '(VHF: $vhfMin-$vhfMax, UHF: $uhfMin-$uhfMax)';
}

List<String> validateChannel(ChannelData channel) {
  final warnings = <String>[];
  if (channel.rxFreq > 0) {
    final rx = validateFrequency(channel.rxFreq);
    if (rx != null) warnings.add(rx);
  }
  if (channel.duplex == 'split' && channel.txFreq > 0) {
    final tx = validateFrequency(channel.txFreq);
    if (tx != null) warnings.add(tx);
  }
  if (channel.name.length > 7) {
    warnings.add('Name "${channel.name}" exceeds 7 characters');
  }
  return warnings;
}

ChannelData createDefaultChannel(int index) => ChannelData(index: index);

List<ChannelData> createDefaultChannels() =>
    List.generate(128, createDefaultChannel);

String channelsToCsv(List<ChannelData> channels) {
  final header = 'Channel,RX Freq,TX Freq,Duplex,Tone Mode,RX Tone,TX Tone,Name,Power,Bandwidth';
  final rows = channels.map((ch) {
    final rxFreq = ch.rxFreq > 0 ? ch.rxFreq.toStringAsFixed(5) : '';
    final txFreq = ch.txFreq > 0 ? ch.txFreq.toStringAsFixed(5) : '';
    final rxTone = ch.toneMode == 'CTCSS'
        ? ctcssTones[ch.rxToneCode.clamp(0, ctcssTones.length - 1)]
        : ch.toneMode == 'DCS'
            ? dcsCodes[ch.rxToneCode.clamp(0, dcsCodes.length - 1)]
            : '';
    final txTone = ch.toneMode == 'CTCSS'
        ? ctcssTones[ch.txToneCode.clamp(0, ctcssTones.length - 1)]
        : ch.toneMode == 'DCS'
            ? dcsCodes[ch.txToneCode.clamp(0, dcsCodes.length - 1)]
            : '';
    return '${ch.index + 1},$rxFreq,$txFreq,${ch.duplex},${ch.toneMode},$rxTone,$txTone,${ch.name},${ch.power},${ch.bandwidth}';
  });
  return [header, ...rows].join('\n');
}

List<ChannelData> channelsFromCsv(String csv) {
  final lines = csv.trim().split('\n');
  if (lines.length < 2) return [];

  final channels = <ChannelData>[];
  for (var i = 1; i < lines.length; i++) {
    final cols = lines[i].split(',');
    if (cols.length < 10) continue;
    final idx = int.tryParse(cols[0]) ?? 0;
    if (idx < 1 || idx > 128) continue;

    final toneMode = toneModes.contains(cols[4]) ? cols[4] : 'None';
    var rxToneCode = 0;
    var txToneCode = 0;
    final rxToneVal = double.tryParse(cols[5]) ?? 0;
    final txToneVal = double.tryParse(cols[6]) ?? 0;
    if (toneMode == 'CTCSS') {
      final rxIdx = ctcssTones.indexOf(rxToneVal);
      final txIdx = ctcssTones.indexOf(txToneVal);
      rxToneCode = rxIdx >= 0 ? rxIdx : 0;
      txToneCode = txIdx >= 0 ? txIdx : 0;
    } else if (toneMode == 'DCS') {
      final rxIdx = dcsCodes.indexOf(rxToneVal.toInt());
      final txIdx = dcsCodes.indexOf(txToneVal.toInt());
      rxToneCode = rxIdx >= 0 ? rxIdx : 0;
      txToneCode = txIdx >= 0 ? txIdx : 0;
    }

    channels.add(ChannelData(
      index: idx - 1,
      rxFreq: double.tryParse(cols[1]) ?? 0,
      txFreq: double.tryParse(cols[2]) ?? 0,
      duplex: duplexModes.contains(cols[3]) ? cols[3] : 'none',
      toneMode: toneMode,
      rxToneCode: rxToneCode,
      txToneCode: txToneCode,
      name: cols[7].length > 7 ? cols[7].substring(0, 7) : cols[7],
      power: powerLevels.contains(cols[8]) ? cols[8] : 'High',
      bandwidth: bandwidthOptions.contains(cols[9]) ? cols[9] : 'Wide',
    ));
  }
  return channels;
}
