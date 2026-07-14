import 'dart:convert';
export 'package:ocp_flutter_core/ocp_flutter_core.dart' show StorageService, StorageKeys;
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Concrete implementation of [StorageService] using SharedPreferences.
///
/// Created and initialized by [ServiceLocator] during app startup.
/// Inject into providers that need persistence.
class LocalStorageService implements StorageService {
  SharedPreferences? _prefs;

  @override
  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
    debugPrint('[LocalStorageService] Initialized');
  }

  SharedPreferences get _instance {
    if (_prefs == null) {
      throw StateError('LocalStorageService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  @override
  Future<String?> getString(String key) async => _instance.getString(key);

  @override
  Future<void> setString(String key, String value) async =>
      await _instance.setString(key, value);

  @override
  Future<int?> getInt(String key) async => _instance.getInt(key);

  @override
  Future<void> setInt(String key, int value) async =>
      await _instance.setInt(key, value);

  @override
  Future<double?> getDouble(String key) async => _instance.getDouble(key);

  @override
  Future<void> setDouble(String key, double value) async =>
      await _instance.setDouble(key, value);

  @override
  Future<bool?> getBool(String key) async => _instance.getBool(key);

  @override
  Future<void> setBool(String key, bool value) async =>
      await _instance.setBool(key, value);

  @override
  Future<List<String>> getStringList(String key) async =>
      _instance.getStringList(key) ?? [];

  @override
  Future<void> setStringList(String key, List<String> value) async =>
      await _instance.setStringList(key, value);

  @override
  Future<void> remove(String key) async => await _instance.remove(key);

  @override
  Future<void> clear() async => await _instance.clear();

  @override
  Future<void> setJson(String key, Map<String, dynamic> value) async {
    await setString(key, jsonEncode(value));
  }

  @override
  Future<Map<String, dynamic>?> getJson(String key) async {
    final raw = await getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (e) {
      debugPrint('[StorageService] Failed to decode JSON for key "$key": $e');
      return null;
    }
  }

  @override
  Future<void> setJsonList(String key, List<Map<String, dynamic>> value) async {
    await setString(key, jsonEncode(value));
  }

  @override
  Future<List<Map<String, dynamic>>?> getJsonList(String key) async {
    final raw = await getString(key);
    if (raw == null) return null;
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (e) {
      debugPrint('[StorageService] Failed to decode JSON list for key "$key": $e');
      return null;
    }
  }
}
