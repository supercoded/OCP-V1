import 'package:mock_position_feed/mock_position_feed.dart';

/// Prints a short scripted position history for the demo feed.
Future<void> main(List<String> args) async {
  final feed = MockPositionFeed.demo();
  final from = feed.epoch;
  final to = feed.epoch.add(const Duration(seconds: 30));
  final history = feed.history(from: from, to: to);

  for (final entry in history.entries) {
    // ignore: avoid_print
    print('== ${entry.key} ==');
    for (final sample in entry.value) {
      // ignore: avoid_print
      print(
        '  t=${sample.timestamp.toIso8601String()} '
        'lat=${sample.latitude.toStringAsFixed(6)} '
        'lon=${sample.longitude.toStringAsFixed(6)} '
        'spd=${sample.speedMps?.toStringAsFixed(1) ?? '-'}',
      );
    }
  }
}
