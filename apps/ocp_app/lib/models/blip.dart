class Blip {
  final String id;
  final String label;
  final double bearing; // degrees 0-360
  final double range; // 0.0-1.0 normalized
  final DateTime timestamp;
  final bool isHighlighted;

  const Blip({
    required this.id,
    required this.label,
    required this.bearing,
    required this.range,
    required this.timestamp,
    this.isHighlighted = false,
  });

  Blip copyWith({
    String? id,
    String? label,
    double? bearing,
    double? range,
    DateTime? timestamp,
    bool? isHighlighted,
  }) {
    return Blip(
      id: id ?? this.id,
      label: label ?? this.label,
      bearing: bearing ?? this.bearing,
      range: range ?? this.range,
      timestamp: timestamp ?? this.timestamp,
      isHighlighted: isHighlighted ?? this.isHighlighted,
    );
  }

  /// Returns age in seconds
  double get ageSeconds =>
      DateTime.now().difference(timestamp).inMilliseconds / 1000.0;

  /// Opacity based on age — fades over 10 seconds
  double get opacity {
    const fadeDuration = 10.0;
    final age = ageSeconds;
    if (age >= fadeDuration) return 0.0;
    return 1.0 - (age / fadeDuration);
  }
}