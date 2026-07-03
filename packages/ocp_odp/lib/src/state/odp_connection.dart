import 'dart:async';

import 'package:ocp_odp/src/codec/odp_codec.dart';
import 'package:ocp_odp/src/codec/odp_frame.dart';
import 'package:ocp_odp/src/codec/odp_port.dart';
import 'package:ocp_odp/src/state/odp_state.dart';

/// ODP connection state machine with handshake, DATA lifecycle, and reconnect.
class OdpConnection {
  OdpConnection({
    OdpCodec? codec,
    Duration handshakeTimeout = const Duration(seconds: 5),
  })  : _codec = codec ?? OdpCodec(),
        _handshakeTimeout = handshakeTimeout;

  final OdpCodec _codec;
  final Duration _handshakeTimeout;
  OdpState _state = OdpState.disconnected;
  int _sequence = 0;
  int? _negotiatedVersion;
  final _stateController = StreamController<OdpState>.broadcast();
  final _dataController = StreamController<OdpDataPayload>.broadcast();

  OdpState get state => _state;
  int? get negotiatedVersion => _negotiatedVersion;
  Duration get handshakeTimeout => _handshakeTimeout;
  Stream<OdpState> get stateChanges => _stateController.stream;

  /// Emits port-tagged DATA payloads received while [state] is [OdpState.connected].
  Stream<OdpDataPayload> get dataFrames => _dataController.stream;

  List<int> beginHandshake() {
    _setState(OdpState.handshaking);
    _sequence++;
    return _codec.encodeHello(sequence: _sequence);
  }

  /// Processes an inbound wire frame. Returns `false` on decode/handshake errors.
  bool feedIncoming(List<int> raw) {
    final frame = _codec.decode(raw);
    if (frame == null) {
      _setState(OdpState.error);
      return false;
    }
    switch (frame.type) {
      case OdpMessageType.helloAck:
        if (_state != OdpState.handshaking || frame.payload.isEmpty) {
          _setState(OdpState.error);
          return false;
        }
        _negotiatedVersion = frame.payload.first;
        _setState(OdpState.connected);
        return true;
      case OdpMessageType.capabilityRsp:
        return _state == OdpState.connected;
      case OdpMessageType.data:
        if (_state != OdpState.connected) return false;
        final payload = OdpDataPayload.decode(frame.payload);
        if (payload != null && !_dataController.isClosed) {
          _dataController.add(payload);
        }
        return true;
      case OdpMessageType.error:
        _setState(OdpState.error);
        return false;
      default:
        return _state == OdpState.connected;
    }
  }

  /// Alias for [feedIncoming] (legacy tests and pairing flow).
  bool handleFrame(List<int> raw) => feedIncoming(raw);

  List<int> requestCapabilities() {
    _sequence++;
    return _codec.encode(
      OdpFrame(
        version: OdpCodec.protocolVersion,
        type: OdpMessageType.capabilityReq,
        sequence: _sequence,
        payload: const [],
      ),
    );
  }

  /// Encodes a port-tagged DATA frame for sending on the wire.
  List<int> sendPortData({required OdpPort port, required List<int> bytes}) {
    _sequence++;
    return _codec.encodePortData(
      sequence: _sequence,
      port: port,
      bytes: bytes,
    );
  }

  Future<bool> runHandshake(
    Future<List<int>> Function(List<int> outgoing) sendAndReceive,
  ) async {
    try {
      final hello = beginHandshake();
      final ack = await sendAndReceive(hello).timeout(_handshakeTimeout);
      if (!feedIncoming(ack)) return false;
      final capReq = requestCapabilities();
      final capRsp = await sendAndReceive(capReq).timeout(_handshakeTimeout);
      return feedIncoming(capRsp);
    } on TimeoutException {
      _setState(OdpState.error);
      return false;
    }
  }

  /// Re-runs the handshake after [OdpState.error] or [OdpState.disconnected].
  ///
  /// No-op when already [OdpState.connected]. Phase 3 will add session-token
  /// resume; for now reconnect is a full HELLO + CAPABILITY exchange.
  Future<bool> reconnect(
    Future<List<int>> Function(List<int> outgoing) sendAndReceive,
  ) async {
    if (_state == OdpState.connected) return true;
    _negotiatedVersion = null;
    return runHandshake(sendAndReceive);
  }

  /// Marks the connection established without an ODP wire handshake.
  ///
  /// Used when the transport is Meshtastic BLE (config sync replaces HELLO).
  void markConnected({int negotiatedVersion = 1}) {
    _negotiatedVersion = negotiatedVersion;
    _setState(OdpState.connected);
  }

  void disconnect() {
    _negotiatedVersion = null;
    _setState(OdpState.disconnected);
  }

  void dispose() {
    _dataController.close();
    _stateController.close();
  }

  void _setState(OdpState value) {
    _state = value;
    if (!_stateController.isClosed) {
      _stateController.add(value);
    }
  }
}
