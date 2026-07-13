import { useState, useEffect, useRef, useCallback } from "react";

export interface VfoState {
  centerFreq: number; // Hz
  bandwidth: number; // Hz
}

interface VfoIndicatorProps {
  vfo: VfoState;
  onVfoChange: (vfo: VfoState) => void;
  spectrumCenterFreq: number; // Hz — center of the visible spectrum
  spectrumSampleRate: number; // Hz — total visible bandwidth
  className?: string;
}

export function VfoIndicator({
  vfo,
  onVfoChange,
  spectrumCenterFreq,
  spectrumSampleRate,
  className = "",
}: VfoIndicatorProps) {
  // VFO position as fraction [0,1] within the visible spectrum
  const vfoOffset = spectrumSampleRate > 0
    ? (vfo.centerFreq - spectrumCenterFreq + spectrumSampleRate / 2) / spectrumSampleRate
    : 0.5;
  const vfoWidthFraction = spectrumSampleRate > 0
    ? vfo.bandwidth / spectrumSampleRate
    : 0.05;

  const leftPct = Math.max(0, Math.min(100, ((vfoOffset - vfoWidthFraction / 2)) * 100));
  const widthPct = Math.max(0.5, Math.min(100 - leftPct, vfoWidthFraction * 100));

  return (
    <div className={`absolute inset-0 pointer-events-none ${className}`}>
      {/* VFO band */}
      <div
        className="absolute top-0 bottom-0 border-x-2 border-ocp-accent/60 bg-ocp-accent/8"
        style={{
          left: `${leftPct}%`,
          width: `${widthPct}%`,
        }}
      />
      {/* Center frequency line */}
      <div
        className="absolute top-0 bottom-0 w-px bg-ocp-accent/80"
        style={{
          left: `${Math.max(0, Math.min(100, vfoOffset * 100))}%`,
        }}
      />
    </div>
  );
}

interface VfoReadoutProps {
  vfo: VfoState;
  onBandwidthChange: (bw: number) => void;
  minBw?: number;
  maxBw?: number;
}

export function VfoReadout({
  vfo,
  onBandwidthChange,
  minBw = 5000,
  maxBw = 500000,
}: VfoReadoutProps) {
  const freqMhz = (vfo.centerFreq / 1e6).toFixed(3);
  const bwKhz = (vfo.bandwidth / 1e3).toFixed(1);

  return (
    <div className="space-y-2">
      <div className="flex items-center gap-2">
        <span className="text-[10px] uppercase tracking-wider text-ocp-text-dim">VFO</span>
        <span className="text-xs font-mono text-ocp-accent">{freqMhz} MHz</span>
        <span className="text-[10px] text-ocp-text-dim">@</span>
        <span className="text-xs font-mono text-ocp-accent">{bwKhz} kHz</span>
      </div>
      <div className="space-y-1">
        <label className="text-[10px] uppercase tracking-wider text-ocp-text-dim">
          VFO Bandwidth
        </label>
        <input
          type="range"
          min={minBw}
          max={maxBw}
          step={1000}
          value={vfo.bandwidth}
          onChange={(e) => onBandwidthChange(parseInt(e.target.value, 10))}
          className="w-full h-1 bg-ocp-border rounded appearance-none cursor-pointer accent-ocp-accent"
        />
      </div>
    </div>
  );
}