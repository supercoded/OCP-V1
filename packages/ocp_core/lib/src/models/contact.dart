/// Contact domain model.
class Contact {
  const Contact({
    required this.contactId,
    required this.displayName,
    this.publicKey,
    required this.createdAt,
    required this.updatedAt,
  });

  final String contactId;
  final String displayName;
  final String? publicKey;
  final DateTime createdAt;
  final DateTime updatedAt;
}
