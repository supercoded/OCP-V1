import 'package:ocp_core/src/models/contact.dart';
import 'package:ocp_core/src/repositories/contact_repository.dart';
import 'package:ocp_storage/ocp_storage.dart';

/// Isar-backed [ContactRepository].
class IsarContactRepository implements ContactRepository {
  IsarContactRepository(OcpDatabase database) : _stores = OcpStores(database);

  final OcpStores _stores;

  @override
  Future<void> delete(String contactId) async {
    final existing = await _stores.contactById(contactId);
    if (existing != null) {
      await _stores.deleteContact(existing.id);
    }
  }

  @override
  Future<Contact?> findById(String contactId) async {
    final schema = await _stores.contactById(contactId);
    return schema == null ? null : _toModel(schema);
  }

  @override
  Future<List<Contact>> findAll() async {
    final schemas = await _stores.allContacts();
    return schemas.map(_toModel).toList();
  }

  @override
  Future<void> save(Contact contact) async {
    final existing = await _stores.contactById(contact.contactId);
    final schema = _toSchema(contact);
    if (existing != null) {
      schema.id = existing.id;
    }
    await _stores.putContact(schema);
  }

  Contact _toModel(ContactSchema schema) => Contact(
        contactId: schema.contactId,
        displayName: schema.displayName,
        publicKey: schema.publicKey,
        createdAt: schema.createdAt,
        updatedAt: schema.updatedAt,
      );

  ContactSchema _toSchema(Contact contact) => ContactSchema()
    ..contactId = contact.contactId
    ..displayName = contact.displayName
    ..publicKey = contact.publicKey
    ..createdAt = contact.createdAt
    ..updatedAt = contact.updatedAt;
}
