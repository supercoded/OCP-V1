/**
 * OCP-V1 Bridge Server
 *
 * WebSocket + HTTP bridge that connects the Flutter desktop app to the
 * existing Node.js OCP packages.  Runs on localhost:18790.
 *
 * Protocol:
 *   Client → Server:  { type: "command", id: <int>, method: <string>, params: {...} }
 *   Server → Client:  { type: "response", id: <int>, success: <bool>, ...result }
 *   Server → Client:  { type: "event", event: <string>, data: {...} }
 *
 * Events pushed to Flutter:
 *   stateChange   – connection state, transportKind, nodeCount
 *   messageReceived – incoming text message
 *   nodeUpdate     – network node added/updated
 *   ruViewSensing  – RuView presence data
 *   rtlSpectrum    – FFT spectrum frame
 */

import { createServer } from "http";
import { WebSocketServer } from "ws";
import { pathToFileURL } from "url";
import { dirname, resolve } from "path";
import { fileURLToPath } from "url";

const __dirname = dirname(fileURLToPath(import.meta.url));

// ── Resolve monorepo packages ────────────────────────────────────────────
// The bridge lives at apps/ocp_app/bridge/; monorepo root is ../../../
const MONO_ROOT = resolve(__dirname, "..", "..", "..");

async function loadPackages() {
  const pkgs = {};

  // @ocp/bridge-meshtastic
  try {
    const mod = await import(
      pathToFileURL(resolve(MONO_ROOT, "packages/ocp_bridge_meshtastic/src/index.js")).href
    );
    pkgs.meshtastic = mod;
    console.log("[bridge] ✓ @ocp/bridge-meshtastic loaded");
  } catch (e) {
    console.warn("[bridge] ⚠ @ocp/bridge-meshtastic not available:", e.message);
  }

  // @ocp/network
  try {
    const mod = await import(
      pathToFileURL(resolve(MONO_ROOT, "packages/ocp_network/src/index.js")).href
    );
    pkgs.network = mod;
    console.log("[bridge] ✓ @ocp/network loaded");
  } catch (e) {
    console.warn("[bridge] ⚠ @ocp/network not available:", e.message);
  }

  // @ocp/tools-rtlsdr
  try {
    const mod = await import(
      pathToFileURL(resolve(MONO_ROOT, "packages/ocp_tools_rtlsdr/src/index.js")).href
    );
    pkgs.rtlsdr = mod;
    console.log("[bridge] ✓ @ocp/tools-rtlsdr loaded");
  } catch (e) {
    console.warn("[bridge] ⚠ @ocp/tools-rtlsdr not available:", e.message);
  }

  // @ocp/tools-ruview
  try {
    const mod = await import(
      pathToFileURL(resolve(MONO_ROOT, "packages/ocp_tools_ruview/src/ruviewClient.js")).href
    );
    pkgs.ruview = mod;
    console.log("[bridge] ✓ @ocp/tools-ruview loaded");
  } catch (e) {
    console.warn("[bridge] ⚠ @ocp/tools-ruview not available:", e.message);
  }

  // @ocp/maps
  try {
    const mod = await import(
      pathToFileURL(resolve(MONO_ROOT, "packages/ocp_maps/src/index.js")).href
    );
    pkgs.maps = mod;
    console.log("[bridge] ✓ @ocp/maps loaded");
  } catch (e) {
    console.warn("[bridge] ⚠ @ocp/maps not available:", e.message);
  }

  // @ocp/bridge-baofeng
  try {
    const mod = await import(
      pathToFileURL(resolve(MONO_ROOT, "packages/ocp_bridge_baofeng/src/index.js")).href
    );
    pkgs.baofeng = mod;
    console.log("[bridge] ✓ @ocp/bridge-baofeng loaded");
  } catch (e) {
    console.warn("[bridge] ⚠ @ocp/bridge-baofeng not available:", e.message);
  }

  return pkgs;
}

// ── Bridge state ──────────────────────────────────────────────────────────
const state = {
  // Meshtastic
  meshConnected: false,
  meshTransportKind: null,
  meshNodeCount: 0,
  meshTransport: null,
  networkState: null,

  // RTL-SDR
  rtlConnected: false,
  rtlClient: null,
  spectrumProcessor: null,

  // RuView
  ruViewConnected: false,
  ruViewClient: null,

  // Map
  mapServer: null,
  mapPort: null,

  // Messages
  messageHistory: [],
};

// ── Send helper ──────────────────────────────────────────────────────────
function sendResponse(ws, id, result) {
  ws.send(
    JSON.stringify({
      type: "response",
      id,
      ...result,
    })
  );
}

function sendEvent(ws, event, data) {
  ws.send(
    JSON.stringify({
      type: "event",
      event,
      data,
    })
  );
}

function broadcastEvent(wss, event, data) {
  const msg = JSON.stringify({ type: "event", event, data });
  for (const client of wss.clients) {
    if (client.readyState === 1) {
      // OPEN
      client.send(msg);
    }
  }
}

// ── Command handlers ──────────────────────────────────────────────────────

async function handleCommand(ws, wss, pkgs, msg) {
  const { id, method, params } = msg;

  switch (method) {
    // ── Meshtastic ─────────────────────────────────────────────────────
    case "connect": {
      if (!pkgs.meshtastic) {
        sendResponse(ws, id, { success: false, error: "Meshtastic package not loaded" });
        return;
      }
      try {
        const { MeshtasticTransport } = pkgs.meshtastic;
        const { NetworkState } = pkgs.network || {};
        const opts = params || {};
        const endpoint = {
          host: opts.tcpHost || "localhost",
          port: opts.tcpPort || 4403,
        };
        const transport = new MeshtasticTransport(endpoint, {
          reconnectInterval: 5000,
          maxRetries: 10,
          networkState: state.networkState,
        });

        transport.on("connected", (info) => {
          state.meshConnected = true;
          state.meshTransportKind = info.kind || "TCP";
          broadcastEvent(wss, "stateChange", {
            connected: true,
            transportKind: state.meshTransportKind,
            nodeCount: state.meshNodeCount,
          });
        });

        transport.on("disconnected", () => {
          state.meshConnected = false;
          broadcastEvent(wss, "stateChange", {
            connected: false,
            transportKind: null,
            nodeCount: state.meshNodeCount,
          });
        });

        transport.on("frame", (decoded) => {
          if (decoded.packet) {
            broadcastEvent(wss, "messageReceived", {
              id: decoded.packet.id || Date.now(),
              text:
                decoded.packet.decoded?.text ??
                decoded.packet.payload?.text ??
                decoded.packet.text ??
                "",
              from: String(decoded.packet.from || ""),
              to: decoded.packet.to ? String(decoded.packet.to) : null,
              channel: decoded.packet.channel || 0,
              timestamp: Date.now(),
              outgoing: false,
            });
          }
        });

        await transport.connect();
        state.meshTransport = transport;
        sendResponse(ws, id, { success: true });
      } catch (e) {
        sendResponse(ws, id, { success: false, error: e.message });
      }
      break;
    }

    case "disconnect": {
      if (state.meshTransport) {
        await state.meshTransport.disconnect();
        state.meshTransport = null;
        state.meshConnected = false;
        state.meshTransportKind = null;
      }
      sendResponse(ws, id, { success: true });
      break;
    }

    // ── RTL-SDR ────────────────────────────────────────────────────────
    case "connectRtl": {
      if (!pkgs.rtlsdr) {
        sendResponse(ws, id, { success: false, error: "RTL-SDR package not loaded" });
        return;
      }
      try {
        const { RtlTcpClient, SpectrumProcessor } = pkgs.rtlsdr;
        const opts = params || {};
        const client = new RtlTcpClient({
          host: opts.host || "localhost",
          port: opts.port || 1234,
        });

        const processor = new SpectrumProcessor({
          fftSize: opts.fftSize || 2048,
          sampleRate: opts.sampleRate || 2048000,
          centerFreq: opts.centerFreqHz || 100000000,
        });

        client.on("iq", (samples, count) => {
          processor.feedInterleavedUint8(samples);
        });

        processor.on("spectrum", (frame) => {
          broadcastEvent(wss, "rtlSpectrum", {
            centerFreq: frame.centerFreq,
            sampleRate: frame.sampleRate,
            fftSize: frame.fftSize,
            magnitudes: Array.from(frame.magnitudes),
          });
        });

        await client.connect();
        state.rtlClient = client;
        state.spectrumProcessor = processor;
        state.rtlConnected = true;

        // Set initial frequency and sample rate
        client.setCenterFreq(opts.centerFreqHz || 100000000);
        client.setSampleRate(opts.sampleRate || 2048000);

        sendResponse(ws, id, { success: true });
      } catch (e) {
        sendResponse(ws, id, { success: false, error: e.message });
      }
      break;
    }

    case "disconnectRtl": {
      if (state.rtlClient) {
        await state.rtlClient.disconnect();
        state.rtlClient = null;
      }
      if (state.spectrumProcessor) {
        state.spectrumProcessor.destroy();
        state.spectrumProcessor = null;
      }
      state.rtlConnected = false;
      sendResponse(ws, id, { success: true });
      break;
    }

    // ── Messaging ──────────────────────────────────────────────────────
    case "sendMessage": {
      if (!state.meshTransport) {
        sendResponse(ws, id, { success: false, error: "Not connected" });
        return;
      }
      try {
        const { text, channel, destinationNodeId } = params || {};
        const frame = {
          id: Date.now(),
          text: text || "",
          channel: channel ?? 0,
          to: destinationNodeId ? parseInt(destinationNodeId) : undefined,
        };
        await state.meshTransport.sendFrame(frame);

        // Record in history
        const msg = {
          id: Date.now(),
          text: text || "",
          from: "you",
          to: destinationNodeId || null,
          channel: channel ?? 0,
          timestamp: Date.now(),
          outgoing: true,
        };
        state.messageHistory.push(msg);
        // Keep last 500 messages
        if (state.messageHistory.length > 500) {
          state.messageHistory = state.messageHistory.slice(-500);
        }

        sendResponse(ws, id, { success: true });
      } catch (e) {
        sendResponse(ws, id, { success: false, error: e.message });
      }
      break;
    }

    case "getMessageHistory": {
      sendResponse(ws, id, { success: true, messages: state.messageHistory });
      break;
    }

    // ── RuView ─────────────────────────────────────────────────────────
    case "startRuView": {
      if (!pkgs.ruview) {
        sendResponse(ws, id, { success: false, error: "RuView package not loaded" });
        return;
      }
      try {
        const { RuViewClient } = pkgs.ruview;
        const opts = params || {};
        const client = new RuViewClient({
          host: opts.host || "localhost",
          wsPort: opts.wsPort || 3001,
        });

        client.on("sensing", (data) => {
          broadcastEvent(wss, "ruViewSensing", data);
        });

        client.on("error", (err) => {
          console.error("[bridge] RuView error:", err.message);
        });

        client.start();
        state.ruViewClient = client;
        state.ruViewConnected = true;
        sendResponse(ws, id, { success: true });
      } catch (e) {
        sendResponse(ws, id, { success: false, error: e.message });
      }
      break;
    }

    case "stopRuView": {
      if (state.ruViewClient) {
        state.ruViewClient.stop();
        state.ruViewClient = null;
      }
      state.ruViewConnected = false;
      sendResponse(ws, id, { success: true });
      break;
    }

    // ── Map ────────────────────────────────────────────────────────────
    case "startMap": {
      if (!pkgs.maps) {
        sendResponse(ws, id, { success: false, error: "Maps package not loaded" });
        return;
      }
      try {
        const { PmtilesServer } = pkgs.maps;
        const filePath = (params && params.filePath) || "";
        if (!filePath) {
          sendResponse(ws, id, { success: false, error: "filePath required" });
          return;
        }
        if (state.mapServer) {
          await state.mapServer.stop();
        }
        const server = new PmtilesServer(filePath, 0);
        const port = await server.start();
        state.mapServer = server;
        state.mapPort = port;
        sendResponse(ws, id, { success: true, port });
      } catch (e) {
        sendResponse(ws, id, { success: false, error: e.message });
      }
      break;
    }

    case "stopMap": {
      if (state.mapServer) {
        await state.mapServer.stop();
        state.mapServer = null;
        state.mapPort = null;
      }
      sendResponse(ws, id, { success: true });
      break;
    }

    default:
      sendResponse(ws, id, { success: false, error: `Unknown method: ${method}` });
  }
}

// ── Server startup ────────────────────────────────────────────────────────

async function main() {
  const PORT = parseInt(process.env.OCP_BRIDGE_PORT || "18790", 10);

  const pkgs = await loadPackages();

  // Create NetworkState for node tracking
  if (pkgs.network && pkgs.network.default) {
    state.networkState = new pkgs.network.default({ nodeTimeoutMs: 300000 });
    state.networkState.on("nodeAdded", (node) => {
      // Will be forwarded to mesh transport via options.networkState
    });
    state.networkState.on("nodeUpdated", (node) => {
      // Broadcast node updates
    });
  }

  const server = createServer((req, res) => {
    // Simple health endpoint
    if (req.url === "/" || req.url === "/health") {
      res.writeHead(200, { "Content-Type": "application/json" });
      res.end(
        JSON.stringify({
          status: "ok",
          meshConnected: state.meshConnected,
          rtlConnected: state.rtlConnected,
          ruViewConnected: state.ruViewConnected,
          mapPort: state.mapPort,
        })
      );
      return;
    }
    res.writeHead(404);
    res.end("Not found");
  });

  const wss = new WebSocketServer({ server });

  wss.on("connection", (ws) => {
    console.log("[bridge] Client connected");

    ws.on("message", async (raw) => {
      try {
        const msg = JSON.parse(raw.toString());
        if (msg.type === "command") {
          await handleCommand(ws, wss, pkgs, msg);
        }
      } catch (e) {
        console.error("[bridge] Error handling message:", e.message);
        try {
          ws.send(JSON.stringify({ type: "error", error: e.message }));
        } catch (_) {}
      }
    });

    ws.on("close", () => {
      console.log("[bridge] Client disconnected");
    });

    // Send initial state
    sendEvent(ws, "stateChange", {
      connected: state.meshConnected,
      transportKind: state.meshTransportKind,
      nodeCount: state.meshNodeCount,
    });
  });

  server.listen(PORT, "127.0.0.1", () => {
    console.log(`[bridge] OCP-V1 bridge server listening on 127.0.0.1:${PORT}`);
  });

  // Graceful shutdown
  const shutdown = async () => {
    console.log("\n[bridge] Shutting down...");
    if (state.meshTransport) await state.meshTransport.disconnect();
    if (state.rtlClient) await state.rtlClient.disconnect();
    if (state.ruViewClient) state.ruViewClient.stop();
    if (state.mapServer) await state.mapServer.stop();
    if (state.networkState) state.networkState.destroy();
    wss.close();
    server.close();
    process.exit(0);
  };

  process.on("SIGINT", shutdown);
  process.on("SIGTERM", shutdown);
}

main().catch((err) => {
  console.error("[bridge] Fatal:", err);
  process.exit(1);
});