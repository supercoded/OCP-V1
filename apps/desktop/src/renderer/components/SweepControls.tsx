import { AnalogToggle } from "./AnalogToggle";

export interface SweepControlsProps {
  sweepRpm: number;
  onSweepRpmChange: (v: number) => void;
  maxRangeMeters: number;
  onMaxRangeChange: (v: number) => void;
  audioEnabled: boolean;
  onAudioEnabledChange: (v: boolean) => void;
  mockBlips: boolean;
  onMockBlipsChange: (v: boolean) => void;
}

export function SweepControls({
  sweepRpm,
  onSweepRpmChange,
  maxRangeMeters,
  onMaxRangeChange,
  audioEnabled,
  onAudioEnabledChange,
  mockBlips,
  onMockBlipsChange,
}: SweepControlsProps) {
  return (
    <div className="flex flex-col gap-4 p-4 border-l border-ocp-border bg-ocp-panel min-w-[240px]">
      <div className="text-xs uppercase tracking-widest text-ocp-bright font-semibold mb-1">
        Sweep Control
      </div>

      <div className="flex flex-col gap-1">
        <label className="text-[10px] uppercase tracking-wider text-ocp-dim">
          Sweep Speed: {sweepRpm} RPM
        </label>
        <input
          type="range"
          min={2}
          max={30}
          step={1}
          value={sweepRpm}
          onChange={(e) => onSweepRpmChange(Number(e.target.value))}
          className="w-full accent-ocp-accent"
        />
      </div>

      <div className="flex flex-col gap-1">
        <label className="text-[10px] uppercase tracking-wider text-ocp-dim">
          Max Range: {maxRangeMeters} m
        </label>
        <input
          type="range"
          min={10}
          max={1000}
          step={10}
          value={maxRangeMeters}
          onChange={(e) => onMaxRangeChange(Number(e.target.value))}
          className="w-full accent-ocp-accent"
        />
      </div>

      <div className="flex flex-col gap-2">
        <AnalogToggle
          label="Sonar Audio"
          checked={audioEnabled}
          onChange={onAudioEnabledChange}
        />
        <AnalogToggle
          label="Mock Blips"
          checked={mockBlips}
          onChange={onMockBlipsChange}
        />
      </div>
    </div>
  );
}
