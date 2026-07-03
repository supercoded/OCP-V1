import 'package:ocp_core/src/models/conversation.dart';
import 'package:ocp_core/src/repositories/conversation_repository.dart';
import 'package:ocp_storage/ocp_storage.dart';

/// Isar-backed [ConversationRepository].
class IsarConversationRepository implements ConversationRepository {
  IsarConversationRepository(OcpDatabase database)
      : _stores = OcpStores(database);

  final OcpStores _stores;

  @override
  Future<void> delete(String conversationId) async {
    final existing = await _stores.conversationById(conversationId);
    if (existing != null) {
      await _stores.deleteConversation(existing.id);
    }
  }

  @override
  Future<Conversation?> findById(String conversationId) async {
    final schema = await _stores.conversationById(conversationId);
    return schema == null ? null : _toModel(schema);
  }

  @override
  Future<List<Conversation>> findByWorkspace(String workspaceId) async {
    final schemas = await _stores.conversationsForWorkspace(workspaceId);
    return schemas.map(_toModel).toList();
  }

  @override
  Future<void> save(Conversation conversation) async {
    final existing = await _stores.conversationById(conversation.conversationId);
    final schema = _toSchema(conversation);
    if (existing != null) {
      schema.id = existing.id;
    }
    await _stores.putConversation(schema);
  }

  Conversation _toModel(ConversationSchema schema) => Conversation(
        conversationId: schema.conversationId,
        workspaceId: schema.workspaceId,
        title: schema.title,
        isGroup: schema.isGroup,
        participantIds: List<String>.from(schema.participantIds),
        createdAt: schema.createdAt,
        updatedAt: schema.updatedAt,
      );

  ConversationSchema _toSchema(Conversation conversation) =>
      ConversationSchema()
        ..conversationId = conversation.conversationId
        ..workspaceId = conversation.workspaceId
        ..title = conversation.title
        ..isGroup = conversation.isGroup
        ..participantIds = List<String>.from(conversation.participantIds)
        ..createdAt = conversation.createdAt
        ..updatedAt = conversation.updatedAt;
}
