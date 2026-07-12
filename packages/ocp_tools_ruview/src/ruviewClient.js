import { EventEmitter } from "node:events";
import { WebSocket } from "ws";

/**
 * Client for the RuView Wi-Fi DensePose sensing server.
 *
 * Connects to `ws://host:port/ws/sensing` and emits simplified presence/sensing
 * events for the OCP-V1 sonar mapper.
 *
 * Emits:
 *  - "sensing" { nodeId, x, y, z, rssi, timestamp, source }
 *  - "error" Error
 *  - "close" code
 */
export class RuViewClient extends EventEmitter {
  constructor({
    host = "localhost",
    httpPort = 3000,
    wsPort = 3001,
    reconnect = true,
    reconnectMs = 3000,
  } = {}) {
    super();
    this.host = host;
    this.httpPort = httpPort;
    this.wsPort = wsPort;
    this.reconnect = reconnect;
    this.reconnectMs = reconnectMs;
    this.ws = null;
    this.closed = false;
  }

  get wsUrl() {
    return `ws://${this.host}:${this.wsPort}/ws/sensing`;
  }

  start() {
    if (this.ws) return;
    this.closed = false;
    this.#connect();
  }

  stop() {
    this.closed = true;
    this.reconnect = false;
    this.ws?.close();
    this.ws = null;
  }

  #connect() {
    try {
      this.ws = new WebSocket(this.wsUrl);
    } catch (err) {
      this.emit("error", err);
      this.#scheduleReconnect();
      return;
    }

    this.ws.on("open", () => {
      this.emit("open");
    });

    this.ws.on("message", (data) => {
      try {
        const text = data.toString("utf8");
        const frame = JSON.parse(text);
        this.#handleFrame(frame);
      } catch (err) {
        this.emit("error", err);
      }
    });

    this.ws.on("error", (err) => this.emit("error", err));

    this.ws.on("close", (code) => {
      this.ws = null;
      this.emit("close", code);
      if (!this.closed && this.reconnect) {
        this.#scheduleReconnect();
      }
    });
  }

  #handleFrame(frame) {
    if (frame.type !== "sensing_update") return;
    const nodes = frame.nodes || [];
    for (const n of nodes) {
      if (!n.position || n.position.length < 2) continue;
      this.emit("sensing", {
        nodeId: n.node_id,
        x: n.position[0],
        y: n.position[1],
        z: n.position[2] ?? 0,
        rssi: n.rssi_dbm ?? null,
        timestamp: typeof frame.timestamp === "number" ? frame.timestamp * 1000 : Date.now(),
        source: frame.source || "unknown",
      });
    }
  }

  #scheduleReconnect() {
    if (this.closed) return;
    setTimeout(() => this.#connect(), this.reconnectMs);
  }
}
