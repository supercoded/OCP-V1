/// Abstract storage service interface for OCP-V1.
///
/// Defines the contract for key-value persistence. The concrete
/// implementation (LocalStorageService using SharedPreferences)
/// lives in the app package and includes JSON encode/decode helpers.
///
/// Inject the concrete StorageService from ServiceLocator at startup.
abstract class StorageService {
  Future<void> init();

  Future<String?> getString(String key);
  Future<void> setString(String key, String value);

  Future<int?> getInt(String key);
  Future<void> setInt(String key, int value);

  Future<double?> getDouble(String key);
  Future<void> setDouble(String key, double value);

  Future<bool?> getBool(String key);
  Future<void> setBool(String key, bool value);

  Future<List<String>> getStringList(String key);
  Future<void> setStringList(String key, List<String> value);

  Future<void> remove(String key);
  Future<void> clear();

  /// Encode a complex object to JSON string and store it.
  Future<void> setJson(String key, Map<String, dynamic> value);

  /// Read a JSON string and decode it back to a Map.
  Future<Map<String, dynamic>?> getJson(String key);

  /// Encode a list of complex objects to JSON and store it.
  Future<void> setJsonList(String key, List<Map<String, dynamic>> value);

  /// Read a JSON list and decode it back to a List of Maps.
  Future<List<Map<String, dynamic>>?> getJsonList(String key);
}

/// Common storage key constants shared across packages.
class StorageKeys {
  // Settings
  static const String theme = 'settings_theme';
  static const String sonarRangeKm = 'settings_sonar_range_km';
  static const String sonarSweepSpeed = 'settings_sonar_sweep_speed';
  static const String messagingChannel = 'settings_messaging_channel';
  static const String meshtasticHost = 'settings_meshtastic_host';
  static const String meshtasticPort = 'settings_meshtastic_port';
  static const String rtlSdrHost = 'settings_rtl_sdr_host';
  static const String rtlSdrPort = 'settings_rtl_sdr_port';
  static const String rtlSdrCenterFreq = 'settings_rtl_sdr_center_freq';
  static const String rtlSdrGain = 'settings_rtl_sdr_gain';
  static const String rtlSdrGainMode = 'settings_rtl_sdr_gain_mode';
  static const String ruViewHost = 'settings_ruview_host';
  static const String ruViewPort = 'settings_ruview_port';
  static const String peakHoldEnabled = 'settings_peak_hold_enabled';
  static const String vfoEnabled = 'settings_vfo_enabled';
  static const String vfoFreq = 'settings_vfo_freq';
  static const String vfoBandwidth = 'settings_vfo_bandwidth';

  // Bookmarks
  static const String bookmarks = 'spectrum_bookmarks';

  // Connection history
  static const String recentConnections = 'recent_connections';

  // App settings (single JSON blob)
  static const String appSettings = 'app_settings';
}