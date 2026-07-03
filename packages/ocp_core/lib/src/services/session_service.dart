import 'dart:async';

import 'package:logging/logging.dart';
import 'package:ocp_core/src/logging/ocp_logger.dart';

/// Device/session connection state.
enum SessionState { disconnected, connecting, connected, error }

/// Tracks the active device session (wire details live in [OdpDeviceSession]).
class SessionService {
  SessionService({Logger? logger}) : _logger = logger ?? ocpLogger('session');

  final Logger _logger;
  SessionState _state = SessionState.disconnected;
  String? _activeDeviceId;
  final _stateController = StreamController<SessionState>.broadcast();

  SessionState get state => _state;
  String? get activeDeviceId => _activeDeviceId;
  Stream<SessionState> get stateChanges => _stateController.stream;

  void setConnecting(String deviceId) {
    _logger.info('Connecting to $deviceId');
    _activeDeviceId = deviceId;
    _setState(SessionState.connecting);
  }

  void setConnected(String deviceId) {
    _logger.info('Connected to $deviceId');
    _activeDeviceId = deviceId;
    _setState(SessionState.connected);
  }

  void setError(String deviceId) {
    _logger.warning('Session error for $deviceId');
    _activeDeviceId = deviceId;
    _setState(SessionState.error);
  }

  Future<void> disconnect() async {
    _logger.info('Disconnecting');
    _activeDeviceId = null;
    _setState(SessionState.disconnected);
  }

  Future<void> dispose() => _stateController.close();

  void _setState(SessionState value) {
    _state = value;
    if (!_stateController.isClosed) {
      _stateController.add(value);
    }
  }
}
