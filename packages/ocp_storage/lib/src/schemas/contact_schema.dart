import 'package:isar/isar.dart';

part 'contact_schema.g.dart';

/// Address book contact.
@collection
class ContactSchema {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String contactId;

  late String displayName;
  String? publicKey;
  DateTime createdAt = DateTime.now().toUtc();
  DateTime updatedAt = DateTime.now().toUtc();
}
