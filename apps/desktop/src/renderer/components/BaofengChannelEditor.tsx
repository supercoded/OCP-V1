import { useState, useCallback, useRef, useEffect } from "react";
import { AnalogButton } from "./AnalogButton";
import { StatusLamp } from "./StatusLamp";
import { ChannelRow } from "./ChannelRow";
import { createDefaultChannels, validateChannel, channelsToCSV, channelsFromCSV, type ChannelData } from "../lib/baofengChannelModel";
import { useOcpService } from "../contexts/OcpServiceContext";

interface SerialPortInfo {
  path: string;
  manufacturer?: string;
  vendorId?: string;
  productId?: string;
  friendlyName?: string;
}

interface BaofengChannelEditorProps {
  baofengConnect: (portName: string) => Promise<{ ok: boolean; error?: string; portName?: string }>;
  baofengDisconnect: () => Promise<{ ok: boolean }>;
  baofengReadChannels: () => Promise<{ ok: boolean; channels?: ChannelData[]; error?: string }>;
  baofengWriteChannels: (channels: ChannelData[]) => Promise<{ ok: boolean; error?: string }>;
  baofengListPorts: () => Promise<{ ok: boolean; ports?: SerialPortInfo[]; best?: SerialPortInfo; error?: string }>;
  baofengConnected: boolean;
  baofengPortName?: string;
  serialPorts?: SerialPortInfo[];
}

type Phase = "idle" | "connecting" | "identifying" | "reading" | "writing" | "error";

function defaultPortPlaceholder() {
  return navigator.platform?.toLowerCase().includes("win") ? "COM3" : "/dev/ttyUSB0";
}

function portLabel(p: SerialPortInfo) {
  const bits = [p.path];
  if (p.friendlyName) bits.push(p.friendlyName);
  else if (p.manufacturer) bits.push(p.manufacturer);
  return bits.join(" · ");
}

export function BaofengChannelEditor({
  baofengConnect,
  baofengDisconnect,
  baofengReadChannels,
  baofengWriteChannels,
  baofengListPorts,
  baofengConnected,
  baofengPortName,
  serialPorts: serialPortsProp,
}: BaofengChannelEditorProps) {
  const service = useOcpService();
  const baofengPrefs = (service.preferences.pages.devices?.baofeng ?? {}) as Record<string, any>;
  const [channels, setChannels] = useState<ChannelData[]>(() =>
    Array.isArray(baofengPrefs.channels) ? baofengPrefs.channels : createDefaultChannels()
  );
  const [phase, setPhase] = useState<Phase>("idle");
  const [progress, setProgress] = useState({ current: 0, total: 0 });
  const [error, setError] = useState<string | null>(null);
  const [selectedChannel, setSelectedChannel] = useState<number>(Number(baofengPrefs.selectedChannel) || 0);
  const [serialPort, setSerialPort] = useState(baofengPrefs.serialPort ?? "");
  const [ports, setPorts] = useState<SerialPortInfo[]>(serialPortsProp ?? []);
  const [autoConnect, setAutoConnect] = useState(baofengPrefs.autoConnect !== false);
  const [listenStatus, setListenStatus] = useState("Listening for programming cable…");
  const [showWriteConfirm, setShowWriteConfirm] = useState(false);
  const [warnings, setWarnings] = useState<Map<number, string[]>>(new Map());
  const fileInputRef = useRef<HTMLInputElement>(null);
  const connectingRef = useRef(false);

  const saveBaofengPrefs = useCallback((patch: Record<string, any>) => {
    void service.updatePagePreferences("devices", {
      baofeng: {
        ...((service.preferences.pages.devices?.baofeng ?? {}) as Record<string, any>),
        ...patch,
      },
    });
  }, [service]);

  // Sync ports from main-process watch / list
  useEffect(() => {
    if (serialPortsProp?.length) setPorts(serialPortsProp);
  }, [serialPortsProp]);

  useEffect(() => {
    const api = (window as any).ocp;
    if (!api) return;

    const offConnected = api.onBaofengConnected?.((info: { portName: string }) => {
      setSerialPort(info.portName);
      saveBaofengPrefs({ serialPort: info.portName });
      setPhase("idle");
      setError(null);
      setListenStatus(`Connected · ${info.portName}`);
    });

    const offProgress = api.onBaofengProgress?.((info: { current: number; total: number; phase: string }) => {
      setProgress({ current: info.current, total: info.total });
      if (info.phase === "ident") setPhase("identifying");
      else if (info.phase === "read") setPhase("reading");
      else if (info.phase === "write") setPhase("writing");
    });

    void baofengListPorts().then((result) => {
      if (result.ok && result.ports) {
        setPorts(result.ports);
        if (!serialPort && result.best?.path) {
          setSerialPort(result.best.path);
          saveBaofengPrefs({ serialPort: result.best.path });
        } else if (!serialPort && result.ports[0]) {
          setSerialPort(result.ports[0].path);
          saveBaofengPrefs({ serialPort: result.ports[0].path });
        }
        setListenStatus(
          result.ports.length
            ? `Watching ${result.ports.length} serial port(s)`
            : "Listening for programming cable…"
        );
      } else if (result.error) {
        setError(result.error);
        setPhase("error");
      }
    });

    return () => {
      offConnected?.();
      offProgress?.();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps -- mount watchers once
  }, []);

  const handleConnect = useCallback(async (portOverride?: string) => {
    const path = (portOverride || serialPort).trim();
    if (!path) {
      setError(`Enter or select a serial port (e.g. ${defaultPortPlaceholder()})`);
      setPhase("error");
      return;
    }
    if (connectingRef.current) return;
    connectingRef.current = true;
    setPhase("connecting");
    setError(null);
    setListenStatus(`Connecting to ${path}…`);
    try {
      const result = await baofengConnect(path);
      if (!result.ok) {
        setError(result.error ?? "Connection failed");
        setPhase("error");
        setListenStatus("Listening for programming cable…");
      } else {
        setSerialPort(result.portName || path);
        saveBaofengPrefs({ serialPort: result.portName || path });
        setPhase("idle");
        setListenStatus(`Connected · ${result.portName || path}`);
      }
    } finally {
      connectingRef.current = false;
    }
  }, [baofengConnect, serialPort]);

  const handleDisconnect = useCallback(async () => {
    await baofengDisconnect();
    setPhase("idle");
    setError(null);
    setListenStatus("Listening for programming cable…");
  }, [baofengDisconnect]);

  const handleRefreshPorts = useCallback(async () => {
    const result = await baofengListPorts();
    if (result.ok && result.ports) {
      setPorts(result.ports);
      if (result.best?.path && !baofengConnected) {
        setSerialPort(result.best.path);
        saveBaofengPrefs({ serialPort: result.best.path });
      }
      setListenStatus(
        result.ports.length
          ? `Found ${result.ports.length} serial port(s)`
          : "No serial ports found — plug in programming cable"
      );
    } else {
      setError(result.error ?? "Failed to list serial ports");
      setPhase("error");
    }
  }, [baofengListPorts, baofengConnected]);

  const handleRead = useCallback(async () => {
    if (!baofengConnected) return;
    setPhase("reading");
    setProgress({ current: 0, total: 46 });
    setError(null);
    try {
      const result = await baofengReadChannels();
      if (result.ok && result.channels) {
        setChannels(result.channels);
        saveBaofengPrefs({ channels: result.channels });
        setPhase("idle");
      } else {
        setError(result.error ?? "Read failed");
        setPhase("error");
      }
    } catch (err: any) {
      setError(err.message ?? "Read failed");
      setPhase("error");
    }
  }, [baofengConnected, baofengReadChannels, saveBaofengPrefs]);

  const handleWrite = useCallback(async () => {
    setShowWriteConfirm(false);
    if (!baofengConnected) return;

    const newWarnings = new Map<number, string[]>();
    for (const ch of channels) {
      if (ch.rxFreq > 0) {
        const ws = validateChannel(ch);
        if (ws.length > 0) newWarnings.set(ch.index, ws);
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

  const handleExportCSV = useCallback(() => {
    const csv = channelsToCSV(channels);
    const blob = new Blob([csv], { type: "text/csv" });
    const url = URL.createObjectURL(blob);
    const a = document.createElement("a");
    a.href = url;
    a.download = "baofeng-channels.csv";
    a.click();
    URL.revokeObjectURL(url);
  }, [channels]);

  const handleImportCSV = useCallback(() => {
    fileInputRef.current?.click();
  }, []);

  const handleFileSelected = useCallback(async (e: React.ChangeEvent<HTMLInputElement>) => {
    const file = e.target.files?.[0];
    if (!file) return;
    try {
      const text = await file.text();
      const imported = channelsFromCSV(text);
      if (imported.length > 0) {
        setChannels(imported);
        saveBaofengPrefs({ channels: imported });
        for (const ch of imported) {
          // keep indices as model provides
        }
      }
    } catch (err: any) {
      setError(`CSV import failed: ${err.message}`);
      setPhase("error");
    }
    e.target.value = "";
  }, [saveBaofengPrefs]);

  const handleChannelChange = useCallback((index: number, updates: Partial<ChannelData>) => {
    setChannels((prev) => {
      const next = [...prev];
      next[index] = { ...next[index], ...updates };
      saveBaofengPrefs({ channels: next });
      return next;
    });
  }, [saveBaofengPrefs]);

  const handleClearChannel = useCallback(() => {
    setChannels((prev) => {
      const next = [...prev];
      next[selectedChannel] = {
        ...next[selectedChannel],
        rxFreq: 0,
        txFreq: 0,
        duplex: "none",
        toneMode: "None",
        rxToneCode: 0,
        txToneCode: 0,
        name: "",
        power: "High",
        bandwidth: "Wide",
      };
      saveBaofengPrefs({ channels: next });
      return next;
    });
  }, [saveBaofengPrefs, selectedChannel]);

  // Auto-connect when a new programming cable appears
  useEffect(() => {
    const api = (window as any).ocp;
    if (!api?.onBaofengPorts) return;
    return api.onBaofengPorts((info: { ports?: SerialPortInfo[]; best?: SerialPortInfo; added?: string[] }) => {
      if (info.ports) {
        setPorts(info.ports);
        if (!baofengConnected) {
          setListenStatus(
            info.ports.length
              ? `Watching ${info.ports.length} serial port(s)`
              : "Listening for programming cable…"
          );
        }
      }
      if (!serialPort && info.best?.path) {
        setSerialPort(info.best.path);
        saveBaofengPrefs({ serialPort: info.best.path });
      }
      if (baofengConnected || connectingRef.current || !autoConnect) return;
      const added = info.added ?? [];
      if (!added.length) return;
      const candidates = (info.ports ?? []).filter((p) => added.includes(p.path));
      const target =
        candidates.find((p) => p.path === info.best?.path) ||
        info.best ||
        candidates[0];
      if (!target?.path) return;
      setSerialPort(target.path);
      saveBaofengPrefs({ serialPort: target.path });
      void handleConnect(target.path);
    });
  }, [autoConnect, baofengConnected, handleConnect, saveBaofengPrefs, serialPort]);

  const isBusy = phase === "reading" || phase === "writing" || phase === "connecting" || phase === "identifying";
  const progressPct = progress.total > 0 ? Math.round((progress.current / progress.total) * 100) : 0;

  return (
    <div className="flex flex-col gap-3">
      <div className="p-4 rounded-lg border border-ocp-border bg-ocp-panel flex flex-col gap-3">
        <div className="flex items-center justify-between">
          <span className="text-xs uppercase tracking-wider text-ocp-dim font-semibold">
            Baofeng UV-5RM Serial Connection
          </span>
          <StatusLamp
            state={baofengConnected ? "active" : phase === "error" ? "error" : "off"}
            label={baofengConnected ? `Connected · ${baofengPortName || serialPort}` : "Disconnected"}
          />
        </div>

        <div className="text-[10px] text-ocp-dim font-mono">
          {listenStatus}
          {autoConnect ? " · auto-connect on plug-in" : " · manual connect"}
        </div>

        <div className="flex gap-3 items-end flex-wrap">
          <div className="flex flex-col gap-1 flex-1 min-w-[12rem]">
            <label className="text-[10px] uppercase tracking-wider text-ocp-dim">Serial Port</label>
            <select
              value={ports.some((p) => p.path === serialPort) ? serialPort : ""}
              onChange={(e) => {
                setSerialPort(e.target.value);
                saveBaofengPrefs({ serialPort: e.target.value });
              }}
              disabled={baofengConnected || isBusy}
              className="px-3 py-2 rounded-md border border-ocp-border bg-ocp-panel-2 text-ocp-text text-xs font-mono focus:outline-none focus:border-ocp-bright transition-colors disabled:opacity-50"
            >
              <option value="">
                {ports.length ? "Select port…" : "No ports detected"}
              </option>
              {ports.map((p) => (
                <option key={p.path} value={p.path}>
                  {portLabel(p)}
                </option>
              ))}
            </select>
          </div>

          <div className="flex flex-col gap-1 flex-1 min-w-[8rem]">
            <label className="text-[10px] uppercase tracking-wider text-ocp-dim">Or type path</label>
            <input
              type="text"
              value={serialPort}
              onChange={(e) => {
                setSerialPort(e.target.value);
                saveBaofengPrefs({ serialPort: e.target.value });
              }}
              disabled={baofengConnected || isBusy}
              placeholder={defaultPortPlaceholder()}
              className="px-3 py-2 rounded-md border border-ocp-border bg-ocp-panel-2 text-ocp-text text-xs font-mono placeholder:text-ocp-dim/50 focus:outline-none focus:border-ocp-bright transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
            />
          </div>

          <AnalogButton onClick={handleRefreshPorts} disabled={isBusy}>
            Refresh
          </AnalogButton>

          {!baofengConnected ? (
            <AnalogButton variant="accent" onClick={() => handleConnect()} disabled={isBusy || !serialPort}>
              {phase === "connecting" || phase === "identifying" ? "Connecting…" : "Connect"}
            </AnalogButton>
          ) : (
            <AnalogButton onClick={handleDisconnect} disabled={isBusy}>
              Disconnect
            </AnalogButton>
          )}
        </div>

        <label className="flex items-center gap-2 text-[10px] text-ocp-dim cursor-pointer select-none">
          <input
            type="checkbox"
            checked={autoConnect}
            onChange={(e) => {
              setAutoConnect(e.target.checked);
              saveBaofengPrefs({ autoConnect: e.target.checked });
            }}
            className="accent-ocp-green"
          />
          Auto-connect when a USB programming cable appears
        </label>

        {error && (
          <div className="px-3 py-2 rounded border border-ocp-red/50 bg-ocp-red/10 text-xs text-ocp-red font-mono">
            {error}
          </div>
        )}
      </div>

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

      {isBusy && (
        <div className="w-full h-2 bg-ocp-panel-2 rounded-full overflow-hidden">
          <div
            className="h-full bg-ocp-green transition-all duration-300 rounded-full"
            style={{ width: `${progressPct}%` }}
          />
        </div>
      )}

      {showWriteConfirm && (
        <div className="p-4 rounded-lg border border-ocp-amber/50 bg-ocp-panel flex flex-col gap-3">
          <div className="text-xs uppercase tracking-wider text-ocp-amber font-semibold">
            Confirm Write — This will overwrite radio memory
          </div>
          <p className="text-xs text-ocp-dim">
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

      <div className="rounded-lg border border-ocp-border bg-ocp-panel overflow-hidden">
        <div className="overflow-auto max-h-[60vh]">
          <table className="w-full text-left border-collapse">
            <thead>
              <tr className="bg-ocp-panel-2 border-b border-ocp-border">
                <th className="px-2 py-2 text-[10px] uppercase tracking-wider text-ocp-dim font-semibold text-center w-10">#</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-dim font-semibold">RX Freq</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-dim font-semibold">TX Freq</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-dim font-semibold">Dup</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-dim font-semibold">Tone</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-dim font-semibold">RX Tone</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-dim font-semibold">TX Tone</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-dim font-semibold">Name</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-dim font-semibold">Pwr</th>
                <th className="px-1 py-2 text-[10px] uppercase tracking-wider text-ocp-dim font-semibold">BW</th>
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
                  onSelect={(index) => {
                    setSelectedChannel(index);
                    saveBaofengPrefs({ selectedChannel: index });
                  }}
                />
              ))}
            </tbody>
          </table>
        </div>
      </div>

      <div className="flex justify-between text-[10px] text-ocp-dim font-mono">
        <span>128 channels · VHF 136–174 MHz · UHF 400–520 MHz</span>
        <span>Selected: CH{selectedChannel + 1} {channels[selectedChannel]?.name || ""}</span>
        <button
          type="button"
          onClick={handleClearChannel}
          className="text-ocp-amber hover:text-ocp-bright transition-colors"
        >
          Clear channel
        </button>
      </div>
    </div>
  );
}
