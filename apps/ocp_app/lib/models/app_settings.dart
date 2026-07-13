/// Application-wide settings model.
///
/// All settings are persisted via StorageService so they survive
/// app restarts. Use [copyWith] for immutable updates and
/// [toMap]/[fromMap] for serialization.
class AppSettings {
  final String theme;
  final double sonarRangeKm;
  final double sonarSweepSpeed;
  final int messagingChannel;
  final String meshtasticHost;
  final int meshtasticPort;
  final String rtlSdrHost;
  final int rtlSdrPort;
  final double rtlSdrCenterFreq;
  final double rtlSdrGain;
  final String rtlSdrGainMode;
  final String ruViewHost;
  final int ruViewPort;
  final bool peakHoldEnabled;
  final bool vfoEnabled;
  final double vfoFreq;
  final double vfoBandwidth;

  const AppSettings({
    this.theme = 'dark',
    this.sonarRangeKm = 10.0,
    this.sonarSweepSpeed = 4.0,
    this.messagingChannel = 0,
    this.meshtasticHost = '10.0.0.100',
    this.meshtasticPort = 4403,
    this.rtlSdrHost = 'localhost',
    this.rtlSdrPort = 1234,
    this.rtlSdrCenterFreq = 100.0,
    this.rtlSdrGain = 0.0,
    this.rtlSdrGainMode = 'auto',
    this.ruViewHost = 'localhost',
    this.ruViewPort = 3001,
    this.peakHoldEnabled = false,
    this.vfoEnabled = true,
    this.vfoFreq = 100.0,
    this.vfoBandwidth = 15.0,
  });

  Map<String, dynamic> toMap() => {
        'theme': theme,
        'sonarRangeKm': sonarRangeKm,
        'sonarSweepSpeed': sonarSweepSpeed,
        'messagingChannel': messagingChannel,
        'meshtasticHost': meshtasticHost,
        'meshtasticPort': meshtasticPort,
        'rtlSdrHost': rtlSdrHost,
        'rtlSdrPort': rtlSdrPort,
        'rtlSdrCenterFreq': rtlSdrCenterFreq,
        'rtlSdrGain': rtlSdrGain,
        'rtlSdrGainMode': rtlSdrGainMode,
        'ruViewHost': ruViewHost,
        'ruViewPort': ruViewPort,
        'peakHoldEnabled': peakHoldEnabled,
        'vfoEnabled': vfoEnabled,
        'vfoFreq': vfoFreq,
        'vfoBandwidth': vfoBandwidth,
      };

  factory AppSettings.fromMap(Map<String, dynamic> map) => AppSettings(
        theme: map['theme'] as String? ?? 'dark',
        sonarRangeKm: (map['sonarRangeKm'] as num?)?.toDouble() ?? 10.0,
        sonarSweepSpeed: (map['sonarSweepSpeed'] as num?)?.toDouble() ?? 4.0,
        messagingChannel: (map['messagingChannel'] as num?)?.toInt() ?? 0,
        meshtasticHost: map['meshtasticHost'] as String? ?? '10.0.0.100',
        meshtasticPort: (map['meshtasticPort'] as num?)?.toInt() ?? 4403,
        rtlSdrHost: map['rtlSdrHost'] as String? ?? 'localhost',
        rtlSdrPort: (map['rtlSdrPort'] as num?)?.toInt() ?? 1234,
        rtlSdrCenterFreq: (map['rtlSdrCenterFreq'] as num?)?.toDouble() ?? 100.0,
        rtlSdrGain: (map['rtlSdrGain'] as num?)?.toDouble() ?? 0.0,
        rtlSdrGainMode: map['rtlSdrGainMode'] as String? ?? 'auto',
        ruViewHost: map['ruViewHost'] as String? ?? 'localhost',
        ruViewPort: (map['ruViewPort'] as num?)?.toInt() ?? 3001,
        peakHoldEnabled: map['peakHoldEnabled'] as bool? ?? false,
        vfoEnabled: map['vfoEnabled'] as bool? ?? true,
        vfoFreq: (map['vfoFreq'] as num?)?.toDouble() ?? 100.0,
        vfoBandwidth: (map['vfoBandwidth'] as num?)?.toDouble() ?? 15.0,
      );

  AppSettings copyWith({
    String? theme,
    double? sonarRangeKm,
    double? sonarSweepSpeed,
    int? messagingChannel,
    String? meshtasticHost,
    int? meshtasticPort,
    String? rtlSdrHost,
    int? rtlSdrPort,
    double? rtlSdrCenterFreq,
    double? rtlSdrGain,
    String? rtlSdrGainMode,
    String? ruViewHost,
    int? ruViewPort,
    bool? peakHoldEnabled,
    bool? vfoEnabled,
    double? vfoFreq,
    double? vfoBandwidth,
  }) =>
      AppSettings(
        theme: theme ?? this.theme,
        sonarRangeKm: sonarRangeKm ?? this.sonarRangeKm,
        sonarSweepSpeed: sonarSweepSpeed ?? this.sonarSweepSpeed,
        messagingChannel: messagingChannel ?? this.messagingChannel,
        meshtasticHost: meshtasticHost ?? this.meshtasticHost,
        meshtasticPort: meshtasticPort ?? this.meshtasticPort,
        rtlSdrHost: rtlSdrHost ?? this.rtlSdrHost,
        rtlSdrPort: rtlSdrPort ?? this.rtlSdrPort,
        rtlSdrCenterFreq: rtlSdrCenterFreq ?? this.rtlSdrCenterFreq,
        rtlSdrGain: rtlSdrGain ?? this.rtlSdrGain,
        rtlSdrGainMode: rtlSdrGainMode ?? this.rtlSdrGainMode,
        ruViewHost: ruViewHost ?? this.ruViewHost,
        ruViewPort: ruViewPort ?? this.ruViewPort,
        peakHoldEnabled: peakHoldEnabled ?? this.peakHoldEnabled,
        vfoEnabled: vfoEnabled ?? this.vfoEnabled,
        vfoFreq: vfoFreq ?? this.vfoFreq,
        vfoBandwidth: vfoBandwidth ?? this.vfoBandwidth,
      );
}