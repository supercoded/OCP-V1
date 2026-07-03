/// Identity profile domain model.
class Identity {
  const Identity({
    required this.identityId,
    required this.displayName,
    required this.isActive,
    this.exportMetadata,
    required this.createdAt,
    required this.updatedAt,
  });

  final String identityId;
  final String displayName;
  final bool isActive;
  final String? exportMetadata;
  final DateTime createdAt;
  final DateTime updatedAt;
}
