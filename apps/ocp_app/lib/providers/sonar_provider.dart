import 'dart:async';
import 'dart:math';
import 'package:flutter/foundation.dart';
import '../models/blip.dart';
import '../services/platform_service.dart';

class SonarProvider extends ChangeNotifier {
  final PlatformService? _platformService;
  StreamSubscription<Map<String, dynamic>>? _ruViewSubscription;
  StreamSubscription<Map<String, dynamic>>? _nodeSubscription;

  double sweepAngle = 0.0; // radians
  double rangeKm = 10.0;
  double sweepSpeed = 4.0; // seconds per revolution
  List<Blip> blips = [];

  // Reference position for bearing calculation (own position)
  double? _ownLat;
  double? _ownLon;

  SonarProvider({PlatformService? platformService}) : _platformService = platformService {
    _listenToPlatform();
  }

  void _listenToPlatform() {
    if (_platformService == null) return;

    // Listen to RuView sensing events for proximity blips
    _ruViewSubscription = _platformService.onRuViewSensing.listen((event) {
      final nodeId = event['nodeId']?.toString() ?? '';
      final x = (event['x'] as num?)?.toDouble() ?? 0.0;
      final y = (event['y'] as num?)?.toDouble() ?? 0.0;
      final _rssi = (event['rssi'] as num?)?.toDouble();

      // Convert RuView coordinates to a bearing/range
      final bearing = _xyToBearing(x, y);
      final range = _xyToRange(x, y);

      final blip = Blip(
        id: 'ruview_$nodeId',
        label: nodeId.isNotEmpty ? nodeId : 'RV',
        bearing: bearing,
        range: range.clamp(0.0, 1.0),
        timestamp: DateTime.now(),
      );
      _upsertBlip(blip);
    });

    // Listen to node updates for mesh node blips
    _nodeSubscription = _platformService.onNodeUpdate.listen((event) {
      final id = event['id']?.toString() ?? '';
      final lat = (event['lat'] as num?)?.toDouble();
      final lon = (event['lon'] as num?)?.toDouble();
      final snr = (event['snr'] as num?)?.toDouble() ?? 0.0;
      final shortName = event['shortName'] as String? ?? id;
      final longName = event['longName'] as String? ?? shortName;

      if (lat != null && lon != null && _ownLat != null && _ownLon != null) {
        // Calculate bearing and range from our position to the node
        final bearing = _calculateBearing(_ownLat!, _ownLon!, lat, lon);
        final distanceKm = _calculateDistance(_ownLat!, _ownLon!, lat, lon);
        final range = (distanceKm / rangeKm).clamp(0.0, 1.0);

        final blip = Blip(
          id: 'mesh_$id',
          label: shortName.isNotEmpty ? shortName : longName,
          bearing: bearing,
          range: range,
          timestamp: DateTime.now(),
        );
        _upsertBlip(blip);
      } else {
        // No position data — place at a bearing based on node ID hash
        final bearing = (id.hashCode.abs() % 360).toDouble();
        final range = 0.3 + (snr.abs() % 0.5);

        final blip = Blip(
          id: 'mesh_$id',
          label: shortName.isNotEmpty ? shortName : longName,
          bearing: bearing,
          range: range.clamp(0.0, 1.0),
          timestamp: DateTime.now(),
        );
        _upsertBlip(blip);
      }
    });
  }

  void _upsertBlip(Blip blip) {
    final idx = blips.indexWhere((b) => b.id == blip.id);
    if (idx >= 0) {
      blips[idx] = blip;
    } else {
      blips = [...blips, blip];
    }
    notifyListeners();
  }

  /// Convert RuView x,y coordinates to bearing (degrees).
  /// Assuming x is east, y is north (standard Cartesian).
  double _xyToBearing(double x, double y) {
    final radians = atan2(x, y); // clockwise from north
    return (radians * 180 / pi + 360) % 360;
  }

  /// Convert RuView x,y coordinates to normalized range.
  /// Assuming coordinates are in meters, normalize to rangeKm.
  double _xyToRange(double x, double y) {
    final distanceM = sqrt(x * x + y * y);
    return (distanceM / 1000.0 / rangeKm).clamp(0.0, 1.0);
  }

  /// Calculate bearing between two lat/lon points in degrees (0-360).
  double _calculateBearing(double lat1, double lon1, double lat2, double lon2) {
    final dLon = _toRad(lon2 - lon1);
    final y = sin(dLon) * cos(_toRad(lat2));
    final x = cos(_toRad(lat1)) * sin(_toRad(lat2)) -
        sin(_toRad(lat1)) * cos(_toRad(lat2)) * cos(dLon);
    final bearing = atan2(y, x);
    return ((_toDeg(bearing) + 360) % 360);
  }

  /// Calculate distance between two lat/lon points in km (Haversine).
  double _calculateDistance(double lat1, double lon1, double lat2, double lon2) {
    const r = 6371; // Earth radius in km
    final dLat = _toRad(lat2 - lat1);
    final dLon = _toRad(lon2 - lon1);
    final a = sin(dLat / 2) * sin(dLat / 2) +
        cos(_toRad(lat1)) * cos(_toRad(lat2)) * sin(dLon / 2) * sin(dLon / 2);
    final c = 2 * atan2(sqrt(a), sqrt(1 - a));
    return r * c;
  }

  double _toRad(double deg) => deg * pi / 180;
  double _toDeg(double rad) => rad * 180 / pi;

  void updateSweep(double delta) {
    sweepAngle = (sweepAngle + delta) % (2 * pi);
    notifyListeners();
  }

  void setRange(double km) {
    rangeKm = km;
    notifyListeners();
  }

  void setSweepSpeed(double seconds) {
    sweepSpeed = seconds;
    notifyListeners();
  }

  void addBlip(Blip blip) {
    blips = [...blips, blip];
    notifyListeners();
  }

  void removeBlip(String id) {
    blips = blips.where((b) => b.id != id).toList();
    notifyListeners();
  }

  void clearBlips() {
    blips = [];
    notifyListeners();
  }

  /// Remove blips older than 10 seconds
  void pruneStaleBlips() {
    final now = DateTime.now();
    blips = blips.where((b) => now.difference(b.timestamp).inSeconds < 10).toList();
    notifyListeners();
  }

  /// Set own position for bearing calculations.
  void setOwnPosition(double lat, double lon) {
    _ownLat = lat;
    _ownLon = lon;
  }

  @override
  void dispose() {
    _ruViewSubscription?.cancel();
    _nodeSubscription?.cancel();
    super.dispose();
  }
}