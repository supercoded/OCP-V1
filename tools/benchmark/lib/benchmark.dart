/// Performance metrics collected during QA.
class PerformanceMetrics {
  PerformanceMetrics({
    required this.label,
    required this.durationMs,
    this.fps,
  });

  final String label;
  final double durationMs;
  final double? fps;
}

/// Simple benchmark harness for launch/write latency measurements.
class BenchmarkHarness {
  final List<PerformanceMetrics> _results = [];

  List<PerformanceMetrics> get results => List.unmodifiable(_results);

  Future<PerformanceMetrics> measure(
    String label,
    Future<void> Function() action,
  ) async {
    final stopwatch = Stopwatch()..start();
    await action();
    stopwatch.stop();
    final metric = PerformanceMetrics(
      label: label,
      durationMs: stopwatch.elapsedMicroseconds / 1000,
    );
    _results.add(metric);
    return metric;
  }

  PerformanceMetrics recordFps(String label, double fps) {
    final metric = PerformanceMetrics(label: label, durationMs: 0, fps: fps);
    _results.add(metric);
    return metric;
  }
}
