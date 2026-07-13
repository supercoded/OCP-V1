/// OCP-V1 platform service layer.
///
/// Provides hardware communication via platform channels (mobile) or
/// WebSocket bridge (desktop).
///
/// Usage:
///   import 'package:ocp_v1/services.dart';
///   final platform = ServiceLocator.platform;
///   await platform.connect({...});
library;

export 'platform_service.dart';
export 'service_locator.dart';