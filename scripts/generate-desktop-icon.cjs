/**
 * Generate apps/desktop/build/icon.png from the INDI/ATA sonar mark.
 * Run: node scripts/generate-desktop-icon.cjs
 */
const fs = require('fs');
const path = require('path');
const zlib = require('zlib');

const SIZE = 256;
const OUT = path.join(__dirname, '../apps/desktop/build/icon.png');
const PAD = 16;
const CORNER = 32;
const CX = SIZE / 2;
const RING = 80;

function crc32(buf) {
  let c = ~0;
  for (let i = 0; i < buf.length; i++) {
    c ^= buf[i];
    for (let k = 0; k < 8; k++) c = (c >>> 1) ^ (0xedb88320 & -(c & 1));
  }
  return ~c >>> 0;
}

function chunk(type, data) {
  const len = Buffer.alloc(4);
  len.writeUInt32BE(data.length, 0);
  const typeBuf = Buffer.from(type, 'ascii');
  const crcBuf = Buffer.alloc(4);
  crcBuf.writeUInt32BE(crc32(Buffer.concat([typeBuf, data])), 0);
  return Buffer.concat([len, typeBuf, data, crcBuf]);
}

function inRoundedRect(x, y) {
  if (x < PAD || x >= SIZE - PAD || y < PAD || y >= SIZE - PAD) return false;
  const left = x < PAD + CORNER;
  const right = x >= SIZE - PAD - CORNER;
  const top = y < PAD + CORNER;
  const bottom = y >= SIZE - PAD - CORNER;
  if (!(left || right) || !(top || bottom)) return true;
  const ox = left ? PAD + CORNER : SIZE - PAD - CORNER;
  const oy = top ? PAD + CORNER : SIZE - PAD - CORNER;
  return Math.hypot(x - ox, y - oy) <= CORNER;
}

const raw = Buffer.alloc((SIZE * 4 + 1) * SIZE);
for (let y = 0; y < SIZE; y++) {
  raw[y * (SIZE * 4 + 1)] = 0;
  for (let x = 0; x < SIZE; x++) {
    const idx = y * (SIZE * 4 + 1) + 1 + x * 4;
    if (!inRoundedRect(x, y)) {
      raw[idx] = 0;
      raw[idx + 1] = 0;
      raw[idx + 2] = 0;
      raw[idx + 3] = 0;
      continue;
    }

    let r = 0x11;
    let g = 0x11;
    let b = 0x11;
    const d = Math.hypot(x - CX, y - CX);
    const ang = Math.atan2(x - CX, CX - y);

    if (ang >= 0 && ang <= Math.PI / 3 && d < RING) {
      r = 0x33;
      g = 0x33;
      b = 0x33;
    }
    if (Math.abs(d - RING) < 6) {
      r = 0xc8;
      g = 0xc8;
      b = 0xc8;
    }
    if (Math.abs(x - CX) < 6 && y <= CX && y >= CX - RING) {
      r = 0xe8;
      g = 0xe8;
      b = 0xe8;
    }
    if (d < 10) {
      r = 0xe8;
      g = 0xe8;
      b = 0xe8;
    }

    raw[idx] = r;
    raw[idx + 1] = g;
    raw[idx + 2] = b;
    raw[idx + 3] = 255;
  }
}

const ihdr = Buffer.alloc(13);
ihdr.writeUInt32BE(SIZE, 0);
ihdr.writeUInt32BE(SIZE, 4);
ihdr[8] = 8;
ihdr[9] = 6;
ihdr[10] = 0;
ihdr[11] = 0;
ihdr[12] = 0;

const png = Buffer.concat([
  Buffer.from([137, 80, 78, 71, 13, 10, 26, 10]),
  chunk('IHDR', ihdr),
  chunk('IDAT', zlib.deflateSync(raw, { level: 9 })),
  chunk('IEND', Buffer.alloc(0)),
]);

fs.mkdirSync(path.dirname(OUT), { recursive: true });
fs.writeFileSync(OUT, png);
console.log('Wrote', OUT, `(${png.length} bytes)`);
