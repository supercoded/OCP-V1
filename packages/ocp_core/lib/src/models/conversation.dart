/// Conversation domain model.
class Conversation {
  const Conversation({
    required this.conversationId,
    required this.workspaceId,
    required this.title,
    required this.isGroup,
    required this.participantIds,
    required this.createdAt,
    required this.updatedAt,
  });

  final String conversationId;
  final String workspaceId;
  final String title;
  final bool isGroup;
  final List<String> participantIds;
  final DateTime createdAt;
  final DateTime updatedAt;
}
