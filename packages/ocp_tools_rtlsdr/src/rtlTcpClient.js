import { EventEmitter } from "events";
import { createConnection } from "net";

export const RTL_TCP_COMMANDS = {
  SET_FREQ: 0x01,
  SET_SAMPLE_RATE: 0x02,
  SET_GAIN_MODE: 0x03,
  SET_GAIN: 0x04,
  SET_FREQ_CORRECTION: 0x05,
  SET_IF_GAIN: 0x06,
  SET_TEST_MODE: 0x07,
  SET_AGC_MODE: 0x08,
  SET_DIRECT_SAMPLING: 0x09,
  SET_OFFSET_TUNING: 0x0a,
  SET_RTL_XTAL: 0x0b,
  SET_TUNER_XTAL: 0x0c,
  SET_TUNER_GAIN_BY_INDEX: 0x0d,
  SET_BIAS_TEE: 0x0e,
};

export class RtlTcpClient extends EventEmitter {
  constructor({ host = "localhost", port = 1234, autoReconnect = true } = {}) {
    super();
    this.host = host;
    this.port = port;
    this.autoReconnect = autoReconnect;
    this.socket = null;
    this.buffer = Buffer.alloc(0);
    this.connected = false;
    this.dongleInfo = null;
    this.reconnectTimer = null;
  }

  connect() {
    return new Promise((resolve, reject) => {
      if (this.socket) {
        return resolve({ connected: this.connected, dongleInfo: this.dongleInfo });
      }

      this.socket = createConnection({ host: this.host, port: this.port }, () => {
        this.connected = true;
        this.emit("open");
        resolve({ connected: true });
      });

      this.socket.on("data", (chunk) => this.#onData(chunk));
      this.socket.on("error", (err) => {
        this.emit("error", err);
        if (!this.connected) reject(err);
      });
      this.socket.on("close", () => {
        this.connected = false;
        this.dongleInfo = null;
        this.socket = null;
        this.emit("close");
        if (this.autoReconnect) this.#scheduleReconnect();
      });
    });
  }

  disconnect() {
    this.autoReconnect = false;
    clearTimeout(this.reconnectTimer);
    return new Promise((resolve) => {
      if (!this.socket) return resolve();
      this.socket.once("close", resolve);
      this.socket.destroy();
    });
  }

  #scheduleReconnect() {
    clearTimeout(this.reconnectTimer);
    this.reconnectTimer = setTimeout(() => this.connect().catch(() => {}), 2000);
  }

  #onData(chunk) {
    this.buffer = Buffer.concat([this.buffer, chunk]);

    if (!this.dongleInfo && this.buffer.length >= 12) {
      const magic = this.buffer.subarray(0, 4).toString("ascii");
      if (magic !== "RTL0") {
        this.emit("error", new Error(`Unexpected rtl_tcp magic: ${magic}`));
        this.disconnect();
        return;
      }
      this.dongleInfo = {
        magic,
        tunerType: this.buffer.readUInt32LE(4),
        tunerGainCount: this.buffer.readUInt32LE(8),
      };
      this.buffer = this.buffer.subarray(12);
      this.emit("dongleInfo", this.dongleInfo);
    }

    if (!this.dongleInfo) return;

    // Samples are interleaved uint8 I/Q pairs.
    const sampleCount = Math.floor(this.buffer.length / 2);
    if (sampleCount === 0) return;

    const samples = new Uint8Array(this.buffer.buffer, this.buffer.byteOffset, sampleCount * 2);
    this.buffer = this.buffer.subarray(sampleCount * 2);
    this.emit("iq", samples, sampleCount);
  }

  #sendCommand(cmd, param = 0) {
    if (!this.socket || !this.connected) return false;
    const buf = Buffer.alloc(5);
    buf.writeUInt8(cmd, 0);
    buf.writeUInt32BE(param >>> 0, 1);
    this.socket.write(buf);
    return true;
  }

  setCenterFreq(hz) {
    return this.#sendCommand(RTL_TCP_COMMANDS.SET_FREQ, Math.round(hz));
  }

  setSampleRate(hz) {
    return this.#sendCommand(RTL_TCP_COMMANDS.SET_SAMPLE_RATE, Math.round(hz));
  }

  setGainMode(manual) {
    return this.#sendCommand(RTL_TCP_COMMANDS.SET_GAIN_MODE, manual ? 0 : 1);
  }

  setGain(tenthsDb) {
    return this.#sendCommand(RTL_TCP_COMMANDS.SET_GAIN, Math.round(tenthsDb));
  }

  setFreqCorrection(ppm) {
    return this.#sendCommand(RTL_TCP_COMMANDS.SET_FREQ_CORRECTION, Math.round(ppm));
  }

  setAgcMode(enabled) {
    return this.#sendCommand(RTL_TCP_COMMANDS.SET_AGC_MODE, enabled ? 1 : 0);
  }

  setDirectSampling(mode) {
    return this.#sendCommand(RTL_TCP_COMMANDS.SET_DIRECT_SAMPLING, Math.max(0, Math.min(2, mode)));
  }

  setBiasTee(enabled) {
    return this.#sendCommand(RTL_TCP_COMMANDS.SET_BIAS_TEE, enabled ? 1 : 0);
  }
}
