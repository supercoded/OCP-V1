import 'package:ocp_core/src/models/conversation.dart';

/// Conversation storage contract.
abstract class ConversationRepository {
  Future<Conversation?> findById(String conversationId);
  Future<List<Conversation>> findByWorkspace(String workspaceId);
  Future<void> save(Conversation conversation);
  Future<void> delete(String conversationId);
}
