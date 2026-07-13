class Bookmark {
  final String label;
  final double frequency; // MHz
  final double bandwidth; // kHz
  final String modulation; // AM, FM, SSB, etc.

  const Bookmark({
    required this.label,
    required this.frequency,
    this.bandwidth = 12.5,
    this.modulation = 'FM',
  });

  Bookmark copyWith({
    String? label,
    double? frequency,
    double? bandwidth,
    String? modulation,
  }) {
    return Bookmark(
      label: label ?? this.label,
      frequency: frequency ?? this.frequency,
      bandwidth: bandwidth ?? this.bandwidth,
      modulation: modulation ?? this.modulation,
    );
  }

  /// Frequency as Hz
  double get frequencyHz => frequency * 1e6;

  @override
  String toString() => '$label ${frequency.toStringAsFixed(3)} MHz $modulation';
}