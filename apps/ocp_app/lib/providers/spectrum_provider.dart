import 'dart:async';
import 'package:flutter/foundation.dart';
import '../models/bookmark.dart';
import '../services/platform_service.dart';
import '../services/storage_service.dart';

class SpectrumProvider extends ChangeNotifier {
  final PlatformService? _platformService;
  final StorageService? _storageService;
  StreamSubscription<Map<String, dynamic>>? _rtlSubscription;

  // Spectrum data
  List<double> _spectrumData = [];
  List<List<double>> _waterfallData = [];
  int _fftSize = 1024;
  double _centerFreqHz = 100e6;
  double _sampleRate = 2.4e6;

  // VFO
  double _vfoFreqHz = 100e6;
  double _vfoBandwidthHz = 15000;
  bool _showVfo = true;

  // Receiver settings
  String _gainMode = 'auto'; // 'auto' or 'manual'
  double _gainValue = 0.0;

  // Connection
  bool _rtlConnected = false;
  String _rtlHost = 'localhost';
  int _rtlPort = 1234;
  String? _rtlError;

  // Mock source
  bool _mockSource = false;

  // Recording
  bool _isRecording = false;
  Duration _recordingDuration = Duration.zero;
  DateTime? _recordingStart;

  // Peak hold
  bool _peakHoldEnabled = false;
  List<double> _peakHoldData = [];

  // Bookmarks
  final List<Bookmark> _bookmarks = [
    const Bookmark(label: 'FM Broadcast', frequency: 100.000, bandwidth: 200, modulation: 'WFM'),
    const Bookmark(label: 'Aviation', frequency: 122.750, bandwidth: 25, modulation: 'AM'),
    const Bookmark(label: 'NOAA Weather', frequency: 162.400, bandwidth: 25, modulation: 'WFM'),
    const Bookmark(label: 'Marine VHF', frequency: 156.800, bandwidth: 25, modulation: 'FM'),
    const Bookmark(label: 'GMRS', frequency: 462.5625, bandwidth: 20, modulation: 'FM'),
  ];

  // Getters
  List<double> get spectrumData => _spectrumData;
  List<List<double>> get waterfallData => _waterfallData;
  int get fftSize => _fftSize;
  double get centerFreqHz => _centerFreqHz;
  double get sampleRate => _sampleRate;
  double get vfoFreqHz => _vfoFreqHz;
  double get vfoBandwidthHz => _vfoBandwidthHz;
  bool get showVfo => _showVfo;
  String get gainMode => _gainMode;
  double get gainValue => _gainValue;
  bool get rtlConnected => _rtlConnected;
  String get rtlHost => _rtlHost;
  int get rtlPort => _rtlPort;
  String? get rtlError => _rtlError;
  bool get mockSource => _mockSource;
  bool get isRecording => _isRecording;
  Duration get recordingDuration => _recordingDuration;
  DateTime? get recordingStart => _recordingStart;
  bool get peakHoldEnabled => _peakHoldEnabled;
  List<double> get peakHoldData => _peakHoldData;
  List<Bookmark> get bookmarks => List.unmodifiable(_bookmarks);

  // Center freq in MHz for display
  double get centerFreqMHz => _centerFreqHz / 1e6;
  double get vfoFreqMHz => _vfoFreqHz / 1e6;

  SpectrumProvider({PlatformService? platformService, StorageService? storageService})
      : _platformService = platformService,
        _storageService = storageService {
    _listenToPlatform();
    _loadBookmarks();
  }

  // ── Bookmark persistence ────────────────────────────────────────────

  Future<void> _loadBookmarks() async {
    if (_storageService == null) return;
    try {
      final list = await _storageService!.getJsonList(StorageKeys.bookmarks);
      if (list != null && list.isNotEmpty) {
        _bookmarks
          ..clear()
          ..addAll(list.map((m) => Bookmark(
                label: m['label'] as String? ?? '',
                frequency: (m['frequency'] as num?)?.toDouble() ?? 0.0,
                bandwidth: (m['bandwidth'] as num?)?.toDouble() ?? 12.5,
                modulation: m['modulation'] as String? ?? 'FM',
              )));
        debugPrint('[SpectrumProvider] Loaded ${_bookmarks.length} bookmarks from storage');
        notifyListeners();
      }
    } catch (e) {
      debugPrint('[SpectrumProvider] Failed to load bookmarks: $e');
    }
  }

  Future<void> saveBookmarks() async {
    if (_storageService == null) return;
    try {
      final list = _bookmarks.map((b) => {
            'label': b.label,
            'frequency': b.frequency,
            'bandwidth': b.bandwidth,
            'modulation': b.modulation,
          }).toList();
      await _storageService!.setJsonList(StorageKeys.bookmarks, list);
      debugPrint('[SpectrumProvider] Saved ${_bookmarks.length} bookmarks');
    } catch (e) {
      debugPrint('[SpectrumProvider] Failed to save bookmarks: $e');
    }
  }

  void _listenToPlatform() {
    if (_platformService == null) return;

    _rtlSubscription = _platformService!.onRtlSpectrum.listen((event) {
      final centerFreq = (event['centerFreq'] as num?)?.toDouble() ?? _centerFreqHz;
      final sampleRate = (event['sampleRate'] as num?)?.toDouble() ?? _sampleRate;
      final fft = (event['fftSize'] as num?)?.toInt() ?? _fftSize;
      final magnitudes = event['magnitudes'];

      List<double> data;
      if (magnitudes is List) {
        data = magnitudes.map((e) => (e as num).toDouble()).toList();
      } else {
        return; // No valid data
      }

      updateSpectrumData(data, centerFreq, sampleRate, fft);
    });
  }

  // Setters
  void setVfoFreq(double hz) {
    _vfoFreqHz = hz;
    notifyListeners();
  }

  void setVfoBandwidth(double hz) {
    _vfoBandwidthHz = hz;
    notifyListeners();
  }

  void setShowVfo(bool show) {
    _showVfo = show;
    notifyListeners();
  }

  void setGainMode(String mode) {
    _gainMode = mode;
    notifyListeners();
  }

  void setGainValue(double value) {
    _gainValue = value;
    notifyListeners();
  }

  void setCenterFreqMHz(double mHz) {
    _centerFreqHz = mHz * 1e6;
    notifyListeners();
  }

  void setRtlHost(String host) {
    _rtlHost = host;
  }

  void setRtlPort(int port) {
    _rtlPort = port;
  }

  void setPeakHoldEnabled(bool enabled) {
    _peakHoldEnabled = enabled;
    if (!enabled) {
      _peakHoldData = [];
    }
    notifyListeners();
  }

  // Connection
  void connectRtl() {
    _rtlConnected = true;
    _rtlError = null;
    notifyListeners();
  }

  void disconnectRtl() {
    _rtlConnected = false;
    _spectrumData = [];
    _waterfallData = [];
    _peakHoldData = [];
    _isRecording = false;
    _recordingStart = null;
    _recordingDuration = Duration.zero;
    _mockSource = false;
    notifyListeners();
  }

  void setRtlError(String? error) {
    _rtlError = error;
    notifyListeners();
  }

  void startMockSource() {
    _mockSource = true;
    _rtlConnected = true;
    _rtlError = null;
    _generateMockData();
    notifyListeners();
  }

  void stopMockSource() {
    _mockSource = false;
    _rtlConnected = false;
    _spectrumData = [];
    _waterfallData = [];
    _peakHoldData = [];
    notifyListeners();
  }

  // Recording
  void startRecording() {
    _isRecording = true;
    _recordingStart = DateTime.now();
    _recordingDuration = Duration.zero;
    notifyListeners();
  }

  void stopRecording() {
    _isRecording = false;
    _recordingStart = null;
    notifyListeners();
  }

  void updateRecordingDuration() {
    if (_isRecording && _recordingStart != null) {
      _recordingDuration = DateTime.now().difference(_recordingStart!);
      notifyListeners();
    }
  }

  // Bookmarks — auto-save on every mutation
  void addBookmark(Bookmark bookmark) {
    _bookmarks.add(bookmark);
    notifyListeners();
    saveBookmarks();
  }

  void removeBookmarkAt(int index) {
    if (index >= 0 && index < _bookmarks.length) {
      _bookmarks.removeAt(index);
      notifyListeners();
      saveBookmarks();
    }
  }

  void updateBookmark(int index, Bookmark bookmark) {
    if (index >= 0 && index < _bookmarks.length) {
      _bookmarks[index] = bookmark;
      notifyListeners();
      saveBookmarks();
    }
  }

  // Update spectrum data (called from external source or platform stream)
  void updateSpectrumData(List<double> data, double centerHz, double sRate, int fft) {
    _spectrumData = data;
    _centerFreqHz = centerHz;
    _sampleRate = sRate;
    _fftSize = fft;

    // Update waterfall history
    if (data.isNotEmpty) {
      _waterfallData.add(List.from(data));
      // Keep last 200 waterfall rows
      if (_waterfallData.length > 200) {
        _waterfallData = _waterfallData.sublist(_waterfallData.length - 200);
      }
    }

    // Update peak hold
    if (_peakHoldEnabled && data.isNotEmpty) {
      if (_peakHoldData.isEmpty || _peakHoldData.length != data.length) {
        _peakHoldData = List.from(data);
      } else {
        for (int i = 0; i < data.length; i++) {
          if (data[i] > _peakHoldData[i]) {
            _peakHoldData[i] = data[i];
          } else {
            _peakHoldData[i] -= 0.002; // slow decay
          }
        }
      }
    }

    notifyListeners();
  }

  // Generate mock spectrum data for testing
  void _generateMockData() {
    const bins = 512;
    final data = List<double>.filled(bins, -80.0);
    final rng = DateTime.now().millisecondsSinceEpoch;

    // Add a few simulated peaks
    for (int i = 0; i < bins; i++) {
      // Base noise floor
      data[i] = -80 + (i * 7 % 11 - 5) * 0.5;

      // Peak near center (simulated signal)
      final centerDist = (i - bins ~/ 2).abs();
      if (centerDist < 15) {
        data[i] += 40 * (1 - centerDist / 15.0);
      }

      // Peak at 1/3
      final thirdDist = (i - bins ~/ 3).abs();
      if (thirdDist < 8) {
        data[i] += 25 * (1 - thirdDist / 8.0);
      }

      // Small random variation
      data[i] += ((rng + i * 13) % 7 - 3) * 0.3;
    }

    updateSpectrumData(data, _centerFreqHz, _sampleRate, bins);
  }

  /// Re-generate mock data (call on a timer for animation)
  void tickMockData() {
    if (!_mockSource) return;
    _generateMockData();
  }

  @override
  void dispose() {
    _rtlSubscription?.cancel();
    super.dispose();
  }
}