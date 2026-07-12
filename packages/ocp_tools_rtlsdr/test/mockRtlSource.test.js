import { describe, it } from "node:test";
import assert from "node:assert";
import { MockRtlSource } from "../src/mockRtlSource.js";

describe("MockRtlSource", () => {
  it("emits interleaved IQ chunks when running", { timeout: 2000 }, async () => {
    const src = new MockRtlSource({
      sampleRate: 2048000,
      centerFreq: 100e6,
      carriers: [{ freqOffset: 256000, amplitude: 0.9 }],
    });

    const chunkPromise = new Promise((resolve) => src.once("iq", (buf, count) => resolve({ buf, count })));
    src.start();
    const { buf, count } = await chunkPromise;
    src.stop();

    assert.strictEqual(buf.length, count * 2);
    assert.ok(count > 0);

    src.destroy();
  });
});
