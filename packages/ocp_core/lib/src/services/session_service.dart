import 'package:logging/logging.dart';
import 'package:ocp_core/src/logging/ocp_logger.dart';

/// Device/session connection state.
enum SessionState { disconnected, connecting, connected, error }

/// Orchestrates device session state (ODP integration in later phases).
class SessionService {
  SessionService({Logger? logger}) : _logger = logger ?? ocpLogger('session');

  final Logger _logger;
  SessionState _state = SessionState.disconnected;
  String? _activeDeviceId;

  SessionState get state => _state;
  String? get activeDeviceId => _activeDeviceId;

  Future<void> connect(String deviceId) async {
    _logger.info('Connecting to $deviceId');
    _state = SessionState.connecting;
    _activeDeviceId = deviceId;
    _state = SessionState.connected;
  }

  Future<void> disconnect() async {
    _logger.info('Disconnecting');
    _state = SessionState.disconnected;
    _activeDeviceId = null;
  }
}
