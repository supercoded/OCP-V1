/**
 * CRC-32 (ISO-HDLC / Ethernet / PNG polynomial 0xEDB88320).
 */

const TABLE = (() => {
  const table = new Uint32Array(256);
  for (let i = 0; i < 256; i++) {
    let c = i;
    for (let k = 0; k < 8; k++) {
      c = c & 1 ? 0xedb88320 ^ (c >>> 1) : c >>> 1;
    }
    table[i] = c >>> 0;
  }
  return table;
})();

/**
 * @param {Buffer|Uint8Array|string} data
 * @returns {number} unsigned 32-bit CRC
 */
export function crc32(data) {
  const buf = typeof data === "string" ? Buffer.from(data, "utf8") : Buffer.from(data);
  let crc = 0xffffffff;
  for (let i = 0; i < buf.length; i++) {
    crc = TABLE[(crc ^ buf[i]) & 0xff] ^ (crc >>> 8);
  }
  return (crc ^ 0xffffffff) >>> 0;
}

/**
 * Append CRC-32 as 4 little-endian bytes.
 * @param {Buffer|Uint8Array} data
 * @returns {Buffer}
 */
export function appendCrc32(data) {
  const body = Buffer.from(data);
  const out = Buffer.alloc(body.length + 4);
  body.copy(out);
  out.writeUInt32LE(crc32(body), body.length);
  return out;
}

/**
 * Verify trailing CRC-32. Returns true if valid.
 * @param {Buffer|Uint8Array} dataWithCrc
 */
export function verifyCrc32(dataWithCrc) {
  const buf = Buffer.from(dataWithCrc);
  if (buf.length < 4) return false;
  const body = buf.subarray(0, buf.length - 4);
  const expected = buf.readUInt32LE(buf.length - 4);
  return crc32(body) === expected;
}

/**
 * @param {Buffer|Uint8Array} dataWithCrc
 * @returns {{ ok: true, body: Buffer } | { ok: false, error: string }}
 */
export function stripAndVerifyCrc32(dataWithCrc) {
  const buf = Buffer.from(dataWithCrc);
  if (buf.length < 4) return { ok: false, error: "Buffer too short for CRC" };
  if (!verifyCrc32(buf)) return { ok: false, error: "CRC mismatch" };
  return { ok: true, body: buf.subarray(0, buf.length - 4) };
}
