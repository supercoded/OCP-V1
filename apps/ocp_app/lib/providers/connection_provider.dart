import 'package:flutter/foundation.dart';

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

  /// Connect to Meshtastic device
  void connect(ConnectionOptions options) {
    _connecting = true;
    notifyListeners();
    // In real app, this would establish connection
    // For now, simulate success after brief delay
    Future.delayed(const Duration(milliseconds: 500), () {
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
      notifyListeners();
    });
  }

  void disconnect() {
    _connected = false;
    _connecting = false;
    _transportKind = null;
    notifyListeners();
  }

  // RTL-SDR actions
  void connectRtl(RtlOptions options) {
    _rtlHost = options.host;
    _rtlPort = options.port;
    _rtlCenterFreq = options.centerFreqHz;
    _rtlConnected = true;
    _rtlError = null;
    notifyListeners();
  }

  void disconnectRtl() {
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
  void startRuView({String host = 'localhost', int port = 3001}) {
    _ruViewHost = host;
    _ruViewPort = port;
    _ruViewConnected = true;
    _ruViewError = null;
    notifyListeners();
  }

  void stopRuView() {
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
}