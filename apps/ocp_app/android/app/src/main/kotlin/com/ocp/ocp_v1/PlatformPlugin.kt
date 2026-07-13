package com.ocp.ocp_v1

import android.bluetooth.BluetoothManager
import android.content.Context
import android.os.Handler
import android.os.Looper
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodChannel

/**
 * Platform plugin for OCP-V1 on Android.
 *
 * Handles MethodChannel calls and EventChannel streams for hardware
 * communication: Meshtastic (BLE/Serial/TCP), RTL-SDR (TCP), RuView,
 * and Baofeng (USB serial).
 *
 * Structure:
 *   MethodChannel:  com.ocp.v1/platform
 *   EventChannels:  com.ocp.v1/platform/state
 *                   com.ocp.v1/platform/messages
 *                   com.ocp.v1/platform/ruview
 *                   com.ocp.v1/platform/rtl
 *                   com.ocp.v1/platform/nodes
 */
class PlatformPlugin(private val context: Context) {

    companion object {
        private const val CHANNEL = "com.ocp.v1/platform"
    }

    private var methodChannel: MethodChannel? = null
    private var stateEventChannel: EventChannel? = null
    private var messageEventChannel: EventChannel? = null
    private var ruViewEventChannel: EventChannel? = null
    private var rtlEventChannel: EventChannel? = null
    private var nodeEventChannel: EventChannel? = null

    // Event sinks
    private var stateSink: EventChannel.EventSink? = null
    private var messageSink: EventChannel.EventSink? = null
    private var ruViewSink: EventChannel.EventSink? = null
    private var rtlSink: EventChannel.EventSink? = null
    private var nodeSink: EventChannel.EventSink? = null

    // Connection state
    private var meshConnected = false
    private var transportKind: String? = null
    private var rtlConnected = false
    private var ruViewRunning = false

    private val handler = Handler(Looper.getMainLooper())

    /**
     * Register this plugin with the Flutter engine.
     */
    fun registerWith(engine: FlutterEngine) {
        methodChannel = MethodChannel(engine.dartExecutor.binaryMessenger, CHANNEL)
            .also { channel ->
                channel.setMethodCallHandler { call, result ->
                    handleMethodCall(call.method, call.arguments, result)
                }
            }

        stateEventChannel = EventChannel(engine.dartExecutor.binaryMessenger, "$CHANNEL/state")
            .also { it.setStreamHandler(StateStreamHandler()) }
        messageEventChannel = EventChannel(engine.dartExecutor.binaryMessenger, "$CHANNEL/messages")
            .also { it.setStreamHandler(MessageStreamHandler()) }
        ruViewEventChannel = EventChannel(engine.dartExecutor.binaryMessenger, "$CHANNEL/ruview")
            .also { it.setStreamHandler(RuViewStreamHandler()) }
        rtlEventChannel = EventChannel(engine.dartExecutor.binaryMessenger, "$CHANNEL/rtl")
            .also { it.setStreamHandler(RtlStreamHandler()) }
        nodeEventChannel = EventChannel(engine.dartExecutor.binaryMessenger, "$CHANNEL/nodes")
            .also { it.setStreamHandler(NodeStreamHandler()) }
    }

    /**
     * Clean up when the engine is detached.
     */
    fun dispose() {
        methodChannel?.setMethodCallHandler(null)
        methodChannel = null
        stateEventChannel = null
        messageEventChannel = null
        ruViewEventChannel = null
        rtlEventChannel = null
        nodeEventChannel = null
    }

    // ── Method call dispatch ───────────────────────────────────────────

    private fun handleMethodCall(
        method: String,
        arguments: Any?,
        result: MethodChannel.Result
    ) {
        @Suppress("UNCHECKED_CAST")
        val params = (arguments as? Map<String, Any>) ?: emptyMap<String, Any>()

        when (method) {
            "connect" -> handleConnect(params, result)
            "disconnect" -> handleDisconnect(result)
            "connectRtl" -> handleConnectRtl(params, result)
            "disconnectRtl" -> handleDisconnectRtl(result)
            "sendMessage" -> handleSendMessage(params, result)
            "getMessageHistory" -> handleGetMessageHistory(result)
            "startRuView" -> handleStartRuView(params, result)
            "stopRuView" -> handleStopRuView(result)
            "startMap" -> handleStartMap(params, result)
            "stopMap" -> handleStopMap(result)
            else -> result.notImplemented()
        }
    }

    // ── Meshtastic ─────────────────────────────────────────────────────

    private fun handleConnect(params: Map<String, Any>, result: MethodChannel.Result) {
        // Determine transport kind
        val kind = when {
            params.containsKey("bleDeviceId") -> "BLE"
            params.containsKey("serialPort") -> "Serial"
            params.containsKey("tcpHost") -> "TCP"
            else -> "Auto"
        }

        // TODO: Implement real BLE/Serial/TCP connection.
        //  For BLE, use Android BluetoothManager to discover and connect.
        //  For Serial, use Android USB Host API or flutter_usb_serial plugin.
        //  For TCP, use java.net.Socket.

        // For now, simulate a successful connection.
        // In production, this would launch a coroutine or thread that manages
        // the actual connection and pushes events through the event sinks.

        meshConnected = true
        transportKind = kind

        // Emit state change
        emitStateChange()

        // Example BLE connection skeleton:
        if (kind == "BLE") {
            try {
                val bluetoothManager = context.getSystemService(Context.BLUETOOTH_SERVICE) as? BluetoothManager
                val adapter = bluetoothManager?.adapter
                if (adapter == null || !adapter.isEnabled) {
                    result.error("BLE_UNAVAILABLE", "Bluetooth is not available or not enabled", null)
                    return
                }
                // TODO: Use adapter.bluetoothLeScanner to scan for Meshtastic devices
                // TODO: Connect to device by MAC address from params["bleDeviceId"]
                result.success(true)
            } catch (e: Exception) {
                result.error("BLE_ERROR", e.message, null)
            }
        } else {
            // TCP or Serial — stub success
            handler.postDelayed({
                emitStateChange()
            }, 500)
            result.success(true)
        }
    }

    private fun handleDisconnect(result: MethodChannel.Result) {
        // TODO: Close the actual BLE/Serial/TCP connection.
        meshConnected = false
        transportKind = null
        emitStateChange()
        result.success(null)
    }

    // ── RTL-SDR ────────────────────────────────────────────────────────

    private fun handleConnectRtl(params: Map<String, Any>, result: MethodChannel.Result) {
        // TODO: On Android, RTL-SDR is typically accessed via USB.
        //  Use Android USB Host API to communicate with the RTL2832U dongle.
        //  For TCP mode (rtl_tcp on another device), use java.net.Socket.
        //
        //  For now, return not-implemented for USB, or attempt TCP if host/port given.

        val host = params["host"] as? String
        val port = (params["port"] as? Number)?.toInt() ?: 1234

        if (host != null) {
            // TCP mode — could connect to remote rtl_tcp server
            // TODO: Implement TCP rtl_tcp client
            result.error("NOT_IMPLEMENTED", "RTL-SDR TCP not yet implemented on Android", null)
        } else {
            result.error("NOT_IMPLEMENTED", "RTL-SDR USB not yet implemented on Android", null)
        }
    }

    private fun handleDisconnectRtl(result: MethodChannel.Result) {
        rtlConnected = false
        result.success(null)
    }

    // ── Messaging ──────────────────────────────────────────────────────

    private fun handleSendMessage(params: Map<String, Any>, result: MethodChannel.Result) {
        if (!meshConnected) {
            result.error("NOT_CONNECTED", "No device connected", null)
            return
        }
        // TODO: Encode message via Meshtastic protobuf and send through the transport.
        //  For now, echo back success.
        result.success(true)
    }

    private fun handleGetMessageHistory(result: MethodChannel.Result) {
        // TODO: Return cached message history.
        result.success(emptyList<Any>())
    }

    // ── RuView ─────────────────────────────────────────────────────────

    private fun handleStartRuView(params: Map<String, Any>, result: MethodChannel.Result) {
        // TODO: On Android, RuView sensing would use Wi-Fi RTT or
        //  a local RuView server. Not yet implemented.
        result.error("NOT_IMPLEMENTED", "RuView not yet implemented on Android", null)
    }

    private fun handleStopRuView(result: MethodChannel.Result) {
        ruViewRunning = false
        result.success(null)
    }

    // ── Maps ────────────────────────────────────────────────────────────

    private fun handleStartMap(params: Map<String, Any>, result: MethodChannel.Result) {
        // On mobile, maps are handled directly by flutter_map + MBTiles/PMTiles.
        // No server needed. Return success with port 0 to indicate no server.
        result.success(null)
    }

    private fun handleStopMap(result: MethodChannel.Result) {
        result.success(null)
    }

    // ── Event emission helpers ──────────────────────────────────────────

    private fun emitStateChange() {
        val event = mapOf(
            "connected" to meshConnected,
            "transportKind" to (transportKind ?: ""),
            "nodeCount" to 0
        )
        handler.post { stateSink?.success(event) }
    }

    // ── Stream handlers ─────────────────────────────────────────────────

    inner class StateStreamHandler : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            stateSink = events
            // Send initial state
            handler.post { events?.success(mapOf(
                "connected" to meshConnected,
                "transportKind" to (transportKind ?: ""),
                "nodeCount" to 0
            )) }
        }
        override fun onCancel(arguments: Any?) { stateSink = null }
    }

    inner class MessageStreamHandler : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            messageSink = events
        }
        override fun onCancel(arguments: Any?) { messageSink = null }
    }

    inner class RuViewStreamHandler : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            ruViewSink = events
        }
        override fun onCancel(arguments: Any?) { ruViewSink = null }
    }

    inner class RtlStreamHandler : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            rtlSink = events
        }
        override fun onCancel(arguments: Any?) { rtlSink = null }
    }

    inner class NodeStreamHandler : EventChannel.StreamHandler {
        override fun onListen(arguments: Any?, events: EventChannel.EventSink?) {
            nodeSink = events
        }
        override fun onCancel(arguments: Any?) { nodeSink = null }
    }
}