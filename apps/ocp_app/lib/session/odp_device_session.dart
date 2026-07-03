import 'dart:async';

import 'package:ocp_bridge_meshtastic/ocp_bridge_meshtastic.dart';
import 'package:ocp_core/ocp_core.dart';
import 'package:ocp_odp/ocp_odp.dart';
import 'package:ocp_transport/ocp_transport.dart';

/// Mock-first device session: transport ↔ ODP ↔ bridge ↔ messaging/location.
///
/// Owns the live connection after pairing. For the MVP this runs against
/// [MockTransport] peers and [MockOdpDeviceLoop]; the real build swaps in BLE
/// without changing this orchestration logic.
class OdpDeviceSession {
  OdpDeviceSession({
    required OcpTransport transport,
    required MessagingService messaging,
    required LocationService location,
    required SessionService session,
    required this.workspaceId,
    required this.conversationId,
    required this.localSenderId,
    required this.remoteSenderId,
    OdpConnection Function()? connectionFactory,
    MeshtasticBridge? bridge,
  })  : _transport = transport,
        _messaging = messaging,
        _location = location,
        _session = session,
        _connection = (connectionFactory ?? OdpConnection.new)(),
        _bridge = bridge ?? MeshtasticBridge();

  final OcpTransport _transport;
  final MessagingService _messaging;
  final LocationService _location;
  final SessionService _session;
  final OdpConnection _connection;
  final MeshtasticBridge _bridge;

  final String workspaceId;
  final String conversationId;
  final String localSenderId;
  final String remoteSenderId;

  StreamSubscription<List<int>>? _wireSub;
  StreamSubscription<OdpDataPayload>? _dataSub;
  StreamSubscription<OdpState>? _odpStateSub;
  StreamSubscription<TransportState>? _transportStateSub;

  OdpConnection get connection => _connection;
  OcpTransport get transport => _transport;

  /// Opens the transport, runs the ODP handshake, and starts the inbound pump.
  ///
  /// When [skipOdpHandshake] is true (Meshtastic BLE), the transport performs
  /// its own link setup in [OcpTransport.connect] and the ODP state machine is
  /// marked connected without HELLO/CAPABILITY on the wire.
  Future<bool> open({
    required String deviceId,
    bool skipOdpHandshake = false,
  }) async {
    _session.setConnecting(deviceId);
    await _transport.connect();

    if (skipOdpHandshake) {
      _connection.markConnected();
    } else {
      final ok = await _connection.runHandshake(_sendAndReceive);
      if (!ok) {
        _session.setError(deviceId);
        return false;
      }
    }

    _wireSub = _transport.incoming.listen(_connection.feedIncoming);
    _dataSub = _connection.dataFrames.listen(_onDataFrame);
    _odpStateSub = _connection.stateChanges.listen((_) => _syncSessionState());
    _transportStateSub =
        _transport.stateChanges.listen((_) => _syncSessionState());

    _session.setConnected(deviceId);
    await _messaging.flushPending(_sendWireMessage);
    return true;
  }

  /// Re-runs the ODP handshake on an existing transport (Phase 3 reconnect).
  Future<bool> reconnect() async {
    final deviceId = _session.activeDeviceId;
    if (deviceId == null) return false;
    _session.setConnecting(deviceId);

    await _wireSub?.cancel();
    _wireSub = null;

    final ok = await _connection.reconnect(_sendAndReceive);
    if (!ok) {
      _session.setError(deviceId);
      return false;
    }

    _wireSub = _transport.incoming.listen(_connection.feedIncoming);
    _session.setConnected(deviceId);
    await _messaging.flushPending(_sendWireMessage);
    return true;
  }

  /// Queues a message locally and sends it immediately when connected.
  Future<Message> sendText(String body) async {
    final message = await _messaging.sendMessage(
      messageId: DateTime.now().microsecondsSinceEpoch.toString(),
      conversationId: conversationId,
      workspaceId: workspaceId,
      senderId: localSenderId,
      body: body,
    );
    if (_connection.state == OdpState.connected) {
      await _sendWireMessage(message);
      await _messaging.markSent(message.messageId);
    }
    return message;
  }

  Future<void> close() async {
    await _wireSub?.cancel();
    await _dataSub?.cancel();
    await _odpStateSub?.cancel();
    await _transportStateSub?.cancel();
    _connection.disconnect();
    await _transport.disconnect();
    await _session.disconnect();
  }

  void dispose() {
    _connection.dispose();
  }

  Future<List<int>> _sendAndReceive(List<int> outgoing) async {
    final completer = Completer<List<int>>();
    late StreamSubscription<List<int>> sub;
    sub = _transport.incoming.listen(
      (response) {
        sub.cancel();
        if (!completer.isCompleted) completer.complete(response);
      },
      onError: (Object error, StackTrace stack) {
        sub.cancel();
        if (!completer.isCompleted) completer.completeError(error, stack);
      },
    );
    await _transport.send(outgoing);
    return completer.future.timeout(_connection.handshakeTimeout);
  }

  Future<void> _sendWireMessage(Message message) async {
    final frame = _bridge.encodeToOdp(TextBridgeMessage(message.body));
    await _transport.send(frame);
  }

  void _onDataFrame(OdpDataPayload payload) {
    final bridgeMsg = _decodePayload(payload);
    if (bridgeMsg == null) return;

    switch (bridgeMsg) {
      case TextBridgeMessage(:final text):
        unawaited(
          _messaging.ingestIncoming(
            messageId: DateTime.now().microsecondsSinceEpoch.toString(),
            conversationId: conversationId,
            workspaceId: workspaceId,
            senderId: remoteSenderId,
            body: text,
          ),
        );
      case PositionBridgeMessage(:final position):
        final nodeId =
            MeshtasticBridge.decodePositionNodeId(payload.bytes) ??
                remoteSenderId;
        unawaited(
          _location.ingest(
            NodePosition(
              nodeId: nodeId,
              latitude: position.latitude,
              longitude: position.longitude,
              altitude: position.altitudeMeters,
              timestamp: position.time ?? DateTime.now().toUtc(),
              source: PositionSource.direct,
            ),
          ),
        );
    }
  }

  BridgeMessage? _decodePayload(OdpDataPayload payload) {
    switch (payload.port) {
      case OdpPort.textMessage:
        return TextBridgeMessage(String.fromCharCodes(payload.bytes));
      case OdpPort.position:
        final position = MeshtasticBridge.decodePositionPayload(payload.bytes);
        return position == null ? null : PositionBridgeMessage(position);
      case OdpPort.unknown:
        return null;
    }
  }

  void _syncSessionState() {
    final deviceId = _session.activeDeviceId;
    if (deviceId == null) return;
    if (_transport.state == TransportState.error ||
        _connection.state == OdpState.error) {
      _session.setError(deviceId);
    } else if (_connection.state == OdpState.connected &&
        _transport.state == TransportState.connected) {
      _session.setConnected(deviceId);
    }
  }
}
