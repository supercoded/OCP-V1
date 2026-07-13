import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Abstract interface for platform-specific hardware communication.
///
/// On mobile (Android/iOS), this is implemented via MethodChannel.
/// On desktop (Linux/Windows/macOS), this is implemented via WebSocket
/// bridge to the existing Node.js packages.
abstract class PlatformService {
  // ── Meshtastic ──────────────────────────────────────────────────────

  /// Connect to a Meshtastic device.
  /// Options may include: tcpHost, tcpPort, serialPort, bleDeviceId.
  Future<bool> connect(Map<String, dynamic> options);

  /// Disconnect from the Meshtastic device.
  Future<void> disconnect();

  // ── RTL-SDR ─────────────────────────────────────────────────────────

  /// Connect to an rtl_tcp server.
  /// Options: host, port, centerFreqHz, sampleRate.
  Future<bool> connectRtl(Map<String, dynamic> options);

  /// Disconnect from rtl_tcp.
  Future<void> disconnectRtl();

  // ── Messaging ───────────────────────────────────────────────────────

  /// Send a text message.
  /// Params: text, channel, destinationNodeId (optional).
  Future<bool> sendMessage(Map<String, dynamic> params);

  /// Retrieve recent message history.
  Future<List<dynamic>> getMessageHistory();

  // ── RuView ──────────────────────────────────────────────────────────

  /// Start RuView Wi-Fi sensing.
  /// Options: host, wsPort.
  Future<void> startRuView(Map<String, dynamic> options);

  /// Stop RuView sensing.
  Future<void> stopRuView();

  // ── Maps ────────────────────────────────────────────────────────────

  /// Start the map tile server with a given .pmtiles file path.
  Future<void> startMap(String filePath);

  /// Stop the map tile server.
  Future<void> stopMap();

  // ── Streams ─────────────────────────────────────────────────────────

  /// Emits state-change events: connected, disconnected, transportKind, nodeCount.
  Stream<Map<String, dynamic>> get onStateChange;

  /// Emits received messages.
  Stream<Map<String, dynamic>> get onMessageReceived;

  /// Emits RuView sensing events.
  Stream<Map<String, dynamic>> get onRuViewSensing;

  /// Emits RTL-SDR spectrum frames.
  Stream<Map<String, dynamic>> get onRtlSpectrum;

  /// Emits network node updates.
  Stream<Map<String, dynamic>> get onNodeUpdate;

  // ── Lifecycle ────────────────────────────────────────────────────────

  /// Clean up resources.
  Future<void> dispose();
}

// ═══════════════════════════════════════════════════════════════════════
// MethodChannel implementation (mobile: Android / iOS)
// ═══════════════════════════════════════════════════════════════════════

class MethodChannelPlatformService implements PlatformService {
  static const _channelName = 'com.ocp.v1/platform';

  final MethodChannel _methodChannel;
  final EventChannel _stateChannel;
  final EventChannel _messageChannel;
  final EventChannel _ruViewChannel;
  final EventChannel _rtlChannel;
  final EventChannel _nodeChannel;

  MethodChannelPlatformService()
      : _methodChannel = const MethodChannel(_channelName),
        _stateChannel = const EventChannel('$_channelName/state'),
        _messageChannel = const EventChannel('$_channelName/messages'),
        _ruViewChannel = const EventChannel('$_channelName/ruview'),
        _rtlChannel = const EventChannel('$_channelName/rtl'),
        _nodeChannel = const EventChannel('$_channelName/nodes');

  @override
  Future<bool> connect(Map<String, dynamic> options) async {
    final result = await _methodChannel.invokeMethod<bool>('connect', options);
    return result ?? false;
  }

  @override
  Future<void> disconnect() async {
    await _methodChannel.invokeMethod<void>('disconnect');
  }

  @override
  Future<bool> connectRtl(Map<String, dynamic> options) async {
    final result =
        await _methodChannel.invokeMethod<bool>('connectRtl', options);
    return result ?? false;
  }

  @override
  Future<void> disconnectRtl() async {
    await _methodChannel.invokeMethod<void>('disconnectRtl');
  }

  @override
  Future<bool> sendMessage(Map<String, dynamic> params) async {
    final result =
        await _methodChannel.invokeMethod<bool>('sendMessage', params);
    return result ?? false;
  }

  @override
  Future<List<dynamic>> getMessageHistory() async {
    final result = await _methodChannel
        .invokeMethod<List<dynamic>>('getMessageHistory');
    return result ?? [];
  }

  @override
  Future<void> startRuView(Map<String, dynamic> options) async {
    await _methodChannel.invokeMethod<void>('startRuView', options);
  }

  @override
  Future<void> stopRuView() async {
    await _methodChannel.invokeMethod<void>('stopRuView');
  }

  @override
  Future<void> startMap(String filePath) async {
    await _methodChannel.invokeMethod<void>('startMap', {'filePath': filePath});
  }

  @override
  Future<void> stopMap() async {
    await _methodChannel.invokeMethod<void>('stopMap');
  }

  @override
  Stream<Map<String, dynamic>> get onStateChange =>
      _stateChannel.receiveBroadcastStream().map(_castEvent);

  @override
  Stream<Map<String, dynamic>> get onMessageReceived =>
      _messageChannel.receiveBroadcastStream().map(_castEvent);

  @override
  Stream<Map<String, dynamic>> get onRuViewSensing =>
      _ruViewChannel.receiveBroadcastStream().map(_castEvent);

  @override
  Stream<Map<String, dynamic>> get onRtlSpectrum =>
      _rtlChannel.receiveBroadcastStream().map(_castEvent);

  @override
  Stream<Map<String, dynamic>> get onNodeUpdate =>
      _nodeChannel.receiveBroadcastStream().map(_castEvent);

  static Map<String, dynamic> _castEvent(dynamic event) {
    if (event is Map) return Map<String, dynamic>.from(event);
    if (event is String) {
      try {
        return Map<String, dynamic>.from(jsonDecode(event));
      } catch (_) {
        return {};
      }
    }
    return {};
  }

  @override
  Future<void> dispose() async {
    // MethodChannel is global; nothing to close here.
  }
}

// ═══════════════════════════════════════════════════════════════════════
// WebSocket implementation (desktop: Linux / Windows / macOS)
// ═══════════════════════════════════════════════════════════════════════

class WebSocketPlatformService implements PlatformService {
  static const _defaultUrl = 'ws://localhost:18790';

  final String url;
  WebSocket? _ws;
  int _requestId = 0;
  final Map<int, Completer<Map<String, dynamic>>> _pending = {};

  // Stream controllers
  final StreamController<Map<String, dynamic>> _stateController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _messageController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _ruViewController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _rtlController =
      StreamController.broadcast();
  final StreamController<Map<String, dynamic>> _nodeController =
      StreamController.broadcast();

  bool _disposed = false;

  WebSocketPlatformService({this.url = _defaultUrl});

  bool get isConnected => _ws != null;

  /// Connect the WebSocket to the bridge server.
  Future<void> ensureConnected() async {
    if (_ws != null) return;
    try {
      _ws = await WebSocket.connect(url);
      _ws!.listen(_onData, onError: _onError, onDone: _onDone);
    } catch (e) {
      debugPrint('[WebSocketPlatformService] connect error: $e');
      rethrow;
    }
  }

  // ── PlatformService methods ──────────────────────────────────────────

  @override
  Future<bool> connect(Map<String, dynamic> options) async {
    await ensureConnected();
    final result = await _call('connect', options);
    return result['success'] == true;
  }

  @override
  Future<void> disconnect() async {
    await ensureConnected();
    await _call('disconnect', {});
  }

  @override
  Future<bool> connectRtl(Map<String, dynamic> options) async {
    await ensureConnected();
    final result = await _call('connectRtl', options);
    return result['success'] == true;
  }

  @override
  Future<void> disconnectRtl() async {
    await ensureConnected();
    await _call('disconnectRtl', {});
  }

  @override
  Future<bool> sendMessage(Map<String, dynamic> params) async {
    await ensureConnected();
    final result = await _call('sendMessage', params);
    return result['success'] == true;
  }

  @override
  Future<List<dynamic>> getMessageHistory() async {
    await ensureConnected();
    final result = await _call('getMessageHistory', {});
    return result['messages'] as List<dynamic>? ?? [];
  }

  @override
  Future<void> startRuView(Map<String, dynamic> options) async {
    await ensureConnected();
    await _call('startRuView', options);
  }

  @override
  Future<void> stopRuView() async {
    await ensureConnected();
    await _call('stopRuView', {});
  }

  @override
  Future<void> startMap(String filePath) async {
    await ensureConnected();
    await _call('startMap', {'filePath': filePath});
  }

  @override
  Future<void> stopMap() async {
    await ensureConnected();
    await _call('stopMap', {});
  }

  // ── Streams ──────────────────────────────────────────────────────────

  @override
  Stream<Map<String, dynamic>> get onStateChange => _stateController.stream;

  @override
  Stream<Map<String, dynamic>> get onMessageReceived =>
      _messageController.stream;

  @override
  Stream<Map<String, dynamic>> get onRuViewSensing =>
      _ruViewController.stream;

  @override
  Stream<Map<String, dynamic>> get onRtlSpectrum => _rtlController.stream;

  @override
  Stream<Map<String, dynamic>> get onNodeUpdate => _nodeController.stream;

  // ── Internals ────────────────────────────────────────────────────────

  Future<Map<String, dynamic>> _call(
      String method, Map<String, dynamic> params) async {
    final id = ++_requestId;
    final completer = Completer<Map<String, dynamic>>();
    _pending[id] = completer;

    final msg = jsonEncode({
      'type': 'command',
      'id': id,
      'method': method,
      'params': params,
    });
    _ws!.add(msg);

    // Timeout after 15 seconds
    return completer.future.timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        _pending.remove(id);
        return {'success': false, 'error': 'timeout'};
      },
    );
  }

  void _onData(dynamic data) {
    if (_disposed) return;
    try {
      final map = jsonDecode(data as String) as Map<String, dynamic>;
      if (map['type'] == 'response' && map['id'] != null) {
        final id = map['id'] as int;
        final completer = _pending.remove(id);
        completer?.complete(map);
      } else if (map['type'] == 'event') {
        _dispatchEvent(map);
      }
    } catch (e) {
      debugPrint('[WebSocketPlatformService] parse error: $e');
    }
  }

  void _dispatchEvent(Map<String, dynamic> map) {
    final event = map['event'] as String? ?? '';
    final eventData = map['data'] as Map<String, dynamic>? ?? {};
    switch (event) {
      case 'stateChange':
        _stateController.add(eventData);
        break;
      case 'messageReceived':
        _messageController.add(eventData);
        break;
      case 'ruViewSensing':
        _ruViewController.add(eventData);
        break;
      case 'rtlSpectrum':
        _rtlController.add(eventData);
        break;
      case 'nodeUpdate':
        _nodeController.add(eventData);
        break;
    }
  }

  void _onError(dynamic error) {
    debugPrint('[WebSocketPlatformService] error: $error');
  }

  void _onDone() {
    _ws = null;
    // Fail all pending requests
    for (final completer in _pending.values) {
      completer.complete({'success': false, 'error': 'websocket closed'});
    }
    _pending.clear();
    if (!_disposed) {
      // Auto-reconnect after a short delay
      Future.delayed(const Duration(seconds: 3), () {
        if (!_disposed) ensureConnected();
      });
    }
  }

  @override
  Future<void> dispose() async {
    _disposed = true;
    await _ws?.close();
    _ws = null;
    await _stateController.close();
    await _messageController.close();
    await _ruViewController.close();
    await _rtlController.close();
    await _nodeController.close();
  }
}