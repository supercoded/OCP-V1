import { EventEmitter } from "events";

export class MockRtlSource extends EventEmitter {
  constructor({ sampleRate = 2048000, centerFreq = 100000000, carriers = [{ freqOffset: 0, amplitude: 0.8 }] } = {}) {
    super();
    this.sampleRate = sampleRate;
    this.centerFreq = centerFreq;
    this.carriers = carriers;
    this.running = false;
    this.interval = null;
    this.phase = 0;
  }

  start() {
    if (this.running) return;
    this.running = true;
    // 4096 samples every ~2 ms to simulate rtl_tcp throughput.
    const samplesPerTick = 4096;
    const intervalMs = (samplesPerTick / this.sampleRate) * 1000;
    this.interval = setInterval(() => this.#emitChunk(samplesPerTick), intervalMs);
  }

  stop() {
    this.running = false;
    if (this.interval) clearInterval(this.interval);
    this.interval = null;
  }

  setCenterFreq(hz) {
    this.centerFreq = hz;
  }

  #emitChunk(sampleCount) {
    const chunk = new Uint8Array(sampleCount * 2);
    const dt = 1 / this.sampleRate;
    for (let n = 0; n < sampleCount; n++) {
      let i = 0;
      let q = 0;
      // Add a little thermal-ish noise.
      const noise = (Math.random() - 0.5) * 0.05;
      for (const c of this.carriers) {
        const f = c.freqOffset;
        const amp = c.amplitude ?? 0.5;
        const theta = 2 * Math.PI * f * n * dt + this.phase;
        i += Math.cos(theta) * amp;
        q += Math.sin(theta) * amp;
      }
      i += noise;
      q += noise;
      chunk[n * 2] = Math.min(255, Math.max(0, Math.round(i * 127.5 + 127.5)));
      chunk[n * 2 + 1] = Math.min(255, Math.max(0, Math.round(q * 127.5 + 127.5)));
    }
    this.phase += 2 * Math.PI * ((this.carriers[0]?.freqOffset || 0) % this.sampleRate) * sampleCount * dt;
    this.emit("iq", chunk, sampleCount);
  }

  destroy() {
    this.stop();
    this.removeAllListeners();
  }
}
