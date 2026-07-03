import 'package:isar/isar.dart';

part 'identity_schema.g.dart';

/// Local identity profile.
@collection
class IdentitySchema {
  Id id = Isar.autoIncrement;

  @Index(unique: true)
  late String identityId;

  late String displayName;
  bool isActive = false;
  String? exportMetadata;
  DateTime createdAt = DateTime.now().toUtc();
  DateTime updatedAt = DateTime.now().toUtc();
}
