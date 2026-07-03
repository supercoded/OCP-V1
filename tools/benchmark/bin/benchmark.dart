import 'package:benchmark/benchmark.dart';

void main() {
  final harness = BenchmarkHarness();
  harness.recordFps('ui_target', 60);
  for (final result in harness.results) {
    // ignore: avoid_print
    print('${result.label}: ${result.fps ?? result.durationMs}');
  }
}
