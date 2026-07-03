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
    _notifications.notify(
      id: messageId,
      title: 'Message queued',
      body: body,
    );
    _logger.info('Queued message $messageId');
    return message;
  }

  Future<List<Message>> pendingMessages() => _messages.findPending();

  Future<void> markSent(String messageId) async {
    final message = await _messages.findById(messageId);
    if (message == null) return;
    await _messages.save(
      Message(
        messageId: message.messageId,
        conversationId: message.conversationId,
        workspaceId: message.workspaceId,
        senderId: message.senderId,
        body: message.body,
        attachmentPath: message.attachmentPath,
        status: MessageStatus.sent,
        createdAt: message.createdAt,
        sentAt: DateTime.now().toUtc(),
      ),
    );
  }

  Future<List<Message>> conversationHistory(String conversationId) =>
      _messages.findByConversation(conversationId);
}
