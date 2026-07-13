/// OCP-V1 platform service layer and storage.
///
/// Provides hardware communication via platform channels (mobile) or
/// WebSocket bridge (desktop), and local persistence via StorageService.
///
/// Usage:
///   import 'package:ocp_v1/services.dart';
///   final platform = ServiceLocator.platform;
///   final storage = ServiceLocator.storage;
///   await platform.connect({...});
library;

export 'platform_service.dart';
export 'service_locator.dart';
export 'storage_service.dart';