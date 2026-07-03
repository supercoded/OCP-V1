import 'package:isar/isar.dart';
import 'package:ocp_storage/src/schemas/contact_schema.dart';
import 'package:ocp_storage/src/schemas/conversation_schema.dart';
import 'package:ocp_storage/src/schemas/device_schema.dart';
import 'package:ocp_storage/src/schemas/identity_schema.dart';
import 'package:ocp_storage/src/schemas/map_region_schema.dart';
import 'package:ocp_storage/src/schemas/message_schema.dart';
import 'package:ocp_storage/src/schemas/node_position_schema.dart';
import 'package:ocp_storage/src/schemas/workspace_schema.dart';
import 'package:ocp_storage/src/database/ocp_database.dart';

/// Low-level Isar queries (kept in storage package for generated extensions).
class OcpStores {
  OcpStores(this._database);

  final OcpDatabase _database;

  Future<ContactSchema?> contactById(String id) =>
      _database.contacts.getByContactId(id);

  Future<List<ContactSchema>> allContacts() =>
      _database.contacts.where().findAll();

  Future<void> putContact(ContactSchema schema) async {
    await _database.isar.writeTxn(() async {
      await _database.contacts.put(schema);
    });
  }

  Future<void> deleteContact(Id isarId) async {
    await _database.isar.writeTxn(() async {
      await _database.contacts.delete(isarId);
    });
  }

  Future<ConversationSchema?> conversationById(String id) =>
      _database.conversations.getByConversationId(id);

  Future<List<ConversationSchema>> conversationsForWorkspace(String workspaceId) =>
      _database.conversations.filter().workspaceIdEqualTo(workspaceId).findAll();

  Future<void> putConversation(ConversationSchema schema) async {
    await _database.isar.writeTxn(() async {
      await _database.conversations.put(schema);
    });
  }

  Future<void> deleteConversation(Id isarId) async {
    await _database.isar.writeTxn(() async {
      await _database.conversations.delete(isarId);
    });
  }

  Future<DeviceSchema?> deviceById(String id) =>
      _database.devices.getByDeviceId(id);

  Future<List<DeviceSchema>> devicesForWorkspace(String workspaceId) =>
      _database.devices.filter().workspaceIdEqualTo(workspaceId).findAll();

  Future<void> putDevice(DeviceSchema schema) async {
    await _database.isar.writeTxn(() async {
      await _database.devices.put(schema);
    });
  }

  Future<void> deleteDevice(Id isarId) async {
    await _database.isar.writeTxn(() async {
      await _database.devices.delete(isarId);
    });
  }

  Future<IdentitySchema?> identityById(String id) =>
      _database.identities.getByIdentityId(id);

  Future<IdentitySchema?> activeIdentity() =>
      _database.identities.filter().isActiveEqualTo(true).findFirst();

  Future<List<IdentitySchema>> allIdentities() =>
      _database.identities.where().findAll();

  Future<void> putIdentity(IdentitySchema schema) async {
    await _database.isar.writeTxn(() async {
      await _database.identities.put(schema);
    });
  }

  Future<void> deleteIdentity(Id isarId) async {
    await _database.isar.writeTxn(() async {
      await _database.identities.delete(isarId);
    });
  }

  Future<MessageSchema?> messageById(String id) =>
      _database.messages.getByMessageId(id);

  Future<List<MessageSchema>> messagesForConversation(String conversationId) =>
      _database.messages.filter().conversationIdEqualTo(conversationId).findAll();

  Future<List<MessageSchema>> pendingMessages() =>
      _database.messages.filter().statusEqualTo(MessageDeliveryStatus.pending).findAll();

  Future<void> putMessage(MessageSchema schema) async {
    await _database.isar.writeTxn(() async {
      await _database.messages.put(schema);
    });
  }

  Future<void> deleteMessage(Id isarId) async {
    await _database.isar.writeTxn(() async {
      await _database.messages.delete(isarId);
    });
  }

  Future<void> putNodePosition(NodePositionSchema schema) async {
    await _database.isar.writeTxn(() async {
      await _database.nodePositions.put(schema);
    });
  }

  /// Most recent [limit] fixes for [nodeId], newest first.
  Future<List<NodePositionSchema>> positionsForNode(
    String nodeId, {
    int limit = 50,
  }) =>
      _database.nodePositions
          .filter()
          .nodeIdEqualTo(nodeId)
          .sortByTimestampDesc()
          .limit(limit)
          .findAll();

  Future<NodePositionSchema?> latestPositionForNode(String nodeId) =>
      _database.nodePositions
          .filter()
          .nodeIdEqualTo(nodeId)
          .sortByTimestampDesc()
          .findFirst();

  Future<List<NodePositionSchema>> allLatestPositions() async {
    final all = await _database.nodePositions.where().findAll();
    final latest = <String, NodePositionSchema>{};
    for (final p in all) {
      final current = latest[p.nodeId];
      if (current == null || p.timestamp.isAfter(current.timestamp)) {
        latest[p.nodeId] = p;
      }
    }
    return latest.values.toList();
  }

  /// Retention hook (Phase 2): drop fixes older than [cutoff].
  Future<int> prunePositionsBefore(DateTime cutoff) {
    return _database.isar.writeTxn(() {
      return _database.nodePositions
          .filter()
          .timestampLessThan(cutoff)
          .deleteAll();
    });
  }

  /// Retention hook (Phase 2): keep only the newest [maxSamples] fixes for
  /// [nodeId], deleting the rest. Returns the count removed.
  Future<int> trimNodePositions(String nodeId, int maxSamples) async {
    if (maxSamples < 0) return 0;
    final ordered = await _database.nodePositions
        .filter()
        .nodeIdEqualTo(nodeId)
        .sortByTimestampDesc()
        .findAll();
    if (ordered.length <= maxSamples) return 0;
    final staleIds = ordered.sublist(maxSamples).map((p) => p.id).toList();
    return _database.isar.writeTxn(
      () => _database.nodePositions.deleteAll(staleIds),
    );
  }

  Future<MapRegionSchema?> mapRegionById(String id) =>
      _database.mapRegions.getByRegionId(id);

  Future<List<MapRegionSchema>> allMapRegions() =>
      _database.mapRegions.where().findAll();

  Future<void> putMapRegion(MapRegionSchema schema) async {
    await _database.isar.writeTxn(() async {
      await _database.mapRegions.put(schema);
    });
  }

  Future<void> deleteMapRegion(Id isarId) async {
    await _database.isar.writeTxn(() async {
      await _database.mapRegions.delete(isarId);
    });
  }

  Future<WorkspaceSchema?> workspaceById(String id) =>
      _database.workspaces.getByWorkspaceId(id);

  Future<List<WorkspaceSchema>> allWorkspaces() =>
      _database.workspaces.where().findAll();

  Future<void> putWorkspace(WorkspaceSchema schema) async {
    await _database.isar.writeTxn(() async {
      await _database.workspaces.put(schema);
    });
  }

  Future<void> deleteWorkspace(Id isarId) async {
    await _database.isar.writeTxn(() async {
      await _database.workspaces.delete(isarId);
    });
  }
}
