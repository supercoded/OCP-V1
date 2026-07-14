import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/connection_history.dart';
import '../services/platform_service.dart';
import '../services/storage_service.dart';

class NodeInfo {
  final String id;
  final String name;
  final String status;

  NodeInfo({required this.id, required this.name, required this.status});
}

class ConnectionOptions {
  final String? tcpHost;
  final int? tcpPort;
  final String? serialPort;
  final String? bleDeviceId;

  const ConnectionOptions({
    this.tcpHost,
    this.tcpPort,
    this.serialPort,
    this.bleDeviceId,
  });
}

class RtlOptions {
  final String host;
  final int port;
  final double centerFreqHz;

  const RtlOptions({
    this.host = 'localhost',
    this.port = 1234,
    this.centerFreqHz = 100e6,
  });
}

class ConnectionProvider extends ChangeNotifier {
  final PlatformService? _platformService;
  final StorageService? _storageService;
  StreamSubscription<Map<String, dynamic>>? _stateSubscription;
  StreamSubscription<Map<String, dynamic>>? _nodeSubscription;

  // Recent connections (persisted)
  final List<RecentConnection> _recentConnections = [];
  List<RecentConnection> get recentConnections => List.unmodifiable(_recentConnections);

  // Meshtastic connection
  bool _connected = false;
  bool _connecting = false;
  String? _transportKind;
  int _nodeCount = 0;
  final List<NodeInfo> _nodes = [];

  // RuView
  bool _ruViewConnected = false;
  String? _ruViewHost;
  int? _ruViewPort;
  int _ruViewTargetCount = 0;
  String? _ruViewError;

  // RTL-SDR
  bool _rtlConnected = false;
  String? _rtlHost;
  int _rtlPort = 1234;
  double _rtlCenterFreq = 100e6;
  double _rtlSampleRate = 2.4e6;
  String? _rtlError;

  // Baofeng
  bool _baofengConnected = false;
  String? _baofengPortName;

  // Getters — Meshtastic
  bool get connected => _connected;
  bool get connecting => _connecting;
  String? get transportKind => _transportKind;
  int get nodeCount => _nodeCount;
  List<NodeInfo> get nodes => List.unmodifiable(_nodes);

  // Getters — RuView
  bool get ruViewConnected => _ruViewConnected;
  String? get ruViewHost => _ruViewHost;
  int? get ruViewPort => _ruViewPort;
  int get ruViewTargetCount => _ruViewTargetCount;
  String? get ruViewError => _ruViewError;

  // Getters — RTL-SDR
  bool get rtlConnected => _rtlConnected;
  String? get rtlHost => _rtlHost;
  int get rtlPort => _rtlPort;
  double get rtlCenterFreq => _rtlCenterFreq;
  double get rtlSampleRate => _rtlSampleRate;
  String? get rtlError => _rtlError;

  // Getters — Baofeng
  bool get baofengConnected => _baofengConnected;
  String? get baofengPortName => _baofengPortName;

  ConnectionProvider({PlatformService? platformService, StorageService? storageService})
      : _platformService = platformService,
        _storageService = storageService {
    _listenToPlatform();
    _loadRecentConnections();
  }

  void _listenToPlatform() {
    if (_platformService == null) return;

    _stateSubscription = _platformService.onStateChange.listen((event) {
      final connected = event['connected'] as bool?;
      final transportKind = event['transportKind'] as String?;
      final nodeCount = event['nodeCount'] as int?;

      if (connected != null) _connected = connected;
      if (transportKind != null) _transportKind = transportKind;
      if (nodeCount != null) _nodeCount = nodeCount;

      if (connected == true) {
        _connecting = false;
      }
      notifyListeners();
    });

    _nodeSubscription = _platformService.onNodeUpdate.listen((event) {
      final id = event['id']?.toString() ?? '';
      final name = event['shortName'] as String? ?? event['longName'] as String? ?? '';
      final status = event['role'] as String? ?? 'client';
      _upsertNode(NodeInfo(id: id, name: name, status: status));
      notifyListeners();
    });
  }

  void _upsertNode(NodeInfo node) {
    final idx = _nodes.indexWhere((n) => n.id == node.id);
    if (idx >= 0) {
      _nodes[idx] = node;
    } else {
      _nodes.add(node);
    }
    _nodeCount = _nodes.length;
  }

  // Meshtastic actions
  void setConnecting(bool value) {
    _connecting = value;
    notifyListeners();
  }

  void setConnected(bool value) {
    _connected = value;
    _connecting = false;
    notifyListeners();
  }

  void setTransportKind(String kind) {
    _transportKind = kind;
    notifyListeners();
  }

  void updateNodes(List<NodeInfo> newNodes) {
    _nodes
      ..clear()
      ..addAll(newNodes);
    _nodeCount = _nodes.length;
    notifyListeners();
  }

  // ── Recent connections persistence ────────────────────────────────────

  Future<void> _loadRecentConnections() async {
    if (_storageService == null) return;
    try {
      final list = await _storageService.getJsonList(StorageKeys.recentConnections);
      if (list != null) {
        _recentConnections.clear();
        _recentConnections.addAll(
          list.map((m) => RecentConnection.fromMap(m)).take(10),
        );
        debugPrint('[ConnectionProvider] Loaded ${_recentConnections.length} recent connections');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[ConnectionProvider] Failed to load recent connections: $e');
    }
  }

  Future<void> _saveRecentConnections() async {
    if (_storageService == null) return;
    try {
      final list = _recentConnections.map((c) => c.toMap()).toList();
      await _storageService.setJsonList(StorageKeys.recentConnections, list);
    } catch (e) {
      debugPrint('[ConnectionProvider] Failed to save recent connections: $e');
    }
  }

  void _addRecentConnection(String host, int port, String transportKind) {
    final conn = RecentConnection(
      host: host,
      port: port,
      transportKind: transportKind,
      lastUsed: DateTime.now(),
    );
    // Remove duplicate if exists
    _recentConnections.removeWhere((c) => c.key == conn.key);
    // Insert at front
    _recentConnections.insert(0, conn);
    // Keep only last 10
    if (_recentConnections.length > 10) {
      _recentConnections.removeRange(10, _recentConnections.length);
    }
    _saveRecentConnections();
  }

  void clearRecentConnections() {
    _recentConnections.clear();
    _saveRecentConnections();
    notifyListeners();
  }

  /// Connect to Meshtastic device via platform service or fallback stub.
  Future<void> connect(ConnectionOptions options) async {
    _connecting = true;
    notifyListeners();

    if (_platformService != null) {
      try {
        final success = await _platformService.connect({
          if (options.tcpHost != null) 'tcpHost': options.tcpHost,
          if (options.tcpPort != null) 'tcpPort': options.tcpPort,
          if (options.serialPort != null) 'serialPort': options.serialPort,
          if (options.bleDeviceId != null) 'bleDeviceId': options.bleDeviceId,
        });
        if (!success) {
          _connected = false;
          _connecting = false;
          notifyListeners();
        }
        // State update will come from onStateChange stream
      } catch (e) {
        _connected = false;
        _connecting = false;
        notifyListeners();
      }
    } else {
      // Fallback stub for testing
      await Future.delayed(const Duration(milliseconds: 500));
      _connected = true;
      _connecting = false;
      if (options.tcpHost != null) {
        _transportKind = 'TCP';
      } else if (options.serialPort != null) {
        _transportKind = 'Serial';
      } else if (options.bleDeviceId != null) {
        _transportKind = 'BLE';
      } else {
        _transportKind = 'Auto';
      }
      // Save to recent connections
      _addRecentConnection(
        options.tcpHost ?? options.serialPort ?? options.bleDeviceId ?? 'auto',
        options.tcpPort ?? 4403,
        _transportKind!,
      );
      notifyListeners();
    }
  }

  Future<void> disconnect() async {
    if (_platformService != null) {
      try {
        await _platformService.disconnect();
      } catch (_) {}
    }
    _connected = false;
    _connecting = false;
    _transportKind = null;
    notifyListeners();
  }

  // RTL-SDR actions
  Future<void> connectRtl(RtlOptions options) async {
    if (_platformService != null) {
      try {
        final success = await _platformService.connectRtl({
          'host': options.host,
          'port': options.port,
          'centerFreqHz': options.centerFreqHz,
        });
        if (success) {
          _rtlHost = options.host;
          _rtlPort = options.port;
          _rtlCenterFreq = options.centerFreqHz;
          _rtlConnected = true;
          _rtlError = null;
        } else {
          _rtlError = 'Connection failed';
        }
      } catch (e) {
        _rtlError = e.toString();
      }
    } else {
      _rtlHost = options.host;
      _rtlPort = options.port;
      _rtlCenterFreq = options.centerFreqHz;
      _rtlConnected = true;
      _rtlError = null;
    }
    notifyListeners();
  }

  Future<void> disconnectRtl() async {
    if (_platformService != null) {
      try {
        await _platformService.disconnectRtl();
      } catch (_) {}
    }
    _rtlConnected = false;
    _rtlError = null;
    notifyListeners();
  }

  void setRtlCenterFreq(double hz) {
    _rtlCenterFreq = hz;
    notifyListeners();
  }

  void setRtlSampleRate(double rate) {
    _rtlSampleRate = rate;
    notifyListeners();
  }

  void setRtlError(String? error) {
    _rtlError = error;
    notifyListeners();
  }

  // RuView actions
  Future<void> startRuView({String host = 'localhost', int port = 3001}) async {
    if (_platformService != null) {
      try {
        await _platformService.startRuView({
          'host': host,
          'wsPort': port,
        });
        _ruViewHost = host;
        _ruViewPort = port;
        _ruViewConnected = true;
        _ruViewError = null;
      } catch (e) {
        _ruViewError = e.toString();
      }
    } else {
      _ruViewHost = host;
      _ruViewPort = port;
      _ruViewConnected = true;
      _ruViewError = null;
    }
    notifyListeners();
  }

  Future<void> stopRuView() async {
    if (_platformService != null) {
      try {
        await _platformService.stopRuView();
      } catch (_) {}
    }
    _ruViewConnected = false;
    notifyListeners();
  }

  void setRuViewTargetCount(int count) {
    _ruViewTargetCount = count;
    notifyListeners();
  }

  void setRuViewError(String? error) {
    _ruViewError = error;
    notifyListeners();
  }

  // Baofeng actions
  void connectBaofeng(String portName) {
    _baofengConnected = true;
    _baofengPortName = portName;
    notifyListeners();
  }

  void disconnectBaofeng() {
    _baofengConnected = false;
    _baofengPortName = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _stateSubscription?.cancel();
    _nodeSubscription?.cancel();
    super.dispose();
  }
}