import 'package:isar/isar.dart';

part 'conversation_schema.g.dart';

/// Direct or group conversation thread.
@collection
class ConversationSchema {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String conversationId;

  @Index()
  late String workspaceId;

  late String title;
  bool isGroup = false;
  List<String> participantIds = [];
  DateTime createdAt = DateTime.now().toUtc();
  DateTime updatedAt = DateTime.now().toUtc();
}
