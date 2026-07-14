import { useEffect, useRef, useState } from "react";

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
  const [size, setSize] = useState({ width: 0, height: 0 });

  // Keep-alive pages can mount while display:none (0×0). Redraw when visible.
  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas || typeof ResizeObserver === "undefined") return;
    const ro = new ResizeObserver((entries) => {
      const entry = entries[0];
      if (!entry) return;
      const width = Math.floor(entry.contentRect.width);
      const height = Math.floor(entry.contentRect.height);
      setSize((prev) =>
        prev.width === width && prev.height === height ? prev : { width, height }
      );
    });
    ro.observe(canvas);
    return () => ro.disconnect();
  }, []);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    // Prefer ResizeObserver size; fall back to layout box.
    const rect = canvas.getBoundingClientRect();
    const width = size.width || Math.floor(rect.width);
    const height = size.height || Math.floor(rect.height);

    // Hidden keep-alive slots report 0 size — createImageData(0, …) throws.
    if (width < 1 || height < 1) return;

    const dpr = window.devicePixelRatio || 1;
    canvas.width = Math.floor(width * dpr);
    canvas.height = Math.floor(height * dpr);

    const bins = magnitudes.length;
    if (bins > 0) {
      historyRef.current = [magnitudes.slice(), ...historyRef.current].slice(0, maxRows);
    }
    const history = historyRef.current;
    if (!history.length) return;

    const imgData = ctx.createImageData(width, height);
    const data = imgData.data;

    // Draw each history row scaled to one pixel high (or more if few rows).
    const rowHeight = Math.max(1, Math.floor(height / maxRows));
    for (let row = 0; row < history.length; row++) {
      const mag = history[row];
      const y0 = height - (row + 1) * rowHeight;
      if (y0 < 0) continue;
      for (let x = 0; x < width; x++) {
        const rowBins = mag.length;
        const bin = rowBins > 0 ? Math.min(rowBins - 1, Math.floor((x / width) * rowBins)) : 0;
        const sample = mag[bin] ?? minDb;
        const db = Math.max(minDb, Math.min(maxDb, sample));
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
  }, [magnitudes, minDb, maxDb, maxRows, size.width, size.height]);

  return <canvas ref={canvasRef} className={`w-full h-full ${className}`} />;
}
