import 'package:isar/isar.dart';

part 'message_schema.g.dart';

enum MessageDeliveryStatus { pending, sent, delivered, failed }

/// Message with offline queue support.
@collection
class MessageSchema {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String messageId;

  @Index()
  late String conversationId;

  @Index()
  late String workspaceId;

  late String senderId;
  late String body;
  String? attachmentPath;
  @enumerated
  MessageDeliveryStatus status = MessageDeliveryStatus.pending;
  DateTime createdAt = DateTime.now().toUtc();
  DateTime? sentAt;
}
