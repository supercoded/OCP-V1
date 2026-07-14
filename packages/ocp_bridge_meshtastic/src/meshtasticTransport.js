import { TransportConnection } from "../../../packages/offline-core/src/transport/transportConnection.js";
import { MeshtasticCodec } from "./meshtasticCodec.js";
import { encodeFrame, extractFrames, wakeBytes } from "./streamFraming.js";
import { createConnection } from "node:net";
import { randomBytes } from "node:crypto";

/**
 * Transport adapter for Meshtastic devices (TCP Client API with 0x94C3 framing).
 */
export class MeshtasticTransport extends TransportConnection {
  constructor(endpoint, options = {}) {
    super("meshtastic", endpoint);
    this.codec = new MeshtasticCodec();
    this.options = {
      reconnectInterval: 5000,
      maxRetries: 3,
      ...options,
    };
    this.socket = null;
    this.reconnectTimer = null;
    this.retryCount = 0;
    this.buffer = Buffer.alloc(0);
  }

  async connect() {
    return new Promise((resolve, reject) => {
      try {
        if (!this.endpoint || !this.endpoint.host || !this.endpoint.port) {
          throw new Error("Invalid endpoint - must specify host and port");
        }

        this.socket = createConnection({
          host: this.endpoint.host,
          port: this.endpoint.port,
        });

        let settled = false;

        this.socket.on("connect", () => {
          this.connected = true;
          this.retryCount = 0;
          this.buffer = Buffer.alloc(0);

          if (this.reconnectTimer) {
            clearTimeout(this.reconnectTimer);
            this.reconnectTimer = null;
          }

          // Wake framer + request config dump
          this.socket.write(wakeBytes());
          this.#requestConfig().catch(() => {});

          this.emit("connected", {
            kind: this.kind,
            endpoint: this.endpoint,
            timestamp: new Date().toISOString(),
          });

          if (!settled) {
            settled = true;
            resolve();
          }
        });

        this.socket.on("data", (data) => {
          this.#handleRawData(data);
        });

        this.socket.on("error", (error) => {
          this.#handleConnectionError(error);
          if (!settled) {
            settled = true;
            reject(error);
          }
        });

        this.socket.on("close", () => {
          this.connected = false;
          this.emit("disconnected", {
            kind: this.kind,
            endpoint: this.endpoint,
            timestamp: new Date().toISOString(),
          });

          if (this.options.reconnectInterval && this.retryCount < this.options.maxRetries) {
            this.retryCount++;
            this.#scheduleReconnect();
          }
        });

        this.socket.setTimeout(30000);
        this.socket.on("timeout", () => {
          this.socket?.destroy();
        });
      } catch (error) {
        this.#handleConnectionError(error);
        reject(error);
      }
    });
  }

  async disconnect() {
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }

    if (this.socket) {
      this.socket.destroy();
      this.socket = null;
    }

    this.connected = false;
    this.retryCount = 0;
    this.buffer = Buffer.alloc(0);

    this.emit("disconnected", {
      kind: this.kind,
      endpoint: this.endpoint,
      timestamp: new Date().toISOString(),
    });
  }

  async sendFrame(frame) {
    if (!this.connected || !this.socket) {
      throw new Error("Meshtastic transport is not connected");
    }

    try {
      const encoded = this.codec.encodeToRadio(frame);
      if (!encoded || encoded.length === 0) {
        throw new Error("Codec produced empty ToRadio payload");
      }
      const framed = encodeFrame(encoded);
      this.socket.write(framed);

      this.emit("sent", {
        kind: this.kind,
        bytes: framed.length,
        frameId: frame.id,
        timestamp: new Date().toISOString(),
      });
    } catch (error) {
      this.emit("error", {
        kind: this.kind,
        endpoint: this.endpoint,
        error: `Failed to send frame: ${error.message}`,
        frame,
        timestamp: new Date().toISOString(),
      });
      throw error;
    }
  }

  #handleRawData(data) {
    try {
      this.buffer = Buffer.concat([this.buffer, data]);
      const { frames, rest } = extractFrames(this.buffer);
      this.buffer = rest;

      for (const messageBuffer of frames) {
        const decoded = this.codec.decodeFromRadio(messageBuffer);
        if (decoded?.error) {
          this.emit("error", {
            kind: this.kind,
            endpoint: this.endpoint,
            error: decoded.error,
            timestamp: new Date().toISOString(),
          });
          continue;
        }

        this.emit("frame", decoded);

        if (this.options.networkState) {
          const ns = this.options.networkState;
          if (decoded.packet) ns.onPacket(decoded.packet);
          if (decoded.nodeInfo) ns.onNodeInfo(decoded.nodeInfo);
        }

        this.emit("received", {
          kind: this.kind,
          bytes: messageBuffer.length,
          timestamp: new Date().toISOString(),
        });
      }
    } catch (error) {
      this.emit("error", {
        kind: this.kind,
        endpoint: this.endpoint,
        error: `Failed to decode frame: ${error.message}`,
        timestamp: new Date().toISOString(),
      });
    }
  }

  async #requestConfig() {
    const wantConfigId =
      typeof this.endpoint.configId === "number"
        ? this.endpoint.configId >>> 0
        : randomBytes(4).readUInt32LE(0);

    await this.sendFrame({ wantConfigId });
  }

  #handleConnectionError(error) {
    this.connected = false;
    this.emit("error", {
      kind: this.kind,
      endpoint: this.endpoint,
      error: error.message,
      timestamp: new Date().toISOString(),
    });

    if (this.options.reconnectInterval && this.retryCount < this.options.maxRetries) {
      this.retryCount++;
      this.#scheduleReconnect();
    }
  }

  #scheduleReconnect() {
    if (this.reconnectTimer) return;

    this.reconnectTimer = setTimeout(async () => {
      this.reconnectTimer = null;
      try {
        await this.connect();
      } catch (error) {
        this.emit("reconnectFailed", {
          kind: this.kind,
          endpoint: this.endpoint,
          retryCount: this.retryCount,
          error: error.message,
          timestamp: new Date().toISOString(),
        });

        if (this.retryCount < this.options.maxRetries) {
          this.#scheduleReconnect();
        } else {
          this.emit("reconnectAborted", {
            kind: this.kind,
            endpoint: this.endpoint,
            maxRetries: this.options.maxRetries,
            timestamp: new Date().toISOString(),
          });
        }
      }
    }, this.options.reconnectInterval);
  }
}
