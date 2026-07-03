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

  test('stores node position history and reads latest per node', () async {
    final stores = OcpStores(database);
    final base = DateTime.utc(2026);
    for (var i = 0; i < 3; i++) {
      await stores.putNodePosition(
        NodePositionSchema()
          ..nodeId = 'node-a'
          ..lat = 37.0 + i * 0.001
          ..lon = -122.0
          ..timestamp = base.add(Duration(seconds: i)),
      );
    }
    await stores.putNodePosition(
      NodePositionSchema()
        ..nodeId = 'node-b'
        ..lat = 40.0
        ..lon = -73.0
        ..timestamp = base
        ..source = PositionSource.relayed,
    );

    final history = await stores.positionsForNode('node-a');
    expect(history, hasLength(3));
    expect(
      history.first.timestamp.toUtc(),
      base.add(const Duration(seconds: 2)),
    );

    final latest = await stores.latestPositionForNode('node-a');
    expect(latest!.lat, closeTo(37.002, 1e-9));

    final allLatest = await stores.allLatestPositions();
    expect(allLatest, hasLength(2));
  });

  test('prunes node positions older than a cutoff', () async {
    final stores = OcpStores(database);
    final base = DateTime.utc(2026);
    for (var i = 0; i < 5; i++) {
      await stores.putNodePosition(
        NodePositionSchema()
          ..nodeId = 'node-a'
          ..lat = 1
          ..lon = 1
          ..timestamp = base.add(Duration(minutes: i)),
      );
    }

    final removed =
        await stores.prunePositionsBefore(base.add(const Duration(minutes: 3)));
    expect(removed, 3);
    final remaining = await stores.positionsForNode('node-a');
    expect(remaining, hasLength(2));
  });

  test('tracks map region tile-pack metadata', () async {
    final stores = OcpStores(database);
    await stores.putMapRegion(
      MapRegionSchema()
        ..regionId = 'bay-area'
        ..minLat = 37.0
        ..minLon = -123.0
        ..maxLat = 38.0
        ..maxLon = -122.0
        ..minZoom = 8
        ..maxZoom = 14
        ..style = 'osm'
        ..sizeBytes = 1024
        ..downloadedAt = DateTime.utc(2026)
        ..storagePath = '/tiles/bay-area',
    );

    final region = await stores.mapRegionById('bay-area');
    expect(region, isNotNull);
    expect(region!.maxZoom, 14);
    expect(await stores.allMapRegions(), hasLength(1));
  });
}
