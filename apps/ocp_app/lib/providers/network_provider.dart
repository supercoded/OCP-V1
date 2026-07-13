import 'package:flutter/foundation.dart';

class MeshNode {
  final String id;
  final String shortName;
  final String longName;
  final String role; // client, router, repeater, etc.
  final double snr;
  final DateTime lastHeard;
  final double? lat;
  final double? lon;
  final int? rssi;

  const MeshNode({
    required this.id,
    this.shortName = '',
    this.longName = '',
    this.role = 'client',
    this.snr = 0.0,
    required this.lastHeard,
    this.lat,
    this.lon,
    this.rssi,
  });

  MeshNode copyWith({
    String? id,
    String? shortName,
    String? longName,
    String? role,
    double? snr,
    DateTime? lastHeard,
    double? lat,
    double? lon,
    int? rssi,
  }) {
    return MeshNode(
      id: id ?? this.id,
      shortName: shortName ?? this.shortName,
      longName: longName ?? this.longName,
      role: role ?? this.role,
      snr: snr ?? this.snr,
      lastHeard: lastHeard ?? this.lastHeard,
      lat: lat ?? this.lat,
      lon: lon ?? this.lon,
      rssi: rssi ?? this.rssi,
    );
  }

  /// Time since last heard, as a human-readable string
  String get timeSinceLastHeard {
    final diff = DateTime.now().difference(lastHeard);
    if (diff.inSeconds < 60) return '${diff.inSeconds}s ago';
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${diff.inDays}d ago';
  }

  /// Whether this node has a valid position
  bool get hasPosition => lat != null && lon != null && !(lat == 0.0 && lon == 0.0);
}

class NetworkProvider extends ChangeNotifier {
  final List<MeshNode> _nodes = [];
  bool _connected = false;
  String? _transportKind;
  String? _selectedNodeId;

  List<MeshNode> get nodes => List.unmodifiable(_nodes);
  bool get connected => _connected;
  String? get transportKind => _transportKind;
  int get nodeCount => _nodes.length;
  String? get selectedNodeId => _selectedNodeId;

  MeshNode? get selectedNode {
    if (_selectedNodeId == null) return null;
    try {
      return _nodes.firstWhere((n) => n.id == _selectedNodeId);
    } catch (_) {
      return null;
    }
  }

  void setConnected(bool value, {String? transport}) {
    _connected = value;
    _transportKind = transport;
    notifyListeners();
  }

  void updateNodes(List<MeshNode> newNodes) {
    _nodes
      ..clear()
      ..addAll(newNodes);
    notifyListeners();
  }

  void addNode(MeshNode node) {
    // Replace if same id exists
    final idx = _nodes.indexWhere((n) => n.id == node.id);
    if (idx >= 0) {
      _nodes[idx] = node;
    } else {
      _nodes.add(node);
    }
    notifyListeners();
  }

  void removeNode(String id) {
    _nodes.removeWhere((n) => n.id == id);
    if (_selectedNodeId == id) {
      _selectedNodeId = null;
    }
    notifyListeners();
  }

  void selectNode(String? id) {
    _selectedNodeId = id;
    notifyListeners();
  }

  /// Resolve node ID to a display name
  String resolveName(String id) {
    if (id == 'you' || id == '0') return 'You';
    try {
      final node = _nodes.firstWhere((n) => n.id == id);
      if (node.shortName.isNotEmpty) return node.shortName;
      if (node.longName.isNotEmpty) return node.longName;
      return '!${node.id}';
    } catch (_) {
      return '!$id';
    }
  }
}