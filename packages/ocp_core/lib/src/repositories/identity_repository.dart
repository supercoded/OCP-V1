import 'package:ocp_core/src/models/identity.dart';

/// Identity storage contract.
abstract class IdentityRepository {
  Future<Identity?> findById(String identityId);
  Future<List<Identity>> findAll();
  Future<Identity?> findActive();
  Future<void> save(Identity identity);
  Future<void> delete(String identityId);
}
