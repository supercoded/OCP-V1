import { EventEmitter } from "events";
import { FFT } from "kissfft-js";

export class SpectrumProcessor extends EventEmitter {
  constructor({ fftSize = 2048, sampleRate = 2048000, centerFreq = 100000000 } = {}) {
    super();
    this.fftSize = fftSize;
    this.sampleRate = sampleRate;
    this.centerFreq = centerFreq;
    this.window = this.#makeHannWindow(fftSize);
    this.inputQueue = [];
    this.lastFrameTime = 0;
    this.frameIntervalMs = 50; // 20 FPS default
    this.fft = null;
    this.#initFft();
  }

  #initFft() {
    try {
      this.fft = new FFT(this.fftSize);
    } catch {
      this.fft = null;
    }
  }

  #makeHannWindow(size) {
    const w = new Float32Array(size);
    for (let i = 0; i < size; i++) {
      w[i] = 0.5 - 0.5 * Math.cos((2 * Math.PI * i) / (size - 1));
    }
    return w;
  }

  configure({ sampleRate, centerFreq, frameRate }) {
    if (sampleRate !== undefined) this.sampleRate = sampleRate;
    if (centerFreq !== undefined) this.centerFreq = centerFreq;
    if (frameRate !== undefined) this.frameIntervalMs = 1000 / frameRate;
  }

  feedInterleavedUint8(uint8Samples) {
    if (!uint8Samples || uint8Samples.length < 2) return;
    const count = Math.floor(uint8Samples.length / 2);
    for (let i = 0; i < count; i++) {
      this.inputQueue.push((uint8Samples[i * 2] - 127.5) / 127.5);
      this.inputQueue.push((uint8Samples[i * 2 + 1] - 127.5) / 127.5);
    }
    this.#tryProcess();
  }

  #tryProcess() {
    const now = performance.now();
    if (now - this.lastFrameTime < this.frameIntervalMs) return;
    if (this.inputQueue.length < this.fftSize * 2) return;
    if (!this.fft) return;

    this.lastFrameTime = now;
    const cin = new Float32Array(this.fftSize * 2);
    for (let i = 0; i < this.fftSize; i++) {
      const re = this.inputQueue[i * 2];
      const im = this.inputQueue[i * 2 + 1];
      const w = this.window[i];
      cin[i * 2] = re * w;
      cin[i * 2 + 1] = im * w;
    }
    // Keep overlap for continuity (drop half a frame).
    this.inputQueue = this.inputQueue.slice(this.fftSize);

    const cout = this.fft.forward(cin);

    const magnitudes = new Float32Array(this.fftSize);
    for (let i = 0; i < this.fftSize; i++) {
      const re = cout[i * 2];
      const im = cout[i * 2 + 1];
      const mag = Math.hypot(re, im) / this.fftSize;
      const db = 20 * Math.log10(mag || 1e-12);
      magnitudes[i] = Math.max(-120, db);
    }

    // Shift zero-frequency component to center for natural spectrum display.
    const shifted = new Float32Array(this.fftSize);
    const half = this.fftSize / 2;
    for (let i = 0; i < half; i++) {
      shifted[i] = magnitudes[i + half];
      shifted[i + half] = magnitudes[i];
    }

    const binSize = this.sampleRate / this.fftSize;
    const startFreq = this.centerFreq - this.sampleRate / 2;
    const frequencies = new Float32Array(this.fftSize);
    for (let i = 0; i < this.fftSize; i++) {
      frequencies[i] = startFreq + i * binSize;
    }

    this.emit("spectrum", {
      centerFreq: this.centerFreq,
      sampleRate: this.sampleRate,
      fftSize: this.fftSize,
      frequencies,
      magnitudes: shifted,
    });

    if (this.inputQueue.length >= this.fftSize * 2) {
      this.#tryProcess();
    }
  }

  destroy() {
    this.removeAllListeners();
    this.inputQueue = [];
    this.fft?.dispose();
    this.fft = null;
  }
}
