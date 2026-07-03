import 'package:isar/isar.dart';
import 'package:ocp_core/ocp_core.dart';
import 'package:ocp_storage/ocp_storage.dart';
import 'package:ocp_storage/src/testing/isar_test_init.dart';
import 'package:test/test.dart';

void main() {
  setUpAll(() async {
    await initializeIsarForTests();
  });

  late OcpCore core;

  setUp(() async {
    final db = await OcpDatabase.openMemory();
    core = await OcpCore.create(db);
  });

  tearDown(() async {
    await core.dispose();
  });

  test('identity service manages profiles', () async {
    await core.identityService.createProfile(
      identityId: 'id-1',
      displayName: 'Alice',
      makeActive: true,
    );
    final active = await core.identityService.activeIdentity();
    expect(active?.displayName, 'Alice');
  });

  test('messaging service queues offline messages', () async {
    await core.messagingService.sendMessage(
      messageId: 'm-1',
      conversationId: 'c-1',
      workspaceId: 'w-1',
      senderId: 'id-1',
      body: 'offline',
    );
    final pending = await core.messagingService.pendingMessages();
    expect(pending, hasLength(1));
    expect(pending.first.status, MessageStatus.pending);
  });

  test('workspace service assigns devices', () async {
    final now = DateTime.now().toUtc();
    final suffix = now.microsecondsSinceEpoch.toString();
    final workspaceId = 'w-$suffix';
    final deviceId = 'd-$suffix';
    await core.workspaces.save(
      Workspace(
        workspaceId: workspaceId,
        name: 'Lab',
        assignedDeviceIds: const [],
        settingsJson: '{}',
        createdAt: now,
        updatedAt: now,
      ),
    );
    await core.devices.save(
      Device(
        deviceId: deviceId,
        workspaceId: workspaceId,
        name: 'Radio',
        capabilities: const ['lora'],
        isPaired: true,
        createdAt: now,
        updatedAt: now,
      ),
    );
    await core.workspaceService.assignDevice(
      workspaceId: workspaceId,
      deviceId: deviceId,
    );
    final workspace = await core.workspaces.findById(workspaceId);
    expect(workspace?.assignedDeviceIds, contains(deviceId));
  });

  test('security service detects replay', () {
    expect(core.securityService.registerSequence(1), isTrue);
    expect(core.securityService.registerSequence(1), isFalse);
  });
}
