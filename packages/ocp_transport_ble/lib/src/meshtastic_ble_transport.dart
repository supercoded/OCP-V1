import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_blue_plus/flutter_blue_plus.dart';
import 'package:logging/logging.dart';
import 'package:ocp_bridge_meshtastic/ocp_bridge_meshtastic.dart';
import 'package:ocp_odp/ocp_odp.dart';
import 'package:ocp_transport/ocp_transport.dart';
import 'package:ocp_transport_ble/src/meshtastic_proto.dart';

/// BLE transport for Meshtastic hardware using the official GATT service.
///
/// Implements [OcpTransport] by translating ODP DATA frames to Meshtastic
/// `ToRadio` protobuf writes and `FromRadio` reads back into ODP frames for
/// [OdpDeviceSession]. The Meshtastic config handshake runs in [connect]; ODP
/// HELLO/CAPABILITY is not sent to the radio (use `skipOdpHandshake` on open).
class MeshtasticBleTransport implements OcpTransport {
  MeshtasticBleTransport({
    required this.deviceId,
    OdpCodec? codec,
    MeshtasticBridge? bridge,
    Logger? logger,
  })  : _codec = codec ?? OdpCodec(),
        _bridge = bridge ?? MeshtasticBridge(),
        _logger = logger ?? Logger('meshtastic-ble');

  final String deviceId;
  final OdpCodec _codec;
  final MeshtasticBridge _bridge;
  final Logger _logger;

  BluetoothDevice? _device;
  BluetoothCharacteristic? _toRadio;
  BluetoothCharacteristic? _fromRadio;
  BluetoothCharacteristic? _fromNum;

  TransportState _state = TransportState.disconnected;
  final _stateController = StreamController<TransportState>.broadcast();
  final _incomingController = StreamController<List<int>>.broadcast();

  StreamSubscription<List<int>>? _fromNumSub;
  StreamSubscription<BluetoothConnectionState>? _connectionSub;
  var _packetId = 1;
  var _draining = false;

  static Guid get _serviceGuid => Guid(MeshtasticBle.serviceUuid);
  static Guid get _toRadioGuid => Guid(MeshtasticBle.toRadioCharacteristic);
  static Guid get _fromRadioGuid => Guid(MeshtasticBle.fromRadioCharacteristic);
  static Guid get _fromNumGuid => Guid(MeshtasticBle.fromNumCharacteristic);

  @override
  String get name => 'ble-meshtastic';

  @override
  TransportState get state => _state;

  @override
  Stream<TransportState> get stateChanges => _stateController.stream;

  @override
  Stream<List<int>> get incoming => _incomingController.stream;

  /// Whether this platform can use flutter_blue_plus (mobile).
  static bool get isSupported =>
      !kIsWeb && (Platform.isAndroid || Platform.isIOS);

  /// Ensures Bluetooth is on and permissions are granted.
  static Future<void> ensureReady() async {
    if (!isSupported) return;
    if (await FlutterBluePlus.isSupported == false) {
      throw StateError('BLE not supported on this platform');
    }
    await FlutterBluePlus.adapterState
        .where((s) => s == BluetoothAdapterState.on)
        .first
        .timeout(const Duration(seconds: 15));
  }

  @override
  Future<void> connect() async {
    if (!isSupported) {
      throw UnsupportedError('Meshtastic BLE requires Android or iOS');
    }
    _setState(TransportState.connecting);
    await ensureReady();

    _device = BluetoothDevice.fromId(deviceId);
    await _device!.connect(timeout: const Duration(seconds: 15));

    _connectionSub ??= _device!.connectionState.listen((connectionState) {
      if (connectionState == BluetoothConnectionState.disconnected) {
        _setState(TransportState.disconnected);
      }
    });

    try {
      await _device!.requestMtu(512);
    } on Object catch (error, stack) {
      _logger.fine('MTU request failed (continuing)', error, stack);
    }

    final services = await _device!.discoverServices();
    final service = services.firstWhere(
      (s) => s.uuid == _serviceGuid,
      orElse: () => throw StateError('Meshtastic GATT service not found'),
    );

    _toRadio = _requireCharacteristic(service, _toRadioGuid);
    _fromRadio = _requireCharacteristic(service, _fromRadioGuid);
    _fromNum = _requireCharacteristic(service, _fromNumGuid);

    await _fromNum!.setNotifyValue(true);
    _fromNumSub ??= _fromNum!.onValueReceived.listen((_) {
      unawaited(_drainFromRadio());
    });

    await _writeToRadio(MeshtasticProto.encodeWantConfig());
    await _drainFromRadio(configSync: true);

    _setState(TransportState.connected);
    _logger.info('Connected to Meshtastic device $deviceId');
  }

  @override
  Future<void> disconnect() async {
    await _fromNumSub?.cancel();
    _fromNumSub = null;
    await _connectionSub?.cancel();
    _connectionSub = null;
    await _device?.disconnect();
    _device = null;
    _toRadio = null;
    _fromRadio = null;
    _fromNum = null;
    _setState(TransportState.disconnected);
  }

  @override
  Future<void> send(List<int> data) async {
    if (_state != TransportState.connected || _toRadio == null) {
      throw StateError('Meshtastic BLE transport not connected');
    }

    final frame = _codec.decode(data);
    if (frame == null || frame.type != OdpMessageType.data) {
      _logger.warning('Ignoring non-DATA ODP frame on BLE send');
      return;
    }

    final payload = OdpDataPayload.decode(frame.payload);
    if (payload == null) return;

    final Uint8List toRadio;
    switch (payload.port) {
      case OdpPort.textMessage:
        final text = String.fromCharCodes(payload.bytes);
        toRadio = MeshtasticProto.encodeTextToRadio(
          text,
          packetId: _nextPacketId(),
        );
      case OdpPort.position:
        final position = MeshtasticBridge.decodePositionPayload(payload.bytes);
        if (position == null) return;
        toRadio = MeshtasticProto.encodePositionToRadio(
          position,
          packetId: _nextPacketId(),
        );
      case OdpPort.unknown:
        return;
    }

    await _writeToRadio(toRadio);
  }

  void dispose() {
    _stateController.close();
    _incomingController.close();
  }

  BluetoothCharacteristic _requireCharacteristic(
    BluetoothService service,
    Guid guid,
  ) {
    return service.characteristics.firstWhere(
      (c) => c.uuid == guid,
      orElse: () => throw StateError('Missing characteristic $guid'),
    );
  }

  Future<void> _writeToRadio(Uint8List bytes) async {
    await _toRadio!.write(bytes, withoutResponse: false);
  }

  Future<void> _drainFromRadio({bool configSync = false}) async {
    if (_draining || _fromRadio == null) return;
    _draining = true;
    try {
      while (true) {
        final chunk = await _fromRadio!.read();
        if (chunk.isEmpty) break;
        final payloads =
            MeshtasticProto.decodeFromRadio(Uint8List.fromList(chunk));
        for (final app in payloads) {
          final odp = _appToOdp(app);
          if (odp != null && !_incomingController.isClosed) {
            _incomingController.add(odp);
          }
        }
        if (configSync && payloads.isEmpty) {
          break;
        }
      }
    } on Object catch (error, stack) {
      _logger.warning('FromRadio drain failed', error, stack);
      if (configSync) rethrow;
    } finally {
      _draining = false;
    }
  }

  List<int>? _appToOdp(MeshtasticAppPayload app) {
    if (app.portnum == MeshtasticProto.portText) {
      return _bridge.encodeToOdp(TextBridgeMessage(utf8.decode(app.payload)));
    }
    if (app.portnum == MeshtasticProto.portPosition) {
      final position = MeshtasticProto.decodePositionPayload(app.payload);
      if (position == null) return null;
      return _bridge.encodePositionToOdp(
        position,
        nodeId: app.fromNode?.toString(),
      );
    }
    return null;
  }

  int _nextPacketId() => _packetId++;

  void _setState(TransportState value) {
    _state = value;
    if (!_stateController.isClosed) {
      _stateController.add(value);
    }
  }
}
