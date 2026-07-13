import { useState, useCallback, useRef } from "react";
import { AnalogButton } from "./AnalogButton";
import { StatusLamp } from "./StatusLamp";
import { ChannelRow } from "./ChannelRow";
import { createDefaultChannels, validateChannel, channelsToCSV, channelsFromCSV, type ChannelData } from "../lib/baofengChannelModel";

interface BaofengChannelEditorProps {
  // IPC methods injected from OcpServiceContext
  baofengConnect: (portName: string) => Promise<{ ok: boolean; error?: string }>;
  baofengDisconnect: () => Promise<{ ok: boolean }>;
  baofengReadChannels: () => Promise<{ ok: boolean; channels?: ChannelData[]; error?: string }>;
  baofengWriteChannels: (channels: ChannelData[]) => Promise<{ ok: boolean; error?: string }>;
  baofengConnected: boolean;
  baofengPortName?: string;
}

type Phase = "idle" | "connecting" | "identifying" | "reading" | "writing" | "error";

export function BaofengChannelEditor({
  baofengConnect,
  baofengDisconnect,
  baofengReadChannels,
  baofengWriteChannels,
  baofengConnected,
  baofengPortName,
}: BaofengChannelEditorProps) {
  const [channels, setChannels] = useState<ChannelData[]>(() => createDefaultChannels());
  const [phase, setPhase] = useState<Phase>("idle");
  const [progress, setProgress] = useState({ current: 0, total: 0 });
  const [error, setError] = useState<string | null>(null);
  const [selectedChannel, setSelectedChannel] = useState<number>(0);
  const [serialPort, setSerialPort] = useState("/dev/ttyUSB0");
  const [showWriteConfirm, setShowWriteConfirm] = useState(false);
  const [warnings, setWarnings] = useState<Map<number, string[]>>(new Map());
  const fileInputRef = useRef<HTMLInputElement>(null);

  const handleConnect = useCallback(async () => {
    setPhase("connecting");
    setError(null);
    const result = await baofengConnect(serialPort);
    if (!result.ok) {
      setError(result.error ?? "Connection failed");
      setPhase("error");
    } else {
      setPhase("idle");
    }
  }, [baofengConnect, serialPort]);

  const handleDisconnect = useCallback(async () => {
    await baofengDisconnect();
    setPhase("idle");
    setError(null);
  }, [baofengDisconnect]);

  const handleRead = useCallback(async () => {
    if (!baofengConnected) return;
    setPhase("reading");
    setProgress({ current: 0, total: 46 }); // 32 channel ops + 14 name ops
    setError(null);
    try {
      const result = await baofengReadChannels();
      if (result.ok && result.channels) {
        setChannels(result.channels);
        setPhase("idle");
      } else {
        setError(result.error ?? "Read failed");
        setPhase("error");
      }
    } catch (err: any) {
      setError(err.message ?? "Read failed");
      setPhase("error");
    }
  }, [baofengConnected, baofengReadChannels]);

  const handleWrite = useCallback(async () => {
    setShowWriteConfirm(false);
    if (!baofengConnected) return;

    // Validate all channels before writing
    const newWarnings = new Map<number, string[]>();
    let hasErrors = false;
    for (const ch of channels) {
      if (ch.rxFreq > 0) {
        const ws = validateChannel(ch);
        if (ws.length > 0) {
          newWarnings.set(ch.index, ws);
          hasErrors = true;
        }
      }
    }
    setWarnings(newWarnings);

    setPhase("writing");
    setProgress({ current: 0, total: 46 });
    setError(null);
    try {
      const result = await baofengWriteChannels(channels);
      if (result.ok) {
        setPhase("idle");
      } else {
        setError(result.error ?? "Write failed");
        setPhase("error");
      }
    } catch (err: any) {
      setError(err.message ?? "Write failed");
      setPhase("error");
    }
  }, [baofengConnected, baofengWriteChannels, channels]);

  const handleChannelChange = useCallback((index: number, updates: Partial<ChannelData>) => {
    setChannels((prev) => {
      const next = [...prev];
      next[index] = { ...next[index], ...updates };
      return next;
    });
  }, []);

  const handleExportCSV = useCallback(() => {
    const csv = channelsToCSV(channels);
    const blob = new Blob([csv], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = `baofeng-channels-${new Date().toISOString().slice(0, 10)}.csv`;
    a.click();
    URL.revokeObjectURL(url);
  }, [channels]);

  const handleImportCSV = useCallback(() => {
    fileInputRef.current?.click();
  }, []);

  const handleFileSelected = useCallback((e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    const reader = new FileReader();
    reader.onload = (ev) => {
      try {
        const text = ev.target?.result as string;
        const imported = channelsFromCSV(text);
        if (imported.length > 0) {
          const newChannels = createDefaultChannels();
          for (const ch of imported) {
            if (ch.index >= 0 && ch.index < 128) {
              newChannels[ch.index] = ch;
            }
          }
          setChannels(newChannels);
        }
      } catch (err: any) {
        setError(`CSV import failed: ${err.message}`);
      }
    };
    reader.readAsText(file);
    // Reset file input so the same file can be re-selected
    e.target.value = "";
  }, []);

  const handleClearChannel = useCallback(() => {
    setChannels((prev) => {
      const next = [...prev];
      next[selectedChannel] = { ...next[selectedChannel], rxFreq: 0, txFreq: 0, duplex: "none", toneMode: "None", rxToneCode: 0, txToneCode: 0, name: "", power: "High", bandwidth: "Wide" };
      return next;
    });
  }, [selectedChannel]);

  const isBusy = phase === "reading" || phase === "writing" || phase === "connecting" || phase === "identifying";
  const progressPct = progress.total > 0 ? Math.round((progress.current / progress.total) * 100) : 0;

  return (
    <div className="flex flex-col gap-3">
      {/* Connection controls */}
      <div className="p-4 rounded-lg border border-ocp-border bg-ocp-panel flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <span className="text-xs uppercase tracking-wider text-ocp-text-dim font-semibold">
            Baofeng UV-5RM Serial Connection
          </span>
          <StatusLamp
            state={baofengConnected ? "active" : phase === "error" ? "error" : "off"}
            label={baofengConnected ? `Connected · ${baofengPortName || serialPort}` : "Disconnected"}
          />
        </div>

        <div className="flex gap-3 items-end">
          <div className="flex flex-col gap-1 flex-1">
            <label className="text-[10px] uppercase tracking-wider text-ocp-text-dim">Serial Port</label>
            <input
              type="text"
              value={serialPort}
              onChange={(e) => setSerialPort(e.target.value)}
              disabled={baofengConnected || isBusy}
              placeholder="/dev/ttyUSB0"
              className="px-3 py-2 rounded-md border border-ocp-border bg-ocp-panel-2 text-ocp-text text-xs font-mono placeholder:text-ocp-text-dim/50 focus:outline-none focus:border-ocp-accent transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            />
          </div>

          {!baofengConnected ? (
            <AnalogButton variant="accent" onClick={handleConnect} disabled={isBusy}>
              {phase === "connecting" ? "Connecting…" : "Connect"}
            </AnalogButton>
          ) : (
            <AnalogButton onClick={handleDisconnect} disabled={isBusy}>
              Disconnect
            </AnalogButton>
          )}
        </div>

        {error && (
          <div className="px-3 py-2 rounded border border-ocp-red/50 bg-ocp-red/10 text-xs text-ocp-red font-mono">
            {error}
          </div>
        )}
      </div>

      {/* Action buttons */}
      <div className="flex gap-3 items-center">
        <AnalogButton variant="accent" onClick={handleRead} disabled={!baofengConnected || isBusy}>
          {phase === "reading" ? `Reading ${progressPct}%…` : "Read from Radio"}
        </AnalogButton>
        <AnalogButton onClick={() => setShowWriteConfirm(true)} disabled={!baofengConnected || isBusy}>
          {phase === "writing" ? `Writing ${progressPct}%…` : "Write to Radio"}
        </AnalogButton>

        <div className="flex-1" />

        <AnalogButton onClick={handleImportCSV} disabled={isBusy}>
          Import CSV
        </AnalogButton>
        <AnalogButton onClick={handleExportCSV} disabled={isBusy}>
          Export CSV
        </AnalogButton>
        <input
          ref={fileInputRef}
          type="file"
          accept=".csv"
          className="hidden"
          onChange={handleFileSelected}
        />
      </div>

      {/* Progress bar */}
      {isBusy && (
        <div className="w-full h-2 bg-ocp-panel-2 rounded-full overflow-hidden">
          <div
            className="h-full bg-ocp-accent transition-all duration-300 rounded-full"
            style={{ width: `${progressPct}%` }}
          />
        </div>
      )}

      {/* Write confirmation dialog */}
      {showWriteConfirm && (
        <div className="p-4 rounded-lg border border-ocp-amber/50 bg-ocp-panel flex flex-col gap-3">
          <div className="text-xs uppercase tracking-wider text-ocp-amber font-semibold">
            ⚠ Confirm Write — This will overwrite radio memory
          </div>
          <p className="text-xs text-ocp-text-dim">
            Writing to the Baofeng UV-5RM is irreversible. Make sure you have a backup of the current channel data.
            {warnings.size > 0 && ` ${warnings.size} channel(s) have out-of-band warnings.`}
          </p>
          <div className="flex gap-3">
            <AnalogButton variant="danger" onClick={handleWrite}>
              Write Channels
            </AnalogButton>
            <AnalogButton onClick={() => setShowWriteConfirm(false)}>Cancel</AnalogButton>
          </div>
        </div>
      )}

      {/* Channel editor table */}
      <div className="rounded-lg border border-ocp-border bg-ocp-panel overflow-hidden">
        <div className="overflow-auto max-h-[60vh]">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-ocp-panel-2 border-b border-ocp-border">
                <th className="px-2 py-2 text-[10px] uppercase tracking-wider text-ocp-text-dim font-semibold text-center w-10">#</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-text-dim font-semibold">RX Freq</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-text-dim font-semibold">TX Freq</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-text-dim font-semibold">Dup</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-text-dim font-semibold">Tone</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-text-dim font-semibold">RX Tone</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-text-dim font-semibold">TX Tone</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-text-dim font-semibold">Name</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-text-dim font-semibold">Pwr</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-text-dim font-semibold">BW</th>
                <th className="px-1 py-2 w-4"></th>
              </tr>
            </thead>
            <tbody>
              {channels.map((ch) => (
                <ChannelRow
                  key={ch.index}
                  channel={ch}
                  onChange={handleChannelChange}
                  selected={selectedChannel === ch.index}
                  onSelect={setSelectedChannel}
                />
              ))}
            </tbody>
          </table>
        </div>
      </div>

      {/* Footer info */}
      <div className="flex justify-between text-[10px] text-ocp-text-dim font-mono">
        <span>128 channels · VHF 136–174 MHz · UHF 400–520 MHz</span>
        <span>Selected: CH{selectedChannel + 1} {channels[selectedChannel]?.name || ""}</span>
        <button
          type="button"
          onClick={handleClearChannel}
          className="text-ocp-amber hover:text-ocp-accent transition-colors"
        >
          Clear channel
        </button>
      </div>
    </div>
  );
}