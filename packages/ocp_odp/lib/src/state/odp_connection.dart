import 'dart:async';

import 'package:ocp_odp/src/codec/odp_codec.dart';
import 'package:ocp_odp/src/codec/odp_frame.dart';
import 'package:ocp_odp/src/state/odp_state.dart';

/// ODP connection state machine with handshake and version negotiation.
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

  OdpState get state => _state;
  int? get negotiatedVersion => _negotiatedVersion;
  Stream<OdpState> get stateChanges => _stateController.stream;

  List<int> beginHandshake() {
    _setState(OdpState.handshaking);
    _sequence++;
    return _codec.encodeHello(sequence: _sequence);
  }

  bool handleFrame(List<int> raw) {
    final frame = _codec.decode(raw);
    if (frame == null) {
      _setState(OdpState.error);
      return false;
    }
    switch (frame.type) {
      case OdpMessageType.helloAck:
        if (frame.payload.isEmpty) {
          _setState(OdpState.error);
          return false;
        }
        _negotiatedVersion = frame.payload.first;
        _setState(OdpState.connected);
        return true;
      case OdpMessageType.capabilityRsp:
        return _state == OdpState.connected;
      case OdpMessageType.error:
        _setState(OdpState.error);
        return false;
      default:
        return _state == OdpState.connected;
    }
  }

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

  Future<bool> runHandshake(
    Future<List<int>> Function(List<int> outgoing) sendAndReceive,
  ) async {
    try {
      final hello = beginHandshake();
      final ack = await sendAndReceive(hello).timeout(_handshakeTimeout);
      if (!handleFrame(ack)) return false;
      final capReq = requestCapabilities();
      final capRsp = await sendAndReceive(capReq).timeout(_handshakeTimeout);
      return handleFrame(capRsp);
    } on TimeoutException {
      _setState(OdpState.error);
      return false;
    }
  }

  void disconnect() {
    _negotiatedVersion = null;
    _setState(OdpState.disconnected);
  }

  void dispose() => _stateController.close();

  void _setState(OdpState value) {
    _state = value;
    _stateController.add(value);
  }
}
