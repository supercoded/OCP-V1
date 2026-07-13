import { useEffect, useRef, useCallback } from "react";

export interface Blip {
  id: string;
  angleDeg: number; // 0 = north, clockwise
  distanceRatio: number; // 0..1 relative to maxRange
  strength: number; // 0..1
  label: string;
  type: "meshtastic" | "wifi" | "sdr" | "baofeng" | "mock" | "ruview";
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

// INDI/ATA palette — muted, professional
const TYPE_COLORS: Record<Blip["type"], string> = {
  meshtastic: "#4caf50",    // green for mesh nodes
  ruview: "#c62828",         // red for presence
  sdr: "#4fc3f7",            // cyan for SDR
  baofeng: "#d4a017",        // amber for radio
  mock: "#888888",           // gray for mock
  wifi: "#42a5f5",           // blue for wifi
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

      // Background — dark #111
      ctx.fillStyle = "#111111";
      ctx.fillRect(0, 0, width, height);

      // Grid rings — subtle #333
      ctx.strokeStyle = "#333333";
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

      // Bearing labels — muted #666
      ctx.fillStyle = "#666666";
      ctx.font = `${10 * dpr}px JetBrains Mono, ui-monospace, SFMono-Regular, Menlo, monospace`;
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
      ctx.fillStyle = "#666666";
      ctx.font = `${9 * dpr}px JetBrains Mono, ui-monospace, SFMono-Regular, Menlo, monospace`;
      ctx.textAlign = "left";
      for (let i = 1; i <= 4; i++) {
        const r = (radius / 4) * i;
        const val = Math.round((maxRangeMeters / 4) * i);
        ctx.fillText(`${val}m`, cx + 4 * dpr, cy - r + 10 * dpr);
      }

      // Blips — no glow, solid dots with subtle radial gradient
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

        // Soft halo
        const g = ctx.createRadialGradient(x, y, 0, x, y, 10 * dpr);
        g.addColorStop(0, color + "60");  // 37% alpha
        g.addColorStop(1, "transparent");
        ctx.globalAlpha = decay;
        ctx.fillStyle = g;
        ctx.beginPath();
        ctx.arc(x, y, 10 * dpr, 0, Math.PI * 2);
        ctx.fill();

        // Core dot
        ctx.globalAlpha = decay;
        ctx.fillStyle = color;
        ctx.beginPath();
        ctx.arc(x, y, 3 * dpr, 0, Math.PI * 2);
        ctx.fill();

        // Label — bright white
        ctx.globalAlpha = decay * 0.85;
        ctx.fillStyle = "#c8c8c8";
        ctx.font = `${9 * dpr}px JetBrains Mono, ui-monospace, SFMono-Regular, Menlo, monospace`;
        ctx.fillText(blip.label, x + 8 * dpr, y - 6 * dpr);
      }
      ctx.globalAlpha = 1;

      // Sweep arm — subtle bright line, no glow
      const sweepRad = ((angle - 90) * Math.PI) / 180;

      // Sweep trail — subtle cone
      const gradient = ctx.createConicGradient(
        ((angle - 90) * Math.PI) / 180,
        cx,
        cy
      );
      gradient.addColorStop(0, "rgba(200, 200, 200, 0)");
      gradient.addColorStop(0.85, "rgba(200, 200, 200, 0)");
      gradient.addColorStop(1, "rgba(200, 200, 200, 0.08)");

      ctx.fillStyle = gradient;
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.arc(cx, cy, radius, sweepRad - 0.35, sweepRad);
      ctx.closePath();
      ctx.fill();

      // Sweep line — white, no glow
      ctx.strokeStyle = "#c8c8c8";
      ctx.lineWidth = 1.5 * dpr;
      ctx.beginPath();
      ctx.moveTo(cx, cy);
      ctx.lineTo(cx + Math.cos(sweepRad) * radius, cy + Math.sin(sweepRad) * radius);
      ctx.stroke();

      // Self dot at center
      ctx.fillStyle = "#e8e8e8";
      ctx.beginPath();
      ctx.arc(cx, cy, 4 * dpr, 0, Math.PI * 2);
      ctx.fill();
      ctx.fillStyle = "#888888";
      ctx.font = `${8 * dpr}px JetBrains Mono, monospace`;
      ctx.fillText("SELF", cx + 6 * dpr, cy - 2 * dpr);
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
      className="rounded border border-ocp-border"
      style={{ width: size, height: size }}
    />
  );
}