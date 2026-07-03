import 'dart:async';

import 'package:logging/logging.dart';
import 'package:ocp_core/src/logging/ocp_logger.dart';
import 'package:ocp_core/src/models/message.dart';
import 'package:ocp_core/src/repositories/message_repository.dart';
import 'package:ocp_core/src/services/notification_service.dart';

/// Orchestrates messaging with offline queue support.
class MessagingService {
  MessagingService(
    this._messages,
    this._notifications, {
    Logger? logger,
  }) : _logger = logger ?? ocpLogger('messaging');

  final MessageRepository _messages;
  final NotificationService _notifications;
  final Logger _logger;
  final StreamController<Message> _updates =
      StreamController<Message>.broadcast();

  /// Emits whenever a message is queued, sent, or received.
  Stream<Message> get messageUpdates => _updates.stream;

  Future<Message> sendMessage({
    required String messageId,
    required String conversationId,
    required String workspaceId,
    required String senderId,
    required String body,
    String? attachmentPath,
  }) async {
    final message = Message(
      messageId: messageId,
      conversationId: conversationId,
      workspaceId: workspaceId,
      senderId: senderId,
      body: body,
      attachmentPath: attachmentPath,
      status: MessageStatus.pending,
      createdAt: DateTime.now().toUtc(),
    );
    await _messages.save(message);
    _updates.add(message);
    _notifications.notify(
      id: messageId,
      title: 'Message queued',
      body: body,
    );
    _logger.info('Queued message $messageId');
    return message;
  }

  /// Persists an inbound wire message (already decoded from ODP/bridge).
  Future<Message> ingestIncoming({
    required String messageId,
    required String conversationId,
    required String workspaceId,
    required String senderId,
    required String body,
  }) async {
    final now = DateTime.now().toUtc();
    final message = Message(
      messageId: messageId,
      conversationId: conversationId,
      workspaceId: workspaceId,
      senderId: senderId,
      body: body,
      status: MessageStatus.delivered,
      createdAt: now,
      sentAt: now,
    );
    await _messages.save(message);
    _updates.add(message);
    _notifications.notify(
      id: messageId,
      title: 'Message received',
      body: body,
    );
    _logger.info('Received message $messageId from $senderId');
    return message;
  }

  Future<List<Message>> pendingMessages() => _messages.findPending();

  /// Sends each pending message through [sendWire] and marks it sent on success.
  ///
  /// Stops at the first failure so ordering is preserved for retry on reconnect.
  Future<int> flushPending(
    Future<void> Function(Message message) sendWire,
  ) async {
    final pending = await _messages.findPending();
    var sent = 0;
    for (final message in pending) {
      try {
        await sendWire(message);
        await markSent(message.messageId);
        sent++;
      } on Object catch (error, stack) {
        _logger.warning('Failed to send ${message.messageId}', error, stack);
        break;
      }
    }
    return sent;
  }

  Future<void> markSent(String messageId) async {
    final message = await _messages.findById(messageId);
    if (message == null) return;
    final updated = Message(
      messageId: message.messageId,
      conversationId: message.conversationId,
      workspaceId: message.workspaceId,
      senderId: message.senderId,
      body: message.body,
      attachmentPath: message.attachmentPath,
      status: MessageStatus.sent,
      createdAt: message.createdAt,
      sentAt: DateTime.now().toUtc(),
    );
    await _messages.save(updated);
    _updates.add(updated);
  }

  Future<List<Message>> conversationHistory(String conversationId) =>
      _messages.findByConversation(conversationId);

  Future<void> dispose() => _updates.close();
}
