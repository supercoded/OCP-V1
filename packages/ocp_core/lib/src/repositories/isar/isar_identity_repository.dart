import 'package:ocp_core/src/models/identity.dart';
import 'package:ocp_core/src/repositories/identity_repository.dart';
import 'package:ocp_storage/ocp_storage.dart';

/// Isar-backed [IdentityRepository].
class IsarIdentityRepository implements IdentityRepository {
  IsarIdentityRepository(OcpDatabase database) : _stores = OcpStores(database);

  final OcpStores _stores;

  @override
  Future<void> delete(String identityId) async {
    final existing = await _stores.identityById(identityId);
    if (existing != null) {
      await _stores.deleteIdentity(existing.id);
    }
  }

  @override
  Future<Identity?> findActive() async {
    final schema = await _stores.activeIdentity();
    return schema == null ? null : _toModel(schema);
  }

  @override
  Future<Identity?> findById(String identityId) async {
    final schema = await _stores.identityById(identityId);
    return schema == null ? null : _toModel(schema);
  }

  @override
  Future<List<Identity>> findAll() async {
    final schemas = await _stores.allIdentities();
    return schemas.map(_toModel).toList();
  }

  @override
  Future<void> save(Identity identity) async {
    if (identity.isActive) {
      final active = await _stores.allIdentities();
      for (final item in active.where((i) => i.isActive && i.identityId != identity.identityId)) {
        item.isActive = false;
        await _stores.putIdentity(item);
      }
    }
    await _saveIdentity(identity);
  }

  Future<void> _saveIdentity(Identity identity) async {
    final existing = await _stores.identityById(identity.identityId);
    final schema = _toSchema(identity);
    if (existing != null) {
      schema.id = existing.id;
    }
    await _stores.putIdentity(schema);
  }

  Identity _toModel(IdentitySchema schema) => Identity(
        identityId: schema.identityId,
        displayName: schema.displayName,
        isActive: schema.isActive,
        exportMetadata: schema.exportMetadata,
        createdAt: schema.createdAt,
        updatedAt: schema.updatedAt,
      );

  IdentitySchema _toSchema(Identity identity) => IdentitySchema()
    ..identityId = identity.identityId
    ..displayName = identity.displayName
    ..isActive = identity.isActive
    ..exportMetadata = identity.exportMetadata
    ..createdAt = identity.createdAt
    ..updatedAt = identity.updatedAt;
}
