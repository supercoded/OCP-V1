import { useEffect, useRef } from "react";

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
  lineColor = "#00ff9d",
  fillColor = "rgba(0, 255, 157, 0.15)",
  gridColor = "rgba(0, 255, 157, 0.15)",
  peakHold = false,
  peakHoldMagnitudes = null,
  vfoCenter,
  vfoLeft,
  vfoRight,
  showVfo = false,
  className = "",
}: SpectrumCanvasProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    const dpr = window.devicePixelRatio || 1;
    const rect = canvas.getBoundingClientRect();
    canvas.width = Math.floor(rect.width * dpr);
    canvas.height = Math.floor(rect.height * dpr);
    ctx.scale(dpr, dpr);

    const width = rect.width;
    const height = rect.height;
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
      ctx.fillStyle = "rgba(0, 240, 160, 0.08)";
      ctx.fillRect(xLeft, 0, xRight - xLeft, height);

      // VFO edges
      ctx.strokeStyle = "rgba(0, 240, 160, 0.5)";
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
      ctx.strokeStyle = "rgba(0, 240, 160, 0.7)";
      ctx.lineWidth = 1;
      ctx.setLineDash([2, 3]);
      ctx.beginPath();
      ctx.moveTo(xCenter, 0);
      ctx.lineTo(xCenter, height);
      ctx.stroke();
      ctx.setLineDash([]);
    }

    // Peak-hold overlay (amber/warm ramp)
    if (peakHold && peakHoldMagnitudes && peakHoldMagnitudes.length === len) {
      ctx.beginPath();
      for (let i = 0; i < len; i++) {
        const db = Math.max(minDb, Math.min(maxDb, peakHoldMagnitudes[i]));
        const x = (i / (len - 1)) * width;
        const y = height - ((db - minDb) / (maxDb - minDb)) * height;
        if (i === 0) ctx.moveTo(x, y);
        else ctx.lineTo(x, y);
      }
      ctx.strokeStyle = "#ffaa00";
      ctx.lineWidth = 1.5;
      ctx.shadowColor = "#ffaa00";
      ctx.shadowBlur = 4;
      ctx.stroke();
      ctx.shadowBlur = 0;
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
    ctx.shadowColor = lineColor;
    ctx.shadowBlur = 6;
    ctx.stroke();
    ctx.shadowBlur = 0;
  }, [magnitudes, minDb, maxDb, lineColor, fillColor, gridColor, peakHold, peakHoldMagnitudes, showVfo, vfoCenter, vfoLeft, vfoRight]);

  return <canvas ref={canvasRef} className={`w-full h-full ${className}`} />;
}