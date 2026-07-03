import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:ocp_core/src/errors/ocp_exception.dart';
import 'package:ocp_core/src/logging/ocp_logger.dart';
import 'package:ocp_core/src/models/identity.dart';
import 'package:ocp_core/src/repositories/identity_repository.dart';

/// Manages local identity profiles, import/export, and active profile selection.
class IdentityService {
  IdentityService(this._repository, {Logger? logger})
      : _logger = logger ?? ocpLogger('identity');

  final IdentityRepository _repository;
  final Logger _logger;

  Future<Identity?> activeIdentity() => _repository.findActive();

  Future<List<Identity>> listProfiles() => _repository.findAll();

  Future<Identity> createProfile({
    required String identityId,
    required String displayName,
    bool makeActive = false,
  }) async {
    final now = DateTime.now().toUtc();
    final identity = Identity(
      identityId: identityId,
      displayName: displayName,
      isActive: makeActive,
      createdAt: now,
      updatedAt: now,
    );
    await _repository.save(identity);
    _logger.info('Created identity profile $identityId');
    return identity;
  }

  Future<void> setActive(String identityId) async {
    final identity = await _repository.findById(identityId);
    if (identity == null) {
      throw OcpException('Identity not found', code: 'identity_not_found');
    }
    await _repository.save(
      Identity(
        identityId: identity.identityId,
        displayName: identity.displayName,
        isActive: true,
        exportMetadata: identity.exportMetadata,
        createdAt: identity.createdAt,
        updatedAt: DateTime.now().toUtc(),
      ),
    );
  }

  /// Exports profile metadata as JSON (keys handled in security phase).
  Future<String> exportProfile(String identityId) async {
    final identity = await _repository.findById(identityId);
    if (identity == null) {
      throw OcpException('Identity not found', code: 'identity_not_found');
    }
    return jsonEncode({
      'identityId': identity.identityId,
      'displayName': identity.displayName,
      'exportedAt': DateTime.now().toUtc().toIso8601String(),
    });
  }

  Future<Identity> importProfile(String jsonPayload) async {
    final map = jsonDecode(jsonPayload) as Map<String, dynamic>;
    final identityId = map['identityId'] as String;
    final displayName = map['displayName'] as String;
    return createProfile(identityId: identityId, displayName: displayName);
  }
}
