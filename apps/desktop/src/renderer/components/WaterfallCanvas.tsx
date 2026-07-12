import { useEffect, useRef } from "react";

interface WaterfallCanvasProps {
  magnitudes: Float32Array;
  minDb?: number;
  maxDb?: number;
  maxRows?: number;
  className?: string;
}

function phosphorColor(t: number) {
  // t 0..1 maps from silence (-120 dB) to hot (-20 dB).
  // Color ramp: black → dark green → green → yellow-green → white.
  if (t < 0.25) {
    // black to dark green
    const s = t / 0.25;
    return { r: 0, g: Math.round(40 * s), b: 0 };
  }
  if (t < 0.6) {
    const s = (t - 0.25) / 0.35;
    return { r: 0, g: Math.round(40 + 175 * s), b: 0 };
  }
  if (t < 0.85) {
    const s = (t - 0.6) / 0.25;
    return { r: Math.round(255 * s), g: 215, b: 0 };
  }
  const s = (t - 0.85) / 0.15;
  return { r: 255, g: 215 + Math.round(40 * s), b: Math.round(255 * s) };
}

export function WaterfallCanvas({
  magnitudes,
  minDb = -120,
  maxDb = -20,
  maxRows = 200,
  className = "",
}: WaterfallCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const historyRef = useRef<Float32Array[]>([]);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.getBoundingClientRect();
    canvas.width = Math.floor(rect.width * dpr);
    canvas.height = Math.floor(rect.height * dpr);

    const width = rect.width;
    const height = rect.height;
    const bins = magnitudes.length;

    historyRef.current = [magnitudes.slice(), ...historyRef.current].slice(0, maxRows);
    const history = historyRef.current;

    const imgData = ctx.createImageData(width, height);
    const data = imgData.data;

    // Draw each history row scaled to one pixel high (or more if few rows).
    const rowHeight = Math.max(1, Math.floor(height / maxRows));
    for (let row = 0; row < history.length; row++) {
      const mag = history[row];
      const y0 = height - (row + 1) * rowHeight;
      if (y0 < 0) continue;
      for (let x = 0; x < width; x++) {
        const bin = Math.min(bins - 1, Math.floor((x / width) * bins));
        const db = Math.max(minDb, Math.min(maxDb, mag[bin]));
        const t = (db - minDb) / (maxDb - minDb);
        const { r, g, b } = phosphorColor(t);
        for (let dy = 0; dy < rowHeight; dy++) {
          const y = y0 + dy;
          if (y < 0 || y >= height) continue;
          const idx = (y * width + x) * 4;
          data[idx] = r;
          data[idx + 1] = g;
          data[idx + 2] = b;
          data[idx + 3] = 255;
        }
      }
    }

    ctx.putImageData(imgData, 0, 0);
  }, [magnitudes, minDb, maxDb, maxRows]);

  return <canvas ref={canvasRef} className={`w-full h-full ${className}`} />;
}
