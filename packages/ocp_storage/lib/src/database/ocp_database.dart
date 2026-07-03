import 'package:isar/isar.dart';
import 'package:ocp_storage/src/schemas/contact_schema.dart';
import 'package:ocp_storage/src/schemas/conversation_schema.dart';
import 'package:ocp_storage/src/schemas/device_schema.dart';
import 'package:ocp_storage/src/schemas/identity_schema.dart';
import 'package:ocp_storage/src/schemas/map_region_schema.dart';
import 'package:ocp_storage/src/schemas/message_schema.dart';
import 'package:ocp_storage/src/schemas/node_position_schema.dart';
import 'package:ocp_storage/src/schemas/workspace_schema.dart';

/// Thin facade over the Isar database.
class OcpDatabase {
  OcpDatabase(this._isar);

  final Isar _isar;

  /// Opens an Isar database at [directoryPath].
  static Future<OcpDatabase> open(String directoryPath) async {
    final isar = await Isar.open(
      [
        ContactSchemaSchema,
        ConversationSchemaSchema,
        DeviceSchemaSchema,
        IdentitySchemaSchema,
        MapRegionSchemaSchema,
        MessageSchemaSchema,
        NodePositionSchemaSchema,
        WorkspaceSchemaSchema,
      ],
      directory: directoryPath,
      name: 'ocp',
    );
    return OcpDatabase(isar);
  }

  /// Opens an in-memory database for tests.
  static Future<OcpDatabase> openMemory() async {
    final isar = await Isar.open(
      [
        ContactSchemaSchema,
        ConversationSchemaSchema,
        DeviceSchemaSchema,
        IdentitySchemaSchema,
        MapRegionSchemaSchema,
        MessageSchemaSchema,
        NodePositionSchemaSchema,
        WorkspaceSchemaSchema,
      ],
      directory: '',
      name: 'ocp_test_${DateTime.now().microsecondsSinceEpoch}',
    );
    return OcpDatabase(isar);
  }

  Isar get isar => _isar;

  IsarCollection<ContactSchema> get contacts => _isar.contactSchemas;

  IsarCollection<ConversationSchema> get conversations =>
      _isar.conversationSchemas;

  IsarCollection<DeviceSchema> get devices => _isar.deviceSchemas;

  IsarCollection<IdentitySchema> get identities => _isar.identitySchemas;

  IsarCollection<MessageSchema> get messages => _isar.messageSchemas;

  IsarCollection<NodePositionSchema> get nodePositions =>
      _isar.nodePositionSchemas;

  IsarCollection<MapRegionSchema> get mapRegions => _isar.mapRegionSchemas;

  IsarCollection<WorkspaceSchema> get workspaces => _isar.workspaceSchemas;

  Future<void> close() => _isar.close();
}
