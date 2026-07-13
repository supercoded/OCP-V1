import 'package:flutter/foundation.dart';
import '../models/app_settings.dart';
import '../services/storage_service.dart';

/// Manages application settings with automatic persistence.
///
/// Each setter saves the setting immediately so nothing is lost
/// on an unexpected exit. Call [loadSettings] during app startup
/// to restore the user's last session.
class SettingsProvider extends ChangeNotifier {
  final StorageService _storage;

  AppSettings _settings = const AppSettings();

  AppSettings get settings => _settings;

  SettingsProvider({required StorageService storage}) : _storage = storage;

  /// Load all settings from local storage. Call once at startup.
  Future<void> loadSettings() async {
    final json = await _storage.getJson(StorageKeys.appSettings);
    if (json != null) {
      _settings = AppSettings.fromMap(json);
      debugPrint('[SettingsProvider] Loaded settings from storage');
    } else {
      debugPrint('[SettingsProvider] No saved settings, using defaults');
    }
    notifyListeners();
  }

  Future<void> _saveSettings() async {
    await _storage.setJson(StorageKeys.appSettings, _settings.toMap());
  }

  // ── Theme ──────────────────────────────────────────────────────────

  // Currently only 'dark' is supported; placeholder for future themes.

  // ── Sonar ───────────────────────────────────────────────────────────

  void updateSonarRange(double km) {
    _settings = _settings.copyWith(sonarRangeKm: km);
    _saveSettings();
    notifyListeners();
  }

  void updateSweepSpeed(double seconds) {
    _settings = _settings.copyWith(sonarSweepSpeed: seconds);
    _saveSettings();
    notifyListeners();
  }

  // ── Messaging ───────────────────────────────────────────────────────

  void updateMessagingChannel(int channel) {
    _settings = _settings.copyWith(messagingChannel: channel);
    _saveSettings();
    notifyListeners();
  }

  // ── Meshtastic ───────────────────────────────────────────────────────

  void updateMeshtasticHost(String host) {
    _settings = _settings.copyWith(meshtasticHost: host);
    _saveSettings();
    notifyListeners();
  }

  void updateMeshtasticPort(int port) {
    _settings = _settings.copyWith(meshtasticPort: port);
    _saveSettings();
    notifyListeners();
  }

  // ── RTL-SDR ──────────────────────────────────────────────────────────

  void updateRtlSdrHost(String host) {
    _settings = _settings.copyWith(rtlSdrHost: host);
    _saveSettings();
    notifyListeners();
  }

  void updateRtlSdrPort(int port) {
    _settings = _settings.copyWith(rtlSdrPort: port);
    _saveSettings();
    notifyListeners();
  }

  void updateRtlSdrCenterFreq(double mHz) {
    _settings = _settings.copyWith(rtlSdrCenterFreq: mHz);
    _saveSettings();
    notifyListeners();
  }

  void updateRtlSdrGain(double gain) {
    _settings = _settings.copyWith(rtlSdrGain: gain);
    _saveSettings();
    notifyListeners();
  }

  void updateRtlSdrGainMode(String mode) {
    _settings = _settings.copyWith(rtlSdrGainMode: mode);
    _saveSettings();
    notifyListeners();
  }

  // ── RuView ──────────────────────────────────────────────────────────

  void updateRuViewHost(String host) {
    _settings = _settings.copyWith(ruViewHost: host);
    _saveSettings();
    notifyListeners();
  }

  void updateRuViewPort(int port) {
    _settings = _settings.copyWith(ruViewPort: port);
    _saveSettings();
    notifyListeners();
  }

  // ── Spectrum ─────────────────────────────────────────────────────────

  void updatePeakHoldEnabled(bool enabled) {
    _settings = _settings.copyWith(peakHoldEnabled: enabled);
    _saveSettings();
    notifyListeners();
  }

  void updateVfoEnabled(bool enabled) {
    _settings = _settings.copyWith(vfoEnabled: enabled);
    _saveSettings();
    notifyListeners();
  }

  void updateVfoFreq(double mHz) {
    _settings = _settings.copyWith(vfoFreq: mHz);
    _saveSettings();
    notifyListeners();
  }

  void updateVfoBandwidth(double kHz) {
    _settings = _settings.copyWith(vfoBandwidth: kHz);
    _saveSettings();
    notifyListeners();
  }

  // ── Reset ────────────────────────────────────────────────────────────

  void resetToDefaults() {
    _settings = const AppSettings();
    _saveSettings();
    notifyListeners();
  }
}