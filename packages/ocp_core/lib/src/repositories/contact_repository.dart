import 'package:ocp_core/src/models/contact.dart';

/// Contact storage contract.
abstract class ContactRepository {
  Future<Contact?> findById(String contactId);
  Future<List<Contact>> findAll();
  Future<void> save(Contact contact);
  Future<void> delete(String contactId);
}
