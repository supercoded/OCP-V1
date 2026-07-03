import 'package:benchmark/benchmark.dart';
import 'package:test/test.dart';

void main() {
  test('records fps target', () {
    final harness = BenchmarkHarness();
    harness.recordFps('ui', 60);
    expect(harness.results.first.fps, 60);
  });
}
