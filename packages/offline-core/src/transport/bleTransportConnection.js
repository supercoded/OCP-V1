import { TransportConnection } from "./transportConnection.js";

export class BleTransportConnection extends TransportConnection {
  constructor(endpoint, io = {}) {
    super("ble", endpoint);
    this.io = io;
  }

  async connect() {
    if (this.io.connect) {
      await this.io.connect(this.endpoint);
    }
    this.connected = true;
    this.emit("connected", { kind: this.kind, endpoint: this.endpoint });
  }

  async sendFrame(frame) {
    if (!this.connected) {
      throw new Error("BLE transport is not connected");
    }
    if (this.io.sendFrame) {
      await this.io.sendFrame(frame);
    }
    this.emit("sent", { kind: this.kind, bytes: frame.length ?? 0 });
  }
}
