import { TransportConnection } from "./transportConnection.js";

export class SerialTransportConnection extends TransportConnection {
  constructor(endpoint, io = {}) {
    super("serial", endpoint);
    this.io = io;
  }

  async connect() {
    if (this.io.open) {
      await this.io.open(this.endpoint);
    }
    this.connected = true;
    this.emit("connected", { kind: this.kind, endpoint: this.endpoint });
  }

  async sendFrame(frame) {
    if (!this.connected) {
      throw new Error("Serial transport is not connected");
    }
    if (this.io.write) {
      await this.io.write(frame);
    }
    this.emit("sent", { kind: this.kind, bytes: frame.length ?? 0 });
  }
}
