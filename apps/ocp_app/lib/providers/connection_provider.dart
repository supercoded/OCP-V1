import 'package:flutter/foundation.dart';

class NodeInfo {
  final String id;
  final String name;
  final String status;

  NodeInfo({required this.id, required this.name, required this.status});
}

class ConnectionProvider extends ChangeNotifier {
  bool _connected = false;
  bool _connecting = false;
  String? _transportKind;
  int _nodeCount = 0;
  final List<NodeInfo> _nodes = [];

  bool get connected => _connected;
  bool get connecting => _connecting;
  String? get transportKind => _transportKind;
  int get nodeCount => _nodeCount;
  List<NodeInfo> get nodes => List.unmodifiable(_nodes);

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
}
