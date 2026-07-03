import 'package:isar/isar.dart';
import 'package:ocp_storage/src/testing/isar_test_init.dart';
import 'package:ocp_storage/ocp_storage.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    await initializeIsarForTests();
  });

  late OcpDatabase database;

  setUp(() async {
    database = await OcpDatabase.openMemory();
  });

  tearDown(() async {
    await database.close();
  });

  test('persists workspace and message', () async {
    await database.isar.writeTxn(() async {
      await database.workspaces.put(
        WorkspaceSchema()
          ..workspaceId = 'ws-1'
          ..name = 'Default',
      );
      await database.messages.put(
        MessageSchema()
          ..messageId = 'msg-1'
          ..conversationId = 'conv-1'
          ..workspaceId = 'ws-1'
          ..senderId = 'user-1'
          ..body = 'Hello offline',
      );
    });

    final messages = await database.messages.where().findAll();
    expect(messages, hasLength(1));
    expect(messages.first.body, 'Hello offline');
  });
}
