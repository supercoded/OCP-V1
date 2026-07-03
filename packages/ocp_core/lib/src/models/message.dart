/// Message delivery status.
enum MessageStatus { pending, sent, delivered, failed }

/// Message domain model.
class Message {
  const Message({
    required this.messageId,
    required this.conversationId,
    required this.workspaceId,
    required this.senderId,
    required this.body,
    this.attachmentPath,
    required this.status,
    required this.createdAt,
    this.sentAt,
  });

  final String messageId;
  final String conversationId;
  final String workspaceId;
  final String senderId;
  final String body;
  final String? attachmentPath;
  final MessageStatus status;
  final DateTime createdAt;
  final DateTime? sentAt;
}
