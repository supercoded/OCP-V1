import 'package:ocp_core/src/models/message.dart';
import 'package:ocp_core/src/repositories/message_repository.dart';
import 'package:ocp_storage/ocp_storage.dart';

/// Isar-backed [MessageRepository].
class IsarMessageRepository implements MessageRepository {
  IsarMessageRepository(OcpDatabase database) : _stores = OcpStores(database);

  final OcpStores _stores;

  @override
  Future<void> delete(String messageId) async {
    final existing = await _stores.messageById(messageId);
    if (existing != null) {
      await _stores.deleteMessage(existing.id);
    }
  }

  @override
  Future<Message?> findById(String messageId) async {
    final schema = await _stores.messageById(messageId);
    return schema == null ? null : _toModel(schema);
  }

  @override
  Future<List<Message>> findByConversation(String conversationId) async {
    final schemas = await _stores.messagesForConversation(conversationId);
    return schemas.map(_toModel).toList();
  }

  @override
  Future<List<Message>> findPending() async {
    final schemas = await _stores.pendingMessages();
    return schemas.map(_toModel).toList();
  }

  @override
  Future<void> save(Message message) async {
    final existing = await _stores.messageById(message.messageId);
    final schema = _toSchema(message);
    if (existing != null) {
      schema.id = existing.id;
    }
    await _stores.putMessage(schema);
  }

  Message _toModel(MessageSchema schema) => Message(
        messageId: schema.messageId,
        conversationId: schema.conversationId,
        workspaceId: schema.workspaceId,
        senderId: schema.senderId,
        body: schema.body,
        attachmentPath: schema.attachmentPath,
        status: _mapStatus(schema.status),
        createdAt: schema.createdAt,
        sentAt: schema.sentAt,
      );

  MessageSchema _toSchema(Message message) => MessageSchema()
    ..messageId = message.messageId
    ..conversationId = message.conversationId
    ..workspaceId = message.workspaceId
    ..senderId = message.senderId
    ..body = message.body
    ..attachmentPath = message.attachmentPath
    ..status = _mapStatusBack(message.status)
    ..createdAt = message.createdAt
    ..sentAt = message.sentAt;

  MessageStatus _mapStatus(MessageDeliveryStatus status) => switch (status) {
        MessageDeliveryStatus.pending => MessageStatus.pending,
        MessageDeliveryStatus.sent => MessageStatus.sent,
        MessageDeliveryStatus.delivered => MessageStatus.delivered,
        MessageDeliveryStatus.failed => MessageStatus.failed,
      };

  MessageDeliveryStatus _mapStatusBack(MessageStatus status) => switch (status) {
        MessageStatus.pending => MessageDeliveryStatus.pending,
        MessageStatus.sent => MessageDeliveryStatus.sent,
        MessageStatus.delivered => MessageDeliveryStatus.delivered,
        MessageStatus.failed => MessageDeliveryStatus.failed,
      };
}
