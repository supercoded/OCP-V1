/**
 * Meshtastic Client API stream framing (TCP/Serial).
 * Header: 0x94 0xC3 + BE uint16 length + protobuf payload (max 512).
 * @see https://meshtastic.org/docs/development/device/client-api/
 */

export const START1 = 0x94;
export const START2 = 0xc3;
export const HEADER_LEN = 4;
export const MAX_PAYLOAD = 512;

/**
 * Prefix protobuf payload with 4-byte Meshtastic stream header.
 * @param {Buffer} payload
 * @returns {Buffer}
 */
export function encodeFrame(payload) {
  const body = Buffer.isBuffer(payload) ? payload : Buffer.from(payload);
  if (body.length > MAX_PAYLOAD) {
    throw new Error(`Meshtastic frame payload too large: ${body.length} > ${MAX_PAYLOAD}`);
  }
  const header = Buffer.alloc(HEADER_LEN);
  header[0] = START1;
  header[1] = START2;
  header.writeUInt16BE(body.length, 2);
  return Buffer.concat([header, body]);
}

/**
 * Wake bytes: 4× START1 after connect (resync nudge per Meshtastic SDK docs).
 * @returns {Buffer}
 */
export function wakeBytes() {
  return Buffer.from([START1, START1, START1, START1]);
}

/**
 * Extract complete framed payloads from a byte buffer.
 * Returns remaining unconsumed bytes for the next chunk.
 * @param {Buffer} buffer
 * @returns {{ frames: Buffer[], rest: Buffer }}
 */
export function extractFrames(buffer) {
  const frames = [];
  let buf = Buffer.isBuffer(buffer) ? buffer : Buffer.from(buffer);
  let i = 0;

  while (i < buf.length) {
    // Hunt for START1
    if (buf[i] !== START1) {
      i += 1;
      continue;
    }
    if (i + 1 >= buf.length) {
      // Need START2
      break;
    }
    if (buf[i + 1] !== START2) {
      i += 1;
      continue;
    }
    if (i + HEADER_LEN > buf.length) {
      // Incomplete header
      break;
    }
    const len = buf.readUInt16BE(i + 2);
    if (len > MAX_PAYLOAD) {
      // Corrupt length — skip START1 and resync
      i += 1;
      continue;
    }
    if (i + HEADER_LEN + len > buf.length) {
      // Incomplete payload
      break;
    }
    frames.push(buf.subarray(i + HEADER_LEN, i + HEADER_LEN + len));
    i += HEADER_LEN + len;
  }

  return { frames, rest: buf.subarray(i) };
}
