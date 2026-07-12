import { describe, it } from "node:test";
import assert from "node:assert";
import { SpectrumProcessor } from "../src/spectrumProcessor.js";

describe("SpectrumProcessor", () => {
  it("emits a shifted spectrum frame from synthetic carrier", { timeout: 10000 }, async () => {
    const proc = new SpectrumProcessor({ fftSize: 256, sampleRate: 2048000, centerFreq: 100e6 });
    assert.ok(proc.fft, "kissfft-js FFT should initialize");

    const framePromise = new Promise((resolve) => proc.once("spectrum", resolve));

    // Generate a pure carrier at exactly sampleRate/8 offset.
    const samples = new Uint8Array(2048);
    const carrier = 2048000 / 8;
    for (let i = 0; i < 1024; i++) {
      const t = i / 2048000;
      const theta = 2 * Math.PI * carrier * t;
      const iVal = Math.cos(theta) * 0.9;
      const qVal = Math.sin(theta) * 0.9;
      samples[i * 2] = Math.min(255, Math.max(0, Math.round(iVal * 127.5 + 127.5)));
      samples[i * 2 + 1] = Math.min(255, Math.max(0, Math.round(qVal * 127.5 + 127.5)));
    }

    proc.feedInterleavedUint8(samples);
    proc.feedInterleavedUint8(samples);

    const frame = await framePromise;
    assert.strictEqual(frame.fftSize, 256);
    assert.strictEqual(frame.frequencies.length, 256);
    assert.strictEqual(frame.magnitudes.length, 256);
    assert.strictEqual(frame.centerFreq, 100e6);

    let peakIndex = 0;
    let peakMag = -Infinity;
    for (let i = 0; i < frame.magnitudes.length; i++) {
      if (frame.magnitudes[i] > peakMag) {
        peakMag = frame.magnitudes[i];
        peakIndex = i;
      }
    }
    const expectedFreq = 100e6 + carrier;
    const actualFreq = frame.frequencies[peakIndex];
    const binSize = frame.sampleRate / frame.fftSize;
    assert.ok(Math.abs(actualFreq - expectedFreq) <= binSize * 2, `peak freq ${actualFreq} not near ${expectedFreq}`);
    assert.ok(peakMag > -40, `peak magnitude too low: ${peakMag}`);

    proc.destroy();
  });
});
