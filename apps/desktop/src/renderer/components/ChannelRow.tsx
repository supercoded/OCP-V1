import { useState, useCallback } from "react";
import { type ChannelData, validateFrequency, CTCSS_TONES, DCS_CODES, DUPLEX_MODES, TONE_MODES, POWER_LEVELS, BANDWIDTH_OPTIONS } from "../lib/baofengChannelModel";

interface ChannelRowProps {
  channel: ChannelData;
  onChange: (index: number, updates: Partial<ChannelData>) => void;
  selected: boolean;
  onSelect: (index: number) => void;
}

export function ChannelRow({ channel, onChange, selected, onSelect }: ChannelRowProps) {
  const [freqWarning, setFreqWarning] = useState<string | null>(null);

  const handleFreqChange = useCallback(
    (field: "rxFreq" | "txFreq", value: string) => {
      const num = value === "" ? 0 : parseFloat(value);
      if (isNaN(num)) return;

      const validation = validateFrequency(num);
      setFreqWarning(validation.valid ? null : validation.warning ?? null);

      onChange(channel.index, { [field]: num });
    },
    [channel.index, onChange]
  );

  const duplexOptions = DUPLEX_MODES;
  const toneModeOptions = TONE_MODES;
  const powerOptions = POWER_LEVELS;
  const bandwidthOptions = BANDWIDTH_OPTIONS;

  // Get tone value for display
  const getRxToneDisplay = () => {
    if (channel.toneMode === "CTCSS") {
      return CTCSS_TONES[channel.rxToneCode]?.toFixed(1) ?? "67.0";
    }
    if (channel.toneMode === "DCS") {
      return DCS_CODES[channel.rxToneCode]?.toString() ?? "023";
    }
    return "";
  };

  const getTxToneDisplay = () => {
    if (channel.toneMode === "CTCSS") {
      return CTCSS_TONES[channel.txToneCode]?.toFixed(1) ?? "67.0";
    }
    if (channel.toneMode === "DCS") {
      return DCS_CODES[channel.txToneCode]?.toString() ?? "023";
    }
    return "";
  };

  const isPopulated = channel.rxFreq > 0;

  return (
    <tr
      className={[
        "group border-b border-ocp-border/30 transition-colors cursor-pointer",
        selected ? "bg-ocp-accent/10" : isPopulated ? "bg-ocp-panel/50 hover:bg-ocp-panel-2/50" : "bg-ocp-bg/30",
      ].join(" ")}
      onClick={() => onSelect(channel.index)}
    >
      {/* Channel # */}
      <td className="px-2 py-1 text-[10px] font-mono text-ocp-text-dim text-center w-10">
        {channel.index + 1}
      </td>

      {/* RX Freq */}
      <td className="px-1 py-1">
        <input
          type="text"
          value={channel.rxFreq > 0 ? channel.rxFreq.toFixed(5) : ""}
          placeholder="—"
          onChange={(e) => handleFreqChange("rxFreq", e.target.value)}
          className="w-20 px-1 py-0.5 rounded border border-ocp-border/50 bg-ocp-bg text-ocp-accent text-[11px] font-mono text-right focus:outline-none focus:border-ocp-accent/70 placeholder:text-ocp-text-dim/30 transition-colors"
        />
      </td>

      {/* TX Offset / Freq */}
      <td className="px-1 py-1">
        <input
          type="text"
          value={channel.txFreq > 0 ? channel.txFreq.toFixed(5) : ""}
          placeholder="—"
          onChange={(e) => handleFreqChange("txFreq", e.target.value)}
          className="w-20 px-1 py-0.5 rounded border border-ocp-border/50 bg-ocp-bg text-ocp-text text-[11px] font-mono text-right focus:outline-none focus:border-ocp-accent/70 placeholder:text-ocp-text-dim/30 transition-colors"
        />
      </td>

      {/* Duplex */}
      <td className="px-1 py-1">
        <select
          value={channel.duplex}
          onChange={(e) => onChange(channel.index, { duplex: e.target.value })}
          className="px-1 py-0.5 rounded border border-ocp-border/50 bg-ocp-bg text-ocp-text text-[10px] font-mono focus:outline-none focus:border-ocp-accent/70 transition-colors"
        >
          {duplexOptions.map((d) => (
            <option key={d} value={d}>{d}</option>
          ))}
        </select>
      </td>

      {/* Tone Mode */}
      <td className="px-1 py-1">
        <select
          value={channel.toneMode}
          onChange={(e) => onChange(channel.index, { toneMode: e.target.value, rxToneCode: 0, txToneCode: 0 })}
          className="px-1 py-0.5 rounded border border-ocp-border/50 bg-ocp-bg text-ocp-text text-[10px] font-mono focus:outline-none focus:border-ocp-accent/70 transition-colors"
        >
          {toneModeOptions.map((t) => (
            <option key={t} value={t}>{t}</option>
          ))}
        </select>
      </td>

      {/* RX Tone */}
      <td className="px-1 py-1">
        {channel.toneMode !== "None" ? (
          <select
            value={channel.rxToneCode}
            onChange={(e) => onChange(channel.index, { rxToneCode: parseInt(e.target.value, 10) })}
            className="w-16 px-1 py-0.5 rounded border border-ocp-border/50 bg-ocp-bg text-ocp-text text-[10px] font-mono focus:outline-none focus:border-ocp-accent/70 transition-colors"
          >
            {channel.toneMode === "CTCSS"
              ? CTCSS_TONES.map((t, i) => (
                  <option key={i} value={i}>{t.toFixed(1)}</option>
                ))
              : DCS_CODES.map((c, i) => (
                  <option key={i} value={i}>D{c}</option>
                ))}
          </select>
        ) : (
          <span className="text-[10px] text-ocp-text-dim/30">—</span>
        )}
      </td>

      {/* TX Tone */}
      <td className="px-1 py-1">
        {channel.toneMode !== "None" ? (
          <select
            value={channel.txToneCode}
            onChange={(e) => onChange(channel.index, { txToneCode: parseInt(e.target.value, 10) })}
            className="w-16 px-1 py-0.5 rounded border border-ocp-border/50 bg-ocp-bg text-ocp-text text-[10px] font-mono focus:outline-none focus:border-ocp-accent/70 transition-colors"
          >
            {channel.toneMode === "CTCSS"
              ? CTCSS_TONES.map((t, i) => (
                  <option key={i} value={i}>{t.toFixed(1)}</option>
                ))
              : DCS_CODES.map((c, i) => (
                  <option key={i} value={i}>D{c}</option>
                ))}
          </select>
        ) : (
          <span className="text-[10px] text-ocp-text-dim/30">—</span>
        )}
      </td>

      {/* Name */}
      <td className="px-1 py-1">
        <input
          type="text"
          value={channel.name}
          maxLength={7}
          placeholder="—"
          onChange={(e) => onChange(channel.index, { name: e.target.value })}
          className="w-16 px-1 py-0.5 rounded border border-ocp-border/50 bg-ocp-bg text-ocp-text text-[11px] font-mono focus:outline-none focus:border-ocp-accent/70 placeholder:text-ocp-text-dim/30 transition-colors"
        />
      </td>

      {/* Power */}
      <td className="px-1 py-1">
        <select
          value={channel.power}
          onChange={(e) => onChange(channel.index, { power: e.target.value })}
          className="px-1 py-0.5 rounded border border-ocp-border/50 bg-ocp-bg text-ocp-text text-[10px] font-mono focus:outline-none focus:border-ocp-accent/70 transition-colors"
        >
          {powerOptions.map((p) => (
            <option key={p} value={p}>{p === "High" ? "H" : "L"}</option>
          ))}
        </select>
      </td>

      {/* Bandwidth */}
      <td className="px-1 py-1">
        <select
          value={channel.bandwidth}
          onChange={(e) => onChange(channel.index, { bandwidth: e.target.value })}
          className="px-1 py-0.5 rounded border border-ocp-border/50 bg-ocp-bg text-ocp-text text-[10px] font-mono focus:outline-none focus:border-ocp-accent/70 transition-colors"
        >
          {bandwidthOptions.map((b) => (
            <option key={b} value={b}>{b === "Wide" ? "W" : "N"}</option>
          ))}
        </select>
      </td>

      {/* Warning indicator */}
      <td className="px-1 py-1 w-4">
        {freqWarning && (
          <span className="text-ocp-amber text-[10px]" title={freqWarning}>⚠</span>
        )}
      </td>
    </tr>
  );
}