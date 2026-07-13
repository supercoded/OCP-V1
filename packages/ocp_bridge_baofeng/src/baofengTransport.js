/**
 * Baofeng serial transport for reading/writing channel data from UV-5RM radios.
 *
 * Uses the 0xA5 command protocol over serial (9600 baud, 8N1).
 * Provides progress callbacks for UI feedback during read/write operations.
 */

import { BaofengProtocol, BAOFENG_BAUD_RATE, BAOFENG_CHANNEL_COUNT, BAOFENG_CHANNEL_BLOCK_SIZE, BAOFENG_READ_BLOCK_SIZE, encodeChannelBlock, decodeChannelBlock, encodeChannelName, decodeChannelName, } from "./baofengProtocol.js";
import { createDefaultChannels, type ChannelData } from "./channelModel.js";

/**
 * @typedef {Object} BaofengTransportOptions
 * @property {string} portName - Serial port path (e.g., "/dev/ttyUSB0")
 * @property {number} [baudRate=9600] - Baud rate
 * @property {number} [timeout=5000] - Read timeout in ms
 */

/**
 * @typedef {Object} ProgressInfo
 * @property {number} current - Current operation number
 * @property {number} total - Total number of operations
 * @property {string} phase - Current phase ("ident", "read", "write")
 */

export class BaofengTransport {
  /** @type {any} Serial port instance */
  port = null;

  /** @type {BaofengTransportOptions} */
  options;

  /** @type {boolean} */
  connected = false;

  /** @type {Function|null} */
  onProgress = null;

  /** @type {Function|null} */
  io = null; // Injected serial IO for testing

  /**
   * @param {BaofengTransportOptions} options
   * @param {any} [io] - Injected serial IO for testing
   */
  constructor(options, io = null) {
    this.options = {
      baudRate: BAOFENG_BAUD_RATE,
      timeout: 5000,
      ...options,
    };
    this.io = io;
  }

  /**
   * Connect to the Baofeng radio via serial port.
   */
  async connect() {
    if (this.io) {
      // Use injected IO (for testing)
      await this.io.open({ portName: this.options.portName, baudRate: this.options.baudRate });
      this.connected = true;
      return;
    }

    // Dynamic import for serialport (optional dependency)
    let SerialPort;
    try {
      const mod = await import("serialport");
      SerialPort = mod.SerialPort;
    } catch {
      throw new Error("serialport module not installed. Install it with: npm install serialport");
    }

    this.port = new SerialPort({
      path: this.options.portName,
      baudRate: this.options.baudRate ?? BAOFENG_BAUD_RATE,
      dataBits: 8,
      stopBits: 1,
      parity: "none",
      autoOpen: false,
    });

    await new Promise((resolve, reject) => {
      this.port.open((err) => {
        if (err) reject(new Error(`Failed to open serial port ${this.options.portName}: ${err.message}`));
        else resolve();
      });
    });

    this.connected = true;
  }

  /**
   * Disconnect from the radio.
   */
  async disconnect() {
    if (this.port) {
      await new Promise((resolve) => {
        this.port.close(() => resolve());
      });
      this.port = null;
    }
    this.connected = false;
  }

  /**
   * Perform identification handshake with the radio.
   * Sends the ident string and waits for ACK.
   */
  async identify() {
    this.#emitProgress({ current: 0, total: 1, phase: "ident" });

    const identCmd = BaofengProtocol.identCommand();

    const response = await this.#sendAndReceive(identCmd, 1);

    if (!BaofengProtocol.isAck(response)) {
      throw new Error("Radio did not respond to identification. Check cable and power.");
    }

    this.#emitProgress({ current: 1, total: 1, phase: "ident" });
  }

  /**
   * Read all 128 channels from the radio.
   * @returns {Promise<ChannelData[]>} Array of channel data
   */
  async readAllChannels() {
    if (!this.connected) throw new Error("Not connected to radio");

    await this.identify();

    const { readOps } = BaofengProtocol.calculateReadOps();
    const totalOps = readOps.length;
    const eepromData = new Map();

    // Read all memory blocks
    for (let i = 0; i < totalOps; i++) {
      const op = readOps[i];
      this.#emitProgress({ current: i + 1, total: totalOps, phase: "read" });

      const cmd = BaofengProtocol.readCommand(op.address, op.size);
      const response = await this.#sendAndReceive(cmd, op.size + 5);

      const parsed = BaofengProtocol.parseResponse(response);
      if (parsed) {
        // Store each byte at its EEPROM offset
        for (let b = 0; b < parsed.payload.length; b++) {
          eepromData.set(parsed.address + b, parsed.payload[b]);
        }
      }
    }

    // Decode channels from EEPROM data
    return this.#decodeChannels(eepromData);
  }

  /**
   * Write all channels to the radio.
   * @param {ChannelData[]} channels - Array of channel data to write
   */
  async writeAllChannels(channels) {
    if (!this.connected) throw new Error("Not connected to radio");

    await this.identify();

    // Encode all channels into EEPROM format
    const channelData = new Uint8Array(BAOFENG_CHANNEL_COUNT * BAOFENG_CHANNEL_BLOCK_SIZE);
    const nameData = new Uint8Array(BAOFENG_CHANNEL_COUNT * 7);

    for (const ch of channels) {
      if (ch.index < 0 || ch.index >= BAOFENG_CHANNEL_COUNT) continue;
      const block = encodeChannelBlock(ch);
      channelData.set(block, ch.index * BAOFENG_CHANNEL_BLOCK_SIZE);
      const nameBlock = encodeChannelName(ch.name);
      nameData.set(nameBlock, ch.index * 7);
    }

    // Write channel data in blocks
    const { writeOps } = BaofengProtocol.calculateWriteOps();
    const totalOps = writeOps.length * 2; // Read back verification not required by protocol

    for (let i = 0; i < writeOps.length; i++) {
      const op = writeOps[i];
      this.#emitProgress({ current: i + 1, total: totalOps, phase: "write" });

      // Extract the relevant slice from channel data or name data
      let data;
      if (op.address >= 0x1000) {
        // Name region
        const offset = op.address - 0x1000;
        data = nameData.subarray(offset, offset + op.size);
      } else {
        // Channel data region
        data = channelData.subarray(op.address, op.address + op.size);
      }

      const cmd = BaofengProtocol.writeCommand(op.address, data);
      await this.#sendAndReceive(cmd, 1);

      // Small delay between write blocks (radio needs time)
      await this.#delay(50);
    }
  }

  /**
   * Decode channel data from EEPROM map.
   * @param {Map<number, number>} eepromData - Map of EEPROM address to byte value
   * @returns {ChannelData[]}
   */
  #decodeChannels(eepromData) {
    const channels = createDefaultChannels();

    for (let i = 0; i < BAOFENG_CHANNEL_COUNT; i++) {
      // Decode channel block
      const blockStart = i * BAOFENG_CHANNEL_BLOCK_SIZE;
      const block = new Uint8Array(BAOFENG_CHANNEL_BLOCK_SIZE);
      for (let b = 0; b < BAOFENG_CHANNEL_BLOCK_SIZE; b++) {
        block[b] = eepromData.get(blockStart + b) ?? 0xff;
      }

      const ch = decodeChannelBlock(block, i);

      // Decode channel name
      const nameStart = 0x1000 + i * 7;
      const nameBlock = new Uint8Array(7);
      for (let b = 0; b < 7; b++) {
        nameBlock[b] = eepromData.get(nameStart + b) ?? 0xff;
      }
      ch.name = decodeChannelName(nameBlock);

      channels[i] = ch;
    }

    return channels;
  }

  /**
   * Send a command and receive a response.
   * @param {Uint8Array|Buffer} data - Data to send
   * @param {number} expectedLength - Expected response length
   * @returns {Promise<Uint8Array>} Response data
   */
  async #sendAndReceive(data, expectedLength) {
    if (this.io) {
      // Test mode: use injected IO
      await this.io.write(data);
      return this.io.read(expectedLength);
    }

    if (!this.port) throw new Error("Serial port not initialized");

    return new Promise((resolve, reject) => {
      const timeout = setTimeout(() => {
        reject(new Error(`Serial read timeout after ${this.options.timeout}ms`));
      }, this.options.timeout);

      let buffer = Buffer.alloc(0);

      const onData = (chunk) => {
        buffer = Buffer.concat([buffer, chunk]);
        if (buffer.length >= expectedLength) {
          clearTimeout(timeout);
          this.port.removeListener("data", onData);
          resolve(new Uint8Array(buffer.subarray(0, expectedLength)));
        }
      };

      this.port.on("data", onData);
      this.port.write(Buffer.from(data), (err) => {
        if (err) {
          clearTimeout(timeout);
          this.port.removeListener("data", onData);
          reject(new Error(`Serial write error: ${err.message}`));
        }
      });
    });
  }

  /**
   * Emit progress event.
   * @param {ProgressInfo} info
   */
  #emitProgress(info) {
    if (this.onProgress) {
      this.onProgress(info);
    }
  }

  /**
   * Delay helper.
   * @param {number} ms
   */
  #delay(ms) {
    return new Promise((resolve) => setTimeout(resolve, ms));
  }
}