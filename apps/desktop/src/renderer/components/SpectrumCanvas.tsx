import { useEffect, useRef } from "react";

interface SpectrumCanvasProps {
  magnitudes: Float32Array;
  minDb?: number;
  maxDb?: number;
  lineColor?: string;
  fillColor?: string;
  gridColor?: string;
  className?: string;
}

export function SpectrumCanvas({
  magnitudes,
  minDb = -120,
  maxDb = -20,
  lineColor = "#00ff9d",
  fillColor = "rgba(0, 255, 157, 0.15)",
  gridColor = "rgba(0, 255, 157, 0.15)",
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
  }, [magnitudes, minDb, maxDb, lineColor, fillColor, gridColor]);

  return <canvas ref={canvasRef} className={`w-full h-full ${className}`} />;
}
