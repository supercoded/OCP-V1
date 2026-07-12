import { useState, useEffect, useCallback, useRef } from "react";
import { useOcpService, type SpectrumFrame } from "../contexts/OcpServiceContext";
import { SpectrumCanvas } from "../components/SpectrumCanvas";
import { WaterfallCanvas } from "../components/WaterfallCanvas";
import { AnalogButton } from "../components/AnalogButton";
import { TextField } from "../components/TextField";
import { StatusLamp } from "../components/StatusLamp";

function formatFreq(hz?: number) {
  if (hz === undefined) return "";
  return (hz / 1e6).toFixed(3);
}

export function SpectrumPage() {
  const service = useOcpService();
  const [host, setHost] = useState("localhost");
  const [port, setPort] = useState("1234");
  const [centerFreq, setCenterFreq] = useState("100.000");
  const [gainMode, setGainMode] = useState<"auto" | "manual">("auto");
  const [gainValue, setGainValue] = useState("0.0");
  const [frame, setFrame] = useState<SpectrumFrame | null>(null);
  const lastFrameRef = useRef<SpectrumFrame | null>(null);

  useEffect(() => {
    const unsub = (window as any).ocp?.onRtlSpectrum((f: SpectrumFrame) => {
      lastFrameRef.current = f;
      setFrame(f);
    });
    return () => unsub?.();
  }, []);

  const connect = useCallback(async () => {
    const result = await service.connectRtl({
      host,
      port: parseInt(port, 10),
      centerFreq: parseFloat(centerFreq) * 1e6,
    });
    if (result.ok) {
      // State will update via IPC; nothing else needed.
    }
  }, [service, host, port, centerFreq]);

  const connectMock = useCallback(async () => {
    await service.startRtlMock({ centerFreq: parseFloat(centerFreq) * 1e6 });
  }, [service, centerFreq]);

  const disconnect = useCallback(async () => {
    await service.disconnectRtl();
    setFrame(null);
    lastFrameRef.current = null;
  }, [service]);

  const applyFreq = useCallback(async () => {
    await service.setRtlFreq(parseFloat(centerFreq) * 1e6);
  }, [service, centerFreq]);

  const applyGain = useCallback(async () => {
    await service.setRtlGain({
      mode: gainMode,
      value: gainMode === "manual" ? parseFloat(gainValue) : undefined,
    });
  }, [service, gainMode, gainValue]);

  return (
    <div className="absolute inset-0 p-4 flex flex-col gap-3">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold tracking-widest uppercase text-ocp-accent text-glow">
          Spectrum
        </h2>
        <div className="flex items-center gap-3">
          <StatusLamp active={service.state.rtlConnected} label={service.state.rtlConnected ? "LIVE" : "OFFLINE"} />
          <div className="text-xs font-mono text-ocp-text-dim">
            {frame ? `${(frame.centerFreq / 1e6).toFixed(3)} MHz · ${(frame.sampleRate / 1e6).toFixed(3)} MSPS · ${frame.fftSize} bins` : "No source"}
          </div>
        </div>
      </div>

      <div className="flex flex-col lg:flex-row gap-3 flex-1 min-h-0">
        {/* Spectrum + waterfall */}
        <div className="flex-1 flex flex-col gap-2 min-h-0">
          <div className="flex-1 relative rounded border border-ocp-border bg-ocp-panel overflow-hidden">
            <SpectrumCanvas magnitudes={frame?.magnitudes ?? new Float32Array(0)} />
          </div>
          <div className="h-48 relative rounded border border-ocp-border bg-ocp-panel overflow-hidden">
            <WaterfallCanvas magnitudes={frame?.magnitudes ?? new Float32Array(0)} />
          </div>
        </div>

        {/* Controls */}
        <div className="w-full lg:w-72 flex flex-col gap-3 shrink-0">
          <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
            <div className="text-xs uppercase tracking-wider text-ocp-text-dim">rtl_tcp Source</div>
            <TextField label="Host" value={host} onChange={setHost} />
            <TextField label="Port" value={port} onChange={setPort} />
            <div className="grid grid-cols-2 gap-2">
              <AnalogButton onClick={connect} disabled={service.state.rtlConnected}>Connect</AnalogButton>
              <AnalogButton onClick={disconnect} disabled={!service.state.rtlConnected}>Disconnect</AnalogButton>
            </div>
            <div className="text-[10px] text-ocp-text-dim">
              Run <code>rtl_tcp -a 0.0.0.0 -p 1234</code> on the host, then connect.
            </div>
          </div>

          <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
            <div className="text-xs uppercase tracking-wider text-ocp-text-dim">Mock Source</div>
            <div className="text-[10px] text-ocp-text-dim mb-1">
              For UI testing without an RTL-SDR dongle.
            </div>
            <AnalogButton onClick={connectMock} disabled={service.state.rtlConnected}>Start Mock Signal</AnalogButton>
          </div>

          <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
            <div className="text-xs uppercase tracking-wider text-ocp-text-dim">Receiver Settings</div>
            <TextField label="Center Freq (MHz)" value={centerFreq} onChange={setCenterFreq} />
            <div className="grid grid-cols-2 gap-2">
              <AnalogButton onClick={applyFreq} disabled={!service.state.rtlConnected}>Set Freq</AnalogButton>
              <div />
            </div>
            <div className="flex gap-2">
              <select
                className="bg-ocp-bg border border-ocp-border rounded px-2 py-1 text-xs text-ocp-text"
                value={gainMode}
                onChange={(e) => setGainMode(e.target.value as "auto" | "manual")}
                disabled={!service.state.rtlConnected}
              >
                <option value="auto">Auto Gain</option>
                <option value="manual">Manual</option>
              </select>
              <TextField label="Gain dB" value={gainValue} onChange={setGainValue} disabled={gainMode === "auto" || !service.state.rtlConnected} />
            </div>
            <AnalogButton onClick={applyGain} disabled={!service.state.rtlConnected}>Set Gain</AnalogButton>
          </div>

          {service.rtlError && (
            <div className="p-2 rounded border border-red-900/50 bg-red-900/20 text-xs text-red-300 font-mono">
              {service.rtlError}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
