import { TransportConnection } from "./transportConnection.js";

export class TcpTransportConnection extends TransportConnection {
  constructor(endpoint, io = {}) {
    super("tcp", endpoint);
    this.io = io;
  }

  async connect() {
    if (this.io.connect) {
      await this.io.connect(this.endpoint.host, this.endpoint.port);
    }
    this.connected = true;
    this.emit("connected", { kind: this.kind, endpoint: this.endpoint });
  }

  async sendFrame(frame) {
    if (!this.connected) {
      throw new Error("TCP transport is not connected");
    }
    if (this.io.write) {
      await this.io.write(frame);
    }
    this.emit("sent", { kind: this.kind, bytes: frame.length ?? 0 });
  }
}
