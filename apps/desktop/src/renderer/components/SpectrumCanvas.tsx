import { useEffect, useRef, useState } from "react";

interface SpectrumCanvasProps {
  magnitudes: Float32Array;
  minDb?: number;
  maxDb?: number;
  lineColor?: string;
  fillColor?: string;
  gridColor?: string;
  peakHold?: boolean;
  peakHoldMagnitudes?: Float32Array | null;
  vfoCenter?: number; // bin index for VFO center line
  vfoLeft?: number; // bin index for VFO left edge
  vfoRight?: number; // bin index for VFO right edge
  showVfo?: boolean;
  className?: string;
}

export function SpectrumCanvas({
  magnitudes,
  minDb = -120,
  maxDb = -20,
  lineColor = "#4fc3f7",
  fillColor = "rgba(79, 195, 247, 0.12)",
  gridColor = "rgba(68, 68, 68, 0.6)",
  peakHold = false,
  peakHoldMagnitudes = null,
  vfoCenter,
  vfoLeft,
  vfoRight,
  showVfo = false,
  className = "",
}: SpectrumCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [size, setSize] = useState({ width: 0, height: 0 });

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

    const rect = canvas.getBoundingClientRect();
    const width = size.width || Math.floor(rect.width);
    const height = size.height || Math.floor(rect.height);
    if (width < 1 || height < 1) return;

    const dpr = window.devicePixelRatio || 1;
    canvas.width = Math.floor(width * dpr);
    canvas.height = Math.floor(height * dpr);
    ctx.setTransform(dpr, 0, 0, dpr, 0, 0);

    const len = magnitudes.length;

    ctx.clearRect(0, 0, width, height);

    // Grid lines (horizontal dB steps).
    ctx.strokeStyle = gridColor;
    ctx.lineWidth = 1;
    for (let db = minDb; db <= maxDb; db += 20) {
      const y = height - ((db - minDb) / (maxDb - minDb)) * height;
      ctx.beginPath();
      ctx.moveTo(0, y);
      ctx.lineTo(width, y);
      ctx.stroke();
    }

    // VFO band overlay (behind spectrum trace)
    if (showVfo && vfoLeft !== undefined && vfoRight !== undefined && len > 0) {
      const xLeft = (vfoLeft / (len - 1)) * width;
      const xRight = (vfoRight / (len - 1)) * width;
      const xCenter = vfoCenter !== undefined ? (vfoCenter / (len - 1)) * width : (xLeft + xRight) / 2;

      // Semi-transparent VFO band
      ctx.fillStyle = "rgba(79, 195, 247, 0.08)";
      ctx.fillRect(xLeft, 0, xRight - xLeft, height);

      // VFO edges
      ctx.strokeStyle = "rgba(79, 195, 247, 0.5)";
      ctx.lineWidth = 2;
      ctx.setLineDash([4, 4]);
      ctx.beginPath();
      ctx.moveTo(xLeft, 0);
      ctx.lineTo(xLeft, height);
      ctx.stroke();
      ctx.beginPath();
      ctx.moveTo(xRight, 0);
      ctx.lineTo(xRight, height);
      ctx.stroke();

      // VFO center line
      ctx.strokeStyle = "rgba(79, 195, 247, 0.7)";
      ctx.lineWidth = 1;
      ctx.setLineDash([2, 3]);
      ctx.beginPath();
      ctx.moveTo(xCenter, 0);
      ctx.lineTo(xCenter, height);
      ctx.stroke();
      ctx.setLineDash([]);
    }

    // Peak-hold overlay (amber status color, no glow)
    if (peakHold && peakHoldMagnitudes && peakHoldMagnitudes.length === len) {
      ctx.beginPath();
      for (let i = 0; i < len; i++) {
        const db = Math.max(minDb, Math.min(maxDb, peakHoldMagnitudes[i]));
        const x = (i / (len - 1)) * width;
        const y = height - ((db - minDb) / (maxDb - minDb)) * height;
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.strokeStyle = "#d4a017";
      ctx.lineWidth = 1.5;
      ctx.stroke();
    }

    // Spectrum trace.
    ctx.beginPath();
    for (let i = 0; i < len; i++) {
      const db = Math.max(minDb, Math.min(maxDb, magnitudes[i]));
      const x = (i / (len - 1)) * width;
      const y = height - ((db - minDb) / (maxDb - minDb)) * height;
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }

    ctx.lineTo(width, height);
    ctx.lineTo(0, height);
    ctx.closePath();
    ctx.fillStyle = fillColor;
    ctx.fill();

    ctx.beginPath();
    for (let i = 0; i < len; i++) {
      const db = Math.max(minDb, Math.min(maxDb, magnitudes[i]));
      const x = (i / (len - 1)) * width;
      const y = height - ((db - minDb) / (maxDb - minDb)) * height;
      if (i === 0) ctx.moveTo(x, y);
      else ctx.lineTo(x, y);
    }
    ctx.strokeStyle = lineColor;
    ctx.lineWidth = 2;
    ctx.stroke();
  }, [magnitudes, minDb, maxDb, lineColor, fillColor, gridColor, peakHold, peakHoldMagnitudes, showVfo, vfoCenter, vfoLeft, vfoRight, size.width, size.height]);

  return <canvas ref={canvasRef} className={`w-full h-full ${className}`} />;
}