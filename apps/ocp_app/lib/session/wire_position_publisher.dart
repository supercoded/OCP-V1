import 'dart:async';

import 'package:mock_device/mock_device.dart';
import 'package:mock_position_feed/mock_position_feed.dart';
import 'package:ocp_bridge_meshtastic/ocp_bridge_meshtastic.dart';

/// Publishes [MockPositionFeed] samples as POSITION ODP frames over the wire.
///
/// Drives the mock-first location path: feed → mock device loop → ODP session
/// → [LocationService], so Maps consumes wire-sourced positions instead of
/// calling [LocationService.ingest] directly.
class WirePositionPublisher {
  WirePositionPublisher({
    required MockPositionFeed feed,
    required MockOdpDeviceLoop deviceLoop,
    this.tickInterval = const Duration(seconds: 1),
    this.simStep = const Duration(seconds: 5),
  })  : _feed = feed,
        _deviceLoop = deviceLoop;

  final MockPositionFeed _feed;
  final MockOdpDeviceLoop _deviceLoop;
  final Duration tickInterval;
  final Duration simStep;

  Timer? _timer;
  DateTime? _simTime;
  bool _running = false;

  bool get isRunning => _running;

  /// Starts emitting POSITION frames from the feed.
  void start() {
    if (_running) return;
    _running = true;
    _simTime = _feed.epoch;
    unawaited(_tick());
    _timer = Timer.periodic(tickInterval, (_) => _tick());
  }

  /// Stops the publisher.
  void stop() {
    _running = false;
    _timer?.cancel();
    _timer = null;
  }

  Future<void> _tick() async {
    if (!_running || _simTime == null) return;
    _simTime = _simTime!.add(simStep);
    for (final sample in _feed.sampleAt(_simTime!)) {
      await _deviceLoop.emitPosition(
        MeshtasticPosition(
          latitude: sample.latitude,
          longitude: sample.longitude,
          altitudeMeters: sample.altitudeMeters,
          time: sample.timestamp,
        ),
        nodeId: sample.nodeId,
      );
    }
  }
}
