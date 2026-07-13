import { useEffect, useRef } from "react";

interface WaterfallCanvasProps {
  magnitudes: Float32Array;
  minDb?: number;
  maxDb?: number;
  maxRows?: number;
  className?: string;
}

function waterfallColor(t: number) {
  // t 0..1 maps from silence (-120 dB) to hot (-20 dB).
  // INDI/ATA palette: black → dark gray → gray → warm amber → bright white.
  if (t < 0.15) {
    const s = t / 0.15;
    return { r: Math.round(15 * s), g: Math.round(15 * s), b: Math.round(20 * s) };
  }
  if (t < 0.4) {
    const s = (t - 0.15) / 0.25;
    return { r: Math.round(15 + 35 * s), g: Math.round(15 + 35 * s), b: Math.round(20 + 30 * s) };
  }
  if (t < 0.65) {
    const s = (t - 0.4) / 0.25;
    return { r: Math.round(50 + 80 * s), g: Math.round(50 + 60 * s), b: Math.round(50 + 10 * s) };
  }
  if (t < 0.85) {
    const s = (t - 0.65) / 0.2;
    return { r: Math.round(130 + 80 * s), g: Math.round(110 + 50 * s), b: Math.round(60 - 10 * s) };
  }
  const s = (t - 0.85) / 0.15;
  return { r: Math.round(210 + 45 * s), g: Math.round(160 + 95 * s), b: Math.round(50 + 205 * s) };
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
        const { r, g, b } = waterfallColor(t);
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
