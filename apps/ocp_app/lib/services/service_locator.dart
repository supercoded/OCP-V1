import 'dart:io' show Platform;
import 'package:flutter/foundation.dart';
import 'platform_service.dart';
import 'storage_service.dart';

/// Singleton service locator that creates the appropriate PlatformService
/// based on the current platform and initializes StorageService for
/// local persistence.
///
/// On desktop (Linux/Windows/macOS): WebSocketPlatformService
/// On mobile (Android/iOS): MethodChannelPlatformService
class ServiceLocator {
  static ServiceLocator? _instance;

  late final PlatformService platformService;
  late final StorageService storageService;

  ServiceLocator._() {
    if (_isDesktop) {
      platformService = WebSocketPlatformService();
      debugPrint('[ServiceLocator] Using WebSocketPlatformService (desktop)');
    } else {
      platformService = MethodChannelPlatformService();
      debugPrint('[ServiceLocator] Using MethodChannelPlatformService (mobile)');
    }
    storageService = LocalStorageService();
    debugPrint('[ServiceLocator] Using LocalStorageService');
  }

  /// Get the singleton instance.
  static ServiceLocator get instance {
    _instance ??= ServiceLocator._();
    return _instance!;
  }

  /// Whether the current platform is desktop.
  static bool get _isDesktop {
    if (kIsWeb) return false;
    return Platform.isLinux || Platform.isMacOS || Platform.isWindows;
  }

  /// Convenience getter for platform service.
  static PlatformService get platform => instance.platformService;

  /// Convenience getter for storage service.
  static StorageService get storage => instance.storageService;

  /// Initialize — call in main() before runApp().
  static Future<void> initialize() async {
    debugPrint('[ServiceLocator] Initializing on ${Platform.operatingSystem}');

    // Initialize storage first
    await instance.storageService.init();

    // For desktop, pre-connect to the bridge WebSocket.
    if (_isDesktop) {
      final ws = instance.platformService as WebSocketPlatformService;
      try {
        await ws.ensureConnected();
        debugPrint('[ServiceLocator] Connected to bridge server');
      } catch (e) {
        debugPrint('[ServiceLocator] Bridge server not yet available: $e');
        // Will auto-reconnect via WebSocketPlatformService internals.
      }
    }
  }

  /// Dispose all services.
  static Future<void> dispose() async {
    await instance.platformService.dispose();
    _instance = null;
  }
}