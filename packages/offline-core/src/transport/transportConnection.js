import { EventEmitter } from "node:events";

/**
 * Shared transport contract used by BLE/Serial/TCP adapters.
 */
export class TransportConnection extends EventEmitter {
  constructor(kind, endpoint) {
    super();
    this.kind = kind;
    this.endpoint = endpoint;
    this.connected = false;
  }

  async connect() {
    throw new Error(`${this.kind} transport must implement connect()`);
  }

  async disconnect() {
    this.connected = false;
    this.emit("disconnected", { kind: this.kind, endpoint: this.endpoint });
  }

  async sendFrame(_frame) {
    throw new Error(`${this.kind} transport must implement sendFrame()`);
  }

  /**
   * Runtime hook used by tests and integration adapters.
   */
  emitIncomingFrame(frame) {
    this.emit("frame", frame);
  }
}
