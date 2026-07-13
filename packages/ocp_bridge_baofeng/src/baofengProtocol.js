/**
 * Baofeng UV-5RM serial protocol encoder/decoder.
 *
 * Based on the CHIRP UV-5R driver protocol:
 *   - 9600 baud, 8N1 serial
 *   - 0xA5 command prefix
 *   - 5-byte command header: [0xA5, ADDR_LO, ADDR_HI, SIZE_LO, SIZE_HI]
 *   - Ident handshake: send identification string, receive ACK
 *   - Read/Write memory blocks from EEPROM
 *
 * The UV-5RM supports 128 channels stored as 16-byte blocks starting
 * at EEPROM offset 0x0000 for channel data.
 */

/** Command magic byte */
export const BAOFENG_MAGIC = 0xa5;

/** Default baud rate for Baofeng serial */
export const BAOFENG_BAUD_RATE = 9600;

/** Number of channel slots in UV-5RM */
export const BAOFENG_CHANNEL_COUNT = 128;

/** Bytes per channel memory block */
export const BAOFENG_CHANNEL_BLOCK_SIZE = 16;

/** Block read size used by CHIRP (64 bytes per read command) */
export const BAOFENG_READ_BLOCK_SIZE = 64;

// Memory map offsets (UV-5R family)
const MEM_CHANNELS_START = 0x0000;
const MEM_NAMES_START = 0x1000;
const MEM_SETTINGS_START = 0x0e40;

// Channel name block is 7 bytes per channel
const CHANNEL_NAME_SIZE = 7;

/**
 * Build a 5-byte command header.
 * @param {number} address - 16-bit EEPROM address
 * @param {number} size - 16-bit payload size
 * @returns {Uint8Array} 5-byte header
 */
export function buildCommandHeader(address, size) {
  return new Uint8Array([
    BAOFENG_MAGIC,
    address & 0xff,
    (address >> 8) & 0xff,
    size & 0xff,
    (size >> 8) & 0xff,
  ]);
}

/**
 * Build the identification string sent to the radio on connect.
 * The UV-5R family expects a specific ident sequence.
 * @param {string} [model="UV-5RM"] - Radio model identifier
 * @returns {Uint8Array} Identification bytes
 */
export function buildIdentString(model = "UV-5RM") {
  // CHIRP sends the model string padded/terminated for identification
  const encoded = new TextEncoder().encode(model);
  // Pad to 8 bytes for the ident exchange
  const buf = new Uint8Array(8);
  buf.set(encoded.subarray(0, Math.min(encoded.length, 7)));
  // Null-terminate
  buf[encoded.length < 8 ? encoded.length : 7] = 0;
  return buf;
}

/**
 * Parse a response block from the radio.
 * Validates the magic byte and extracts payload.
 * @param {Uint8Array} data - Raw response bytes from radio
 * @returns {{ address: number, payload: Uint8Array } | null} Parsed response or null if invalid
 */
export function parseResponse(data) {
  if (!data || data.length < 5) return null;
  if (data[0] !== BAOFENG_MAGIC) return null;

  const address = data[1] | (data[2] << 8);
  const size = data[3] | (data[4] << 8);
  const payload = data.subarray(5, 5 + size);

  if (payload.length < size) return null;

  return { address, payload };
}

/**
 * Compute the EEPROM address for a channel's frequency/settings data.
 * @param {number} channelIndex - 0-based channel index (0-127)
 * @returns {number} EEPROM offset
 */
export function channelAddress(channelIndex) {
  return MEM_CHANNELS_START + channelIndex * BAOFENG_CHANNEL_BLOCK_SIZE;
}

/**
 * Compute the EEPROM address for a channel's name data.
 * @param {number} channelIndex - 0-based channel index (0-127)
 * @returns {number} EEPROM offset
 */
export function channelNameAddress(channelIndex) {
  return MEM_NAMES_START + channelIndex * CHANNEL_NAME_SIZE;
}

/**
 * Encode a frequency in MHz to the 4-byte BCD format used by Baofeng.
 * Frequency is stored as Hz * 10 in little-endian 4-byte format.
 * @param {number} freqMhz - Frequency in MHz (e.g. 146.520)
 * @returns {Uint8Array} 4-byte encoded frequency
 */
export function encodeFrequency(freqMhz) {
  const freqHz10 = Math.round(freqMhz * 1e5); // freq * 100000 to get 10Hz units
  const buf = new Uint8Array(4);
  buf[0] = freqHz10 & 0xff;
  buf[1] = (freqHz10 >> 8) & 0xff;
  buf[2] = (freqHz10 >> 16) & 0xff;
  buf[3] = (freqHz10 >> 24) & 0xff;
  return buf;
}

/**
 * Decode a 4-byte BCD frequency from Baofeng EEPROM format to MHz.
 * @param {Uint8Array} bytes - 4-byte encoded frequency
 * @returns {number} Frequency in MHz
 */
export function decodeFrequency(bytes) {
  if (!bytes || bytes.length < 4) return 0;
  const freqHz10 =
    (bytes[0]) |
    (bytes[1] << 8) |
    (bytes[2] << 16) |
    (bytes[3] << 24);
  return freqHz10 / 1e5; // Convert 10Hz units back to MHz
}

/**
 * Encode channel data into a 16-byte memory block.
 *
 * Channel block layout (UV-5R family, 16 bytes per channel):
 *   Offset 0-3: RX frequency (4 bytes, little-endian 10Hz units)
 *   Offset 4-7: TX frequency / offset (4 bytes, little-endian 10Hz units)
 *   Offset 8:    Step + duplex (bit flags)
 *   Offset 9:    Tone mode (0=none, 1=CTCSS, 2=DCS)
 *   Offset 10:   RX tone code index
 *   Offset 11:   TX tone code index
 *   Offset 12:   Power (0=High, 1=Low) + bandwidth flag in bit 4
 *   Offset 13:   Additional flags
 *   Offset 14:   Reserved
 *   Offset 15:   Reserved
 *
 * @param {import('./channelModel.js').ChannelData} channel - Channel data object
 * @returns {Uint8Array} 16-byte memory block
 */
export function encodeChannelBlock(channel) {
  const block = new Uint8Array(BAOFENG_CHANNEL_BLOCK_SIZE);

  // RX frequency (bytes 0-3)
  const rxFreq = encodeFrequency(channel.rxFreq || 0);
  block.set(rxFreq, 0);

  // TX frequency (bytes 4-7) — depends on duplex mode
  const txFreq = channel.duplex === "split"
    ? encodeFrequency(channel.txFreq || channel.rxFreq || 0)
    : encodeFrequency(channel.rxFreq || 0);
  block.set(txFreq, 4);

  // Step + duplex flags (byte 8)
  // Bit 6: offset direction (1 = +, 0 = -), Bit 5: duplex enabled
  let duplexByte = 0;
  if (channel.duplex === "+") duplexByte = 0x20 | 0x40;
  else if (channel.duplex === "-") duplexByte = 0x20;
  else if (channel.duplex === "split") duplexByte = 0x20 | 0x40 | 0x80;
  block[8] = duplexByte;

  // Tone mode (byte 9)
  let toneMode = 0;
  if (channel.toneMode === "CTCSS") toneMode = 1;
  else if (channel.toneMode === "DCS") toneMode = 2;
  block[9] = toneMode;

  // RX tone index (byte 10) — CTCSS tone table index or DCS code
  block[10] = channel.rxToneCode || 0;
  // TX tone index (byte 11)
  block[11] = channel.txToneCode || 0;

  // Power + bandwidth (byte 12)
  // Bit 0: power (0=High, 1=Low), Bit 4: bandwidth (0=Wide, 1=Narrow)
  let pwrBw = 0;
  if (channel.power === "Low") pwrBw |= 0x01;
  if (channel.bandwidth === "Narrow") pwrBw |= 0x10;
  block[12] = pwrBw;

  // Remaining bytes (13-15) are reserved/zero
  return block;
}

/**
 * Decode a 16-byte memory block into channel data.
 * @param {Uint8Array} block - 16-byte raw EEPROM block
 * @param {number} channelIndex - Channel number (for reference)
 * @returns {import('./channelModel.js').ChannelData} Decoded channel data
 */
export function decodeChannelBlock(block, channelIndex) {
  if (!block || block.length < BAOFENG_CHANNEL_BLOCK_SIZE) {
    return { index: channelIndex, rxFreq: 0, txFreq: 0, duplex: "none", toneMode: "None", rxToneCode: 0, txToneCode: 0, power: "High", bandwidth: "Wide", name: "" };
  }

  const rxFreq = decodeFrequency(block.subarray(0, 4));
  const txFreq = decodeFrequency(block.subarray(4, 8));

  // Duplex flags (byte 8)
  const duplexByte = block[8];
  let duplex = "none";
  if (duplexByte & 0x20) {
    duplex = (duplexByte & 0x40) ? "+" : "-";
  }
  if (duplexByte & 0x80) {
    duplex = "split";
  }

  // Tone mode (byte 9)
  const toneModeByte = block[9];
  let toneMode = "None";
  if (toneModeByte === 1) toneMode = "CTCSS";
  else if (toneModeByte === 2) toneMode = "DCS";

  // Tone codes (bytes 10-11)
  const rxToneCode = block[10];
  const txToneCode = block[11];

  // Power + bandwidth (byte 12)
  const pwrBw = block[12];
  const power = (pwrBw & 0x01) ? "Low" : "High";
  const bandwidth = (pwrBw & 0x10) ? "Narrow" : "Wide";

  return {
    index: channelIndex,
    rxFreq,
    txFreq,
    duplex,
    toneMode,
    rxToneCode,
    txToneCode,
    power,
    bandwidth,
    name: "", // Name is stored in a separate memory region
  };
}

/**
 * Encode a channel name (up to 7 ASCII chars) into a 7-byte block.
 * @param {string} name - Channel name (max 7 chars)
 * @returns {Uint8Array} 7-byte name block
 */
export function encodeChannelName(name) {
  const buf = new Uint8Array(CHANNEL_NAME_SIZE);
  const encoded = new TextEncoder().encode(name || "");
  buf.set(encoded.subarray(0, Math.min(encoded.length, CHANNEL_NAME_SIZE)));
  // Pad remaining with 0xFF (unused name bytes)
  for (let i = encoded.length; i < CHANNEL_NAME_SIZE; i++) {
    buf[i] = 0xff;
  }
  return buf;
}

/**
 * Decode a 7-byte name block into a string.
 * @param {Uint8Array} block - 7-byte name block
 * @returns {string} Channel name
 */
export function decodeChannelName(block) {
  if (!block || block.length < CHANNEL_NAME_SIZE) return "";
  const chars = [];
  for (let i = 0; i < CHANNEL_NAME_SIZE; i++) {
    if (block[i] === 0xff || block[i] === 0x00) break;
    chars.push(block[i]);
  }
  return String.fromCharCode(...chars);
}

export class BaofengProtocol {
  /**
   * Build a read command for a memory block.
   * @param {number} address - Start address
   * @param {number} size - Number of bytes to read
   * @returns {Uint8Array} Command bytes to send
   */
  static readCommand(address, size) {
    return buildCommandHeader(address, size);
  }

  /**
   * Build a write command for a memory block.
   * @param {number} address - Start address
   * @param {Uint8Array} data - Data bytes to write
   * @returns {Uint8Array} Command + data bytes to send
   */
  static writeCommand(address, data) {
    const header = buildCommandHeader(address, data.length);
    const cmd = new Uint8Array(header.length + data.length);
    cmd.set(header, 0);
    cmd.set(data, header.length);
    return cmd;
  }

  /**
   * Build the identification/handshake sequence.
   * @param {string} model - Radio model string
   * @returns {Uint8Array} Ident bytes
   */
  static identCommand(model = "UV-5RM") {
    return buildIdentString(model);
  }

  /**
   * Validate a response from the radio.
   * Checks for ACK byte (0xA5) or parsed response.
   * @param {Uint8Array} response - Raw response bytes
   * @returns {boolean} True if valid ACK
   */
  static isAck(response) {
    return response && response.length >= 1 && response[0] === BAOFENG_MAGIC;
  }

  /**
   * Calculate total read operations needed for all channels.
   * Each read is limited to BAOFENG_READ_BLOCK_SIZE bytes.
   * @returns {{ readOps: Array<{address: number, size: number}> }}
   */
  static calculateReadOps() {
    // Read channel data (128 channels × 16 bytes = 2048 bytes, starting at 0x0000)
    // Read channel names (128 channels × 7 bytes = 896 bytes, starting at 0x1000)
    const channelDataSize = BAOFENG_CHANNEL_COUNT * BAOFENG_CHANNEL_BLOCK_SIZE;
    const nameDataSize = BAOFENG_CHANNEL_COUNT * CHANNEL_NAME_SIZE;

    const readOps = [];

    // Channel frequency/settings blocks
    for (let offset = 0; offset < channelDataSize; offset += BAOFENG_READ_BLOCK_SIZE) {
      readOps.push({
        address: MEM_CHANNELS_START + offset,
        size: Math.min(BAOFENG_READ_BLOCK_SIZE, channelDataSize - offset),
      });
    }

    // Channel name blocks
    for (let offset = 0; offset < nameDataSize; offset += BAOFENG_READ_BLOCK_SIZE) {
      readOps.push({
        address: MEM_NAMES_START + offset,
        size: Math.min(BAOFENG_READ_BLOCK_SIZE, nameDataSize - offset),
      });
    }

    return { readOps };
  }

  /**
   * Calculate total write operations needed for all channels.
   * @returns {{ writeOps: Array<{address: number, data: Uint8Array}> }}
   */
  static calculateWriteOps() {
    // Same regions, but we write only the channel data we care about
    // In practice, we write the full channel + name regions
    const channelDataSize = BAOFENG_CHANNEL_COUNT * BAOFENG_CHANNEL_BLOCK_SIZE;
    const nameDataSize = BAOFENG_CHANNEL_COUNT * CHANNEL_NAME_SIZE;

    const writeOps = [];

    // Channel data blocks (64 bytes per write)
    for (let offset = 0; offset < channelDataSize; offset += BAOFENG_READ_BLOCK_SIZE) {
      writeOps.push({
        address: MEM_CHANNELS_START + offset,
        size: Math.min(BAOFENG_READ_BLOCK_SIZE, channelDataSize - offset),
      });
    }

    // Channel name blocks
    for (let offset = 0; offset < nameDataSize; offset += BAOFENG_READ_BLOCK_SIZE) {
      writeOps.push({
        address: MEM_NAMES_START + offset,
        size: Math.min(BAOFENG_READ_BLOCK_SIZE, nameDataSize - offset),
      });
    }

    return { writeOps };
  }
}