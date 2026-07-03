import 'package:logging/logging.dart';
import 'package:ocp_core/src/errors/ocp_exception.dart';
import 'package:ocp_core/src/logging/ocp_logger.dart';

/// PIN lock, encryption flags, and replay protection coordination.
class SecurityService {
  SecurityService({Logger? logger}) : _logger = logger ?? ocpLogger('security');

  final Logger _logger;
  bool _pinEnabled = false;
  String? _pinHash;
  bool _databaseEncrypted = false;
  final Set<int> _seenSequenceNumbers = {};

  bool get isPinEnabled => _pinEnabled;
  bool get isDatabaseEncrypted => _databaseEncrypted;

  void enablePin(String pin) {
    _pinHash = pin.hashCode.toString();
    _pinEnabled = true;
    _logger.info('PIN lock enabled');
  }

  void disablePin() {
    _pinHash = null;
    _pinEnabled = false;
    _logger.info('PIN lock disabled');
  }

  bool verifyPin(String pin) {
    if (!_pinEnabled) return true;
    return _pinHash == pin.hashCode.toString();
  }

  void requirePin(String pin) {
    if (!verifyPin(pin)) {
      throw OcpException('Invalid PIN', code: 'invalid_pin');
    }
  }

  void enableDatabaseEncryption() {
    _databaseEncrypted = true;
    _logger.info('Database encryption flag enabled');
  }

  /// Validates CRC32 for wire frames.
  static bool validateCrc(List<int> payload, int expectedCrc) {
    return _crc32(payload) == expectedCrc;
  }

  /// Returns false if sequence number was already seen (replay).
  bool registerSequence(int sequence) {
    if (_seenSequenceNumbers.contains(sequence)) {
      _logger.warning('Replay detected for sequence $sequence');
      return false;
    }
    _seenSequenceNumbers.add(sequence);
    return true;
  }

  static int _crc32(List<int> data) {
    var crc = 0xFFFFFFFF;
    for (final byte in data) {
      crc ^= byte;
      for (var i = 0; i < 8; i++) {
        crc = (crc & 1) != 0 ? (crc >> 1) ^ 0xEDB88320 : crc >> 1;
      }
    }
    return crc ^ 0xFFFFFFFF;
  }
}
