import 'package:ocp_core/src/repositories/isar/isar_contact_repository.dart';
import 'package:ocp_core/src/repositories/isar/isar_conversation_repository.dart';
import 'package:ocp_core/src/repositories/isar/isar_device_repository.dart';
import 'package:ocp_core/src/repositories/isar/isar_identity_repository.dart';
import 'package:ocp_core/src/repositories/isar/isar_map_region_repository.dart';
import 'package:ocp_core/src/repositories/isar/isar_message_repository.dart';
import 'package:ocp_core/src/repositories/isar/isar_node_position_repository.dart';
import 'package:ocp_core/src/repositories/isar/isar_workspace_repository.dart';
import 'package:ocp_core/src/repositories/repositories.dart';
import 'package:ocp_core/src/services/services.dart';
import 'package:ocp_storage/ocp_storage.dart';

/// Composition root for OCP Core services and repositories.
class OcpCore {
  OcpCore._({
    required this.database,
    required this.contacts,
    required this.conversations,
    required this.devices,
    required this.identities,
    required this.messages,
    required this.positions,
    required this.mapRegions,
    required this.workspaces,
    required this.identityService,
    required this.locationService,
    required this.messagingService,
    required this.notificationService,
    required this.sessionService,
    required this.workspaceService,
    required this.securityService,
  });

  final OcpDatabase database;
  final ContactRepository contacts;
  final ConversationRepository conversations;
  final DeviceRepository devices;
  final IdentityRepository identities;
  final MessageRepository messages;
  final NodePositionRepository positions;
  final MapRegionRepository mapRegions;
  final WorkspaceRepository workspaces;
  final IdentityService identityService;
  final LocationService locationService;
  final MessagingService messagingService;
  final NotificationService notificationService;
  final SessionService sessionService;
  final WorkspaceService workspaceService;
  final SecurityService securityService;

  static Future<OcpCore> create(OcpDatabase database) async {
    final contacts = IsarContactRepository(database);
    final conversations = IsarConversationRepository(database);
    final devices = IsarDeviceRepository(database);
    final identities = IsarIdentityRepository(database);
    final messages = IsarMessageRepository(database);
    final positions = IsarNodePositionRepository(database);
    final mapRegions = IsarMapRegionRepository(database);
    final workspaces = IsarWorkspaceRepository(database);
    final notifications = NotificationService();
    return OcpCore._(
      database: database,
      contacts: contacts,
      conversations: conversations,
      devices: devices,
      identities: identities,
      messages: messages,
      positions: positions,
      mapRegions: mapRegions,
      workspaces: workspaces,
      identityService: IdentityService(identities),
      locationService: LocationService(positions),
      messagingService: MessagingService(messages, notifications),
      notificationService: notifications,
      sessionService: SessionService(),
      workspaceService: WorkspaceService(workspaces, devices),
      securityService: SecurityService(),
    );
  }

  Future<void> dispose() async {
    await locationService.dispose();
    await database.close();
  }
}
