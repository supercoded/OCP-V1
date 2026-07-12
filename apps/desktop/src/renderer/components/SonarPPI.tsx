import { useEffect, useRef, useCallback } from "react";

export interface Blip {
  id: string;
  angleDeg: number; // 0 = north, clockwise
  distanceRatio: number; // 0..1 relative to maxRange
  strength: number; // 0..1
  label: string;
  type: "meshtastic" | "wifi" | "sdr" | "baofeng" | "mock";
  lastHitAt: number;
}

export interface SonarPPIProps {
  blips: Blip[];
  sweepRpm: number;
  audioEnabled: boolean;
  maxRangeMeters: number;
  size?: number;
  onSweepCycle?: () => void;
}

const TYPE_COLORS: Record<Blip["type"], string> = {
  meshtastic: "#00f0a0",
  ruview: "#ff5555",
  sdr: "#00ccff",
  baofeng: "#ffaa00",
  mock: "#888888",
};

export function SonarPPI({
  blips,
  sweepRpm,
  audioEnabled,
  maxRangeMeters,
  size = 640,
  onSweepCycle,
}: SonarPPIProps) {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const angleRef = useRef(0);
  const lastCycleRef = useRef(0);
  const rafRef = useRef<number | null>(null);

  const draw = useCallback(
    (ctx: CanvasRenderingContext2D, angle: number) => {
      const dpr = Math.max(1, Math.floor(window.devicePixelRatio || 1));
      const width = size * dpr;
      const height = size * dpr;
      if (canvasRef.current) {
        canvasRef.current.width = width;
        canvasRef.current.height = height;
      }

      const cx = width / 2;
      const cy = height / 2;
      const radius = Math.min(cx, cy) * 0.9;

      // Background
      ctx.fillStyle = "#050a0e";
      ctx.fillRect(0, 0, width, height);

      // Grid rings
      ctx.strokeStyle = "#123040";
      ctx.lineWidth = dpr;
      for (let i = 1; i <= 4; i++) {
        ctx.beginPath();
        ctx.arc(cx, cy, (radius / 4) * i, 0, Math.PI * 2);
        ctx.stroke();
      }

      // Bearing lines
      for (let deg = 0; deg < 360; deg += 30) {
        const rad = ((deg - 90) * Math.PI) / 180;
        ctx.beginPath();
        ctx.moveTo(cx, cy);
        ctx.lineTo(cx + Math.cos(rad) * radius, cy + Math.sin(rad) * radius);
        ctx.stroke();
      }

      // Bearing labels
      ctx.fillStyle = "#5a7a8a";
      ctx.font = `${10 * dpr}px ui-monospace, SFMono-Regular, Menlo, monospace`;
      ctx.textAlign = "center";
      ctx.textBaseline = "middle";
      const labels = ["N", "30", "60", "E", "120", "150", "S", "210", "240", "W", "300", "330"];
      labels.forEach((label, idx) => {
        const deg = idx * 30;
        const rad = ((deg - 90) * Math.PI) / 180;
        const dist = radius + 14 * dpr;
        ctx.fillText(label, cx + Math.cos(rad) * dist, cy + Math.sin(rad) * dist);
      });

      // Range labels
      ctx.fillStyle = "#5a7a8a";
      ctx.font = `${9 * dpr}px ui-monospace, SFMono-Regular, Menlo, monospace`;
      ctx.textAlign = "left";
      for (let i = 1; i <= 4; i++) {
        const r = (radius / 4) * i;
        const val = Math.round((maxRangeMeters / 4) * i);
        ctx.fillText(`${val}m`, cx + 4 * dpr, cy - r + 10 * dpr);
      }

      // Blip afterglow (drawn as radial glow; intensity decays with time)
      const now = performance.now();
      for (const blip of blips) {
        const age = now - blip.lastHitAt;
        const decay = Math.max(0, 1 - age / 2500);
        if (decay <= 0.02) continue;

        const rad = ((blip.angleDeg - 90) * Math.PI) / 180;
        const r = blip.distanceRatio * radius;
        const x = cx + Math.cos(rad) * r;
        const y = cy + Math.sin(rad) * r;
        const color = TYPE_COLORS[blip.type];

        // Glow
        const g = ctx.createRadialGradient(x, y, 0, x, y, 12 * dpr * (blip.strength + 0.4));
        g.addColorStop(0, color);
        g.addColorStop(1, "transparent");
        ctx.globalAlpha = decay * 0.35;
        ctx.fillStyle = g;
        ctx.beginPath();
        ctx.arc(x, y, 12 * dpr * (blip.strength + 0.4), 0, Math.PI * 2);
        ctx.fill();

        // Core
        ctx.globalAlpha = decay;
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.arc(x, y, 3 * dpr * (blip.strength + 0.5), 0, Math.PI * 2);
        ctx.fill();

        // Label
        ctx.globalAlpha = decay * 0.85;
        ctx.fillStyle = "#b8d4e3";
        ctx.font = `${9 * dpr}px ui-monospace, SFMono-Regular, Menlo, monospace`;
        ctx.fillText(blip.label, x + 8 * dpr, y - 6 * dpr);
      }
      ctx.globalAlpha = 1;

      // Sweep arm with trailing gradient
      const sweepRad = ((angle - 90) * Math.PI) / 180;
      const gradient = ctx.createConicGradient(
        ((angle - 90) * Math.PI) / 180,
        cx,
        cy
      );
      gradient.addColorStop(0, "rgba(0, 240, 160, 0)");
      gradient.addColorStop(0.85, "rgba(0, 240, 160, 0)");
      gradient.addColorStop(1, "rgba(0, 240, 160, 0.25)");

      ctx.fillStyle = gradient;
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.arc(cx, cy, radius, sweepRad - 0.35, sweepRad);
      ctx.closePath();
      ctx.fill();

      // Sweep leading edge
      ctx.strokeStyle = "#00f0a0";
      ctx.lineWidth = 2 * dpr;
      ctx.shadowColor = "#00f0a0";
      ctx.shadowBlur = 14 * dpr;
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.lineTo(cx + Math.cos(sweepRad) * radius, cy + Math.sin(sweepRad) * radius);
      ctx.stroke();
      ctx.shadowBlur = 0;
    },
    [blips, size, maxRangeMeters]
  );

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;
    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    let last = performance.now();
    const loop = (now: number) => {
      const dt = now - last;
      last = now;
      const degPerMs = (sweepRpm * 360) / 60000;
      angleRef.current = (angleRef.current + degPerMs * dt) % 360;

      // Trigger cycle callback roughly once per revolution
      if (angleRef.current < lastCycleRef.current) {
        onSweepCycle?.();
      }
      lastCycleRef.current = angleRef.current;

      draw(ctx, angleRef.current);
      rafRef.current = requestAnimationFrame(loop);
    };
    rafRef.current = requestAnimationFrame(loop);
    return () => {
      if (rafRef.current) cancelAnimationFrame(rafRef.current);
    };
  }, [draw, sweepRpm, onSweepCycle]);

  return (
    <canvas
      ref={canvasRef}
      width={size}
      height={size}
      className="rounded-full border border-ocp-border shadow-[0_0_40px_rgba(0,240,160,0.08)]"
      style={{ width: size, height: size }}
    />
  );
}
