import 'package:flutter/foundation.dart';
import '../models/blip.dart';

class SonarProvider extends ChangeNotifier {
  double sweepAngle = 0.0; // radians
  double rangeKm = 10.0;
  double sweepSpeed = 4.0; // seconds per revolution
  List<Blip> blips = [];

  void updateSweep(double delta) {
    sweepAngle = (sweepAngle + delta) % (2 * 3.1415926535);
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
}