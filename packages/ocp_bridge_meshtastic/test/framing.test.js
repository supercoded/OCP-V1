import test from "node:test";
import assert from "node:assert/strict";
import {
  encodeFrame,
  extractFrames,
  wakeBytes,
  START1,
  START2,
  MAX_PAYLOAD,
} from "../src/streamFraming.js";

test("encodeFrame builds 0x94C3 header with BE length", () => {
  const payload = Buffer.from([1, 2, 3, 4, 5]);
  const framed = encodeFrame(payload);
  assert.equal(framed[0], START1);
  assert.equal(framed[1], START2);
  assert.equal(framed.readUInt16BE(2), 5);
  assert.deepEqual(framed.subarray(4), payload);
});

test("encodeFrame rejects oversized payload", () => {
  assert.throws(() => encodeFrame(Buffer.alloc(MAX_PAYLOAD + 1)), /too large/);
});

test("extractFrames round-trips one frame", () => {
  const payload = Buffer.from("hello-mesh");
  const framed = encodeFrame(payload);
  const { frames, rest } = extractFrames(framed);
  assert.equal(frames.length, 1);
  assert.deepEqual(frames[0], payload);
  assert.equal(rest.length, 0);
});

test("extractFrames recovers after garbage prefix", () => {
  const payload = Buffer.from([9, 8, 7]);
  const framed = encodeFrame(payload);
  const noisy = Buffer.concat([Buffer.from("DBG\n"), framed]);
  const { frames, rest } = extractFrames(noisy);
  assert.equal(frames.length, 1);
  assert.deepEqual(frames[0], payload);
  assert.equal(rest.length, 0);
});

test("extractFrames rejects oversize length and resyncs", () => {
  const bad = Buffer.from([START1, START2, 0x02, 0x01]); // length 513
  const goodPayload = Buffer.from([1]);
  const good = encodeFrame(goodPayload);
  const { frames } = extractFrames(Buffer.concat([bad, good]));
  assert.equal(frames.length, 1);
  assert.deepEqual(frames[0], goodPayload);
});

test("extractFrames keeps incomplete trailing bytes", () => {
  const payload = Buffer.from([1, 2, 3, 4]);
  const framed = encodeFrame(payload);
  const partial = framed.subarray(0, 5); // header + 1 byte
  const { frames, rest } = extractFrames(partial);
  assert.equal(frames.length, 0);
  assert.deepEqual(rest, partial);
});

test("wakeBytes is four START1", () => {
  assert.deepEqual(wakeBytes(), Buffer.from([START1, START1, START1, START1]));
});
