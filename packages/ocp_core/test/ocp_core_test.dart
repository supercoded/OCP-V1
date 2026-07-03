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

  test('location service ingests position history and emits updates', () async {
    final emitted = <NodePosition>[];
    final sub = core.locationService.positionUpdates.listen(emitted.add);

    final base = DateTime.utc(2026);
    for (var i = 0; i < 3; i++) {
      await core.locationService.ingest(
        NodePosition(
          nodeId: 'node-a',
          latitude: 37.0 + i * 0.001,
          longitude: -122.0,
          timestamp: base.add(Duration(seconds: i)),
        ),
      );
    }

    // Let the broadcast stream flush.
    await Future<void>.delayed(Duration.zero);
    expect(emitted, hasLength(3));

    final history = await core.locationService.history('node-a');
    expect(history, hasLength(3));

    final latest = await core.locationService.latest('node-a');
    expect(latest!.latitude, closeTo(37.002, 1e-9));

    await sub.cancel();
  });

  test('location service prunes old fixes', () async {
    final base = DateTime.utc(2026);
    for (var i = 0; i < 4; i++) {
      await core.locationService.ingest(
        NodePosition(
          nodeId: 'node-b',
          latitude: 1,
          longitude: 1,
          timestamp: base.add(Duration(minutes: i)),
        ),
      );
    }
    final removed =
        await core.locationService.prune(base.add(const Duration(minutes: 2)));
    expect(removed, 2);
    expect(await core.locationService.history('node-b'), hasLength(2));
  });

  test('location retention trims to max samples per node', () async {
    final service = LocationService(
      core.positions,
      retentionPolicy: const PositionRetentionPolicy(maxSamplesPerNode: 2),
    );
    final base = DateTime.utc(2026);
    for (var i = 0; i < 5; i++) {
      await service.ingest(
        NodePosition(
          nodeId: 'r',
          latitude: 1,
          longitude: 1,
          timestamp: base.add(Duration(seconds: i)),
        ),
      );
    }
    final history = await service.history('r');
    expect(history, hasLength(2));
    expect(
      history.first.timestamp.toUtc(),
      base.add(const Duration(seconds: 4)),
    );
    await service.dispose();
  });

  test('location retention drops fixes older than max age', () async {
    final now = DateTime.utc(2026, 6, 1);
    final service = LocationService(
      core.positions,
      retentionPolicy: const PositionRetentionPolicy(
        maxSamplesPerNode: null,
        maxAge: Duration(hours: 1),
      ),
      clock: () => now,
    );
    await service.ingest(
      NodePosition(
        nodeId: 'aged',
        latitude: 1,
        longitude: 1,
        timestamp: now.subtract(const Duration(hours: 2)),
      ),
    );
    await service.ingest(
      NodePosition(
        nodeId: 'aged',
        latitude: 1,
        longitude: 1,
        timestamp: now.subtract(const Duration(minutes: 10)),
      ),
    );
    final history = await service.history('aged');
    expect(history, hasLength(1));
    await service.dispose();
  });

  test('map region repository stores tile-pack metadata', () async {
    await core.mapRegions.save(
      MapRegion(
        regionId: 'bay-area',
        minLatitude: 37,
        minLongitude: -123,
        maxLatitude: 38,
        maxLongitude: -122,
        minZoom: 8,
        maxZoom: 14,
        style: 'osm',
        sizeBytes: 2048,
        downloadedAt: DateTime.utc(2026),
        storagePath: '/tiles/bay-area',
      ),
    );
    final region = await core.mapRegions.findById('bay-area');
    expect(region!.maxZoom, 14);
    expect(await core.mapRegions.findAll(), hasLength(1));
  });
}
