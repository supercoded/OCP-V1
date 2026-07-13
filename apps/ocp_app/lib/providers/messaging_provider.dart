import 'package:flutter/foundation.dart';

class Message {
  final int id;
  final String text;
  final String from; // node id or 'you'
  final String? to; // destination node id, null = broadcast
  final int channel;
  final DateTime timestamp;
  final bool outgoing;

  const Message({
    required this.id,
    required this.text,
    required this.from,
    this.to,
    required this.channel,
    required this.timestamp,
    required this.outgoing,
  });
}

class ChannelInfo {
  final int id;
  final String name;

  const ChannelInfo({required this.id, required this.name});
}

class MessagingProvider extends ChangeNotifier {
  static const List<ChannelInfo> channels = [
    ChannelInfo(id: 0, name: 'LongFast'),
    ChannelInfo(id: 1, name: 'Tactical'),
    ChannelInfo(id: 2, name: 'Channel 2'),
    ChannelInfo(id: 3, name: 'Channel 3'),
    ChannelInfo(id: 4, name: 'Channel 4'),
    ChannelInfo(id: 5, name: 'Channel 5'),
    ChannelInfo(id: 6, name: 'Channel 6'),
    ChannelInfo(id: 7, name: 'Channel 7'),
  ];

  int _selectedChannel = 0;
  final List<Message> _messages = [];
  String? _sendError;
  bool _connected = false;
  String? _transportKind;
  int _nextId = 1;

  int get selectedChannel => _selectedChannel;
  List<Message> get messages => List.unmodifiable(_messages);
  String? get sendError => _sendError;
  bool get connected => _connected;
  String? get transportKind => _transportKind;

  /// Messages for a specific channel
  List<Message> messagesForChannel(int channel) {
    return _messages.where((m) => m.channel == channel).toList();
  }

  /// Unread count for a channel (received, non-outgoing messages)
  int unreadCount(int channel) {
    return _messages.where((m) => m.channel == channel && !m.outgoing).length;
  }

  /// Last message for a channel
  Message? lastMessageForChannel(int channel) {
    final channelMsgs = messagesForChannel(channel);
    return channelMsgs.isNotEmpty ? channelMsgs.last : null;
  }

  void selectChannel(int channel) {
    _selectedChannel = channel;
    notifyListeners();
  }

  void setConnected(bool value, {String? transport}) {
    _connected = value;
    _transportKind = transport;
    notifyListeners();
  }

  /// Send a message. Returns true on success.
  bool sendMessage({
    required String text,
    required int channel,
    String? destinationNodeId,
  }) {
    if (!_connected) {
      _sendError = 'No device connected';
      notifyListeners();
      _clearErrorAfterDelay();
      return false;
    }
    if (text.trim().isEmpty) return false;

    final msg = Message(
      id: _nextId++,
      text: text.trim(),
      from: 'you',
      to: destinationNodeId,
      channel: channel,
      timestamp: DateTime.now(),
      outgoing: true,
    );
    _messages.add(msg);
    _sendError = null;
    notifyListeners();
    return true;
  }

  /// Simulate receiving a message (for testing)
  void receiveMessage({
    required String text,
    required String from,
    int channel = 0,
  }) {
    final msg = Message(
      id: _nextId++,
      text: text,
      from: from,
      channel: channel,
      timestamp: DateTime.now(),
      outgoing: false,
    );
    _messages.add(msg);
    notifyListeners();
  }

  void clearSendError() {
    _sendError = null;
    notifyListeners();
  }

  void _clearErrorAfterDelay() {
    Future.delayed(const Duration(seconds: 5), () {
      _sendError = null;
      notifyListeners();
    });
  }
}