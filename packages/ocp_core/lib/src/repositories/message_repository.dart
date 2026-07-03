import 'package:ocp_core/src/models/message.dart';

/// Message storage contract with offline queue support.
abstract class MessageRepository {
  Future<Message?> findById(String messageId);
  Future<List<Message>> findByConversation(String conversationId);
  Future<List<Message>> findPending();
  Future<void> save(Message message);
  Future<void> delete(String messageId);
}
