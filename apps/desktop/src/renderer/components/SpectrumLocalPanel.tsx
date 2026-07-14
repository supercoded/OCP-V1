import { useState, useEffect, useCallback, useRef } from "react";
import { useOcpService, type SpectrumFrame } from "../contexts/OcpServiceContext";
import { SpectrumCanvas } from "./SpectrumCanvas";
import { WaterfallCanvas } from "./WaterfallCanvas";
import { AnalogButton } from "./AnalogButton";
import { AnalogToggle } from "./AnalogToggle";
import { TextField } from "./TextField";
import { StatusLamp } from "./StatusLamp";
import { BookmarksPanel, type Bookmark } from "./BookmarksPanel";
import { VfoReadout, type VfoState } from "./VfoIndicator";

function formatDuration(ms: number) {
  const s = Math.floor(ms / 1000);
  const m = Math.floor(s / 60);
  const sec = s % 60;
  return `${m.toString().padStart(2, "0")}:${sec.toString().padStart(2, "0")}`;
}

export function SpectrumLocalPanel() {
  const service = useOcpService();
  const localPrefs = (service.preferences.pages.spectrum?.local ?? {}) as Record<string, any>;
  const [host, setHost] = useState(localPrefs.host ?? "localhost");
  const [port, setPort] = useState(localPrefs.port ?? "1234");
  const [centerFreq, setCenterFreq] = useState(localPrefs.centerFreq ?? "100.000");
  const [gainMode, setGainMode] = useState<"auto" | "manual">(localPrefs.gainMode === "manual" ? "manual" : "auto");
  const [gainValue, setGainValue] = useState(localPrefs.gainValue ?? "0.0");
  const [frame, setFrame] = useState<SpectrumFrame | null>(null);
  const lastFrameRef = useRef<SpectrumFrame | null>(null);

  const [peakHoldEnabled, setPeakHoldEnabled] = useState(!!localPrefs.peakHoldEnabled);
  const peakHoldRef = useRef<Float32Array | null>(null);
  const peakDecayRate = 0.002;

  const [vfo, setVfo] = useState<VfoState>({
    centerFreq: Number(localPrefs.vfoCenterFreq) || Number.parseFloat(localPrefs.centerFreq ?? "100.000") * 1e6 || 100000000,
    bandwidth: Number(localPrefs.vfoBandwidth) || 15000,
  });
  const [showVfo, setShowVfo] = useState(localPrefs.showVfo !== false);

  const [isRecording, setIsRecording] = useState(false);
  const [recordingStart, setRecordingStart] = useState<number | null>(null);
  const [recordingDuration, setRecordingDuration] = useState(0);
  const recordingTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);
  const vfoLockedRef = useRef(false);
  const prefsHydratedRef = useRef(false);

  const saveLocalPrefs = useCallback((patch: Record<string, any>) => {
    void service.updatePagePreferences("spectrum", {
      local: {
        ...((service.preferences.pages.spectrum?.local ?? {}) as Record<string, any>),
        ...patch,
      },
    });
  }, [service]);

  useEffect(() => {
    const prefs = (service.preferences.pages.spectrum?.local ?? {}) as Record<string, any>;
    if (prefsHydratedRef.current || !Object.keys(prefs).length) return;
    prefsHydratedRef.current = true;
    if (typeof prefs.host === "string") setHost(prefs.host);
    if (typeof prefs.port === "string") setPort(prefs.port);
    if (typeof prefs.centerFreq === "string") setCenterFreq(prefs.centerFreq);
    if (prefs.gainMode === "auto" || prefs.gainMode === "manual") setGainMode(prefs.gainMode);
    if (typeof prefs.gainValue === "string") setGainValue(prefs.gainValue);
    if (typeof prefs.peakHoldEnabled === "boolean") setPeakHoldEnabled(prefs.peakHoldEnabled);
    if (typeof prefs.showVfo === "boolean") setShowVfo(prefs.showVfo);
    setVfo((prev) => ({
      centerFreq: Number(prefs.vfoCenterFreq) || Number.parseFloat(prefs.centerFreq ?? "") * 1e6 || prev.centerFreq,
      bandwidth: Number(prefs.vfoBandwidth) || prev.bandwidth,
    }));
  }, [service.preferences.pages.spectrum?.local]);

  useEffect(() => {
    const unsub = (window as any).ocp?.onRtlSpectrum((f: SpectrumFrame) => {
      lastFrameRef.current = f;

      if (peakHoldEnabled && f.magnitudes.length > 0) {
        if (!peakHoldRef.current || peakHoldRef.current.length !== f.magnitudes.length) {
          peakHoldRef.current = new Float32Array(f.magnitudes);
        } else {
          const peak = peakHoldRef.current;
          for (let i = 0; i < peak.length; i++) {
            if (f.magnitudes[i] > peak[i]) {
              peak[i] = f.magnitudes[i];
            } else {
              peak[i] -= peakDecayRate;
            }
          }
        }
      }

      if (!vfoLockedRef.current) {
        setVfo((prev) => ({ ...prev, centerFreq: f.centerFreq }));
      }

      setFrame(f);
    });
    return () => unsub?.();
  }, [peakHoldEnabled]);

  useEffect(() => {
    if (!peakHoldEnabled) {
      peakHoldRef.current = null;
    }
  }, [peakHoldEnabled]);

  useEffect(() => {
    if (isRecording && recordingStart) {
      recordingTimerRef.current = setInterval(() => {
        setRecordingDuration(Date.now() - recordingStart!);
      }, 500);
    } else {
      if (recordingTimerRef.current) clearInterval(recordingTimerRef.current);
      recordingTimerRef.current = null;
    }
    return () => {
      if (recordingTimerRef.current) clearInterval(recordingTimerRef.current);
    };
  }, [isRecording, recordingStart]);

  useEffect(() => {
    const api = (window as any).ocp;
    if (!api) return;
    const unsubStarted = api.onRtlRecordingStarted?.(() => {
      setIsRecording(true);
      setRecordingStart(Date.now());
      setRecordingDuration(0);
    });
    const unsubStopped = api.onRtlRecordingStopped?.(() => {
      setIsRecording(false);
      setRecordingStart(null);
      setRecordingDuration(0);
    });
    return () => {
      unsubStarted?.();
      unsubStopped?.();
    };
  }, []);

  const connect = useCallback(async () => {
    const result = await service.connectRtl({
      host,
      port: parseInt(port, 10),
      centerFreq: parseFloat(centerFreq) * 1e6,
    });
    if (result.ok) {
      setVfo({ centerFreq: parseFloat(centerFreq) * 1e6, bandwidth: vfo.bandwidth });
    }
  }, [service, host, port, centerFreq, vfo.bandwidth]);

  const connectMock = useCallback(async () => {
    await service.startRtlMock({ centerFreq: parseFloat(centerFreq) * 1e6 });
    setVfo({ centerFreq: parseFloat(centerFreq) * 1e6, bandwidth: vfo.bandwidth });
  }, [service, centerFreq, vfo.bandwidth]);

  const disconnect = useCallback(async () => {
    await service.disconnectRtl();
    setFrame(null);
    lastFrameRef.current = null;
    peakHoldRef.current = null;
    setIsRecording(false);
    setRecordingStart(null);
    vfoLockedRef.current = false;
  }, [service]);

  const applyFreq = useCallback(async () => {
    await service.setRtlFreq(parseFloat(centerFreq) * 1e6);
    setVfo((prev) => ({ ...prev, centerFreq: parseFloat(centerFreq) * 1e6 }));
    vfoLockedRef.current = false;
  }, [service, centerFreq]);

  const applyGain = useCallback(async () => {
    await service.setRtlGain({
      mode: gainMode,
      value: gainMode === "manual" ? parseFloat(gainValue) : undefined,
    });
  }, [service, gainMode, gainValue]);

  const tuneToBookmark = useCallback(async (freqHz: number, bookmark?: Bookmark) => {
    setCenterFreq((freqHz / 1e6).toFixed(3));
    setVfo((prev) => ({ ...prev, centerFreq: freqHz, bandwidth: bookmark?.bandwidth ?? prev.bandwidth }));
    saveLocalPrefs({
      centerFreq: (freqHz / 1e6).toFixed(3),
      vfoCenterFreq: freqHz,
      vfoBandwidth: bookmark?.bandwidth ?? vfo.bandwidth,
    });
    vfoLockedRef.current = true;
    if (service.state.rtlConnected) {
      await service.setRtlFreq(freqHz);
    }
  }, [service, saveLocalPrefs, vfo.bandwidth]);

  const toggleRecording = useCallback(async () => {
    if (isRecording) {
      const result = await service.stopRtlRecording();
      if (result.ok) {
        setIsRecording(false);
        setRecordingStart(null);
      }
    } else {
      const result = await service.startRtlRecording();
      if (result.ok) {
        setIsRecording(true);
        setRecordingStart(Date.now());
        setRecordingDuration(0);
      }
    }
  }, [isRecording, service]);

  const handleSpectrumClick = useCallback(async (e: React.MouseEvent<HTMLDivElement>) => {
    if (!frame || !showVfo) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const fraction = x / rect.width;
    const startFreq = frame.centerFreq - frame.sampleRate / 2;
    const clickFreq = startFreq + fraction * frame.sampleRate;
    const nextCenter = (clickFreq / 1e6).toFixed(3);
    setVfo((prev) => ({ ...prev, centerFreq: clickFreq }));
    setCenterFreq(nextCenter);
    saveLocalPrefs({ centerFreq: nextCenter, vfoCenterFreq: clickFreq });
    vfoLockedRef.current = true;
    if (service.state.rtlConnected) {
      await service.setRtlFreq(clickFreq);
    }
  }, [frame, saveLocalPrefs, service, showVfo]);

  let vfoLeftBin: number | undefined;
  let vfoRightBin: number | undefined;
  let vfoCenterBin: number | undefined;
  if (frame && frame.magnitudes.length > 0 && showVfo) {
    const binSize = frame.sampleRate / frame.fftSize;
    const startFreq = frame.centerFreq - frame.sampleRate / 2;
    vfoCenterBin = Math.round((vfo.centerFreq - startFreq) / binSize);
    vfoLeftBin = Math.round((vfo.centerFreq - vfo.bandwidth / 2 - startFreq) / binSize);
    vfoRightBin = Math.round((vfo.centerFreq + vfo.bandwidth / 2 - startFreq) / binSize);
  }

  return (
    <div className="flex flex-col lg:flex-row gap-3 flex-1 min-h-0">
      <div className="flex-1 flex flex-col gap-2 min-h-0">
        <div className="flex items-center justify-end gap-3 shrink-0">
          {isRecording && (
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-red-500 animate-pulse" />
              <span className="text-xs font-mono text-red-400">
                REC {formatDuration(recordingDuration)}
              </span>
            </div>
          )}
          <StatusLamp state={service.state.rtlConnected ? "active" : "off"} label={service.state.rtlConnected ? "LIVE" : "OFFLINE"} />
          <div className="text-xs font-mono text-ocp-dim">
            {frame ? `${(frame.centerFreq / 1e6).toFixed(3)} MHz · ${(frame.sampleRate / 1e6).toFixed(3)} MSPS · ${frame.fftSize} bins` : "No source"}
          </div>
        </div>

        <div
          className="flex-1 relative rounded border border-ocp-border bg-ocp-panel overflow-hidden min-h-[200px]"
          onClick={handleSpectrumClick}
        >
          <SpectrumCanvas
            magnitudes={frame?.magnitudes ?? new Float32Array(0)}
            peakHold={peakHoldEnabled}
            peakHoldMagnitudes={peakHoldRef.current}
            showVfo={showVfo}
            vfoCenter={vfoCenterBin}
            vfoLeft={vfoLeftBin}
            vfoRight={vfoRightBin}
          />
          <div className="absolute bottom-1 right-2 text-[10px] font-mono text-ocp-dim/60 pointer-events-none">
            {showVfo ? "Click to set VFO" : ""}
          </div>
        </div>
        <div className="h-48 relative rounded border border-ocp-border bg-ocp-panel overflow-hidden">
          <WaterfallCanvas magnitudes={frame?.magnitudes ?? new Float32Array(0)} />
        </div>
      </div>

      <div className="w-full lg:w-72 flex flex-col gap-3 shrink-0 overflow-y-auto">
        <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
          <div className="text-xs uppercase tracking-wider text-ocp-dim">rtl_tcp Source</div>
          <TextField label="Host" value={host} onChange={(value) => {
            setHost(value);
            saveLocalPrefs({ host: value });
          }} />
          <TextField label="Port" value={port} onChange={(value) => {
            setPort(value);
            saveLocalPrefs({ port: value });
          }} />
          <div className="grid grid-cols-2 gap-2">
            <AnalogButton onClick={connect} disabled={service.state.rtlConnected}>Connect</AnalogButton>
            <AnalogButton onClick={disconnect} disabled={!service.state.rtlConnected}>Disconnect</AnalogButton>
          </div>
          <div className="text-[10px] text-ocp-dim">
            Run <code>rtl_tcp -a 0.0.0.0 -p 1234</code> on the host, then connect.
          </div>
        </div>

        <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
          <div className="text-xs uppercase tracking-wider text-ocp-dim">Mock Source</div>
          <div className="text-[10px] text-ocp-dim mb-1">
            For UI testing without an RTL-SDR dongle.
          </div>
          <AnalogButton onClick={connectMock} disabled={service.state.rtlConnected}>Start Mock Signal</AnalogButton>
        </div>

        <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
          <div className="text-xs uppercase tracking-wider text-ocp-dim">Receiver Settings</div>
          <TextField label="Center Freq (MHz)" value={centerFreq} onChange={(value) => {
            setCenterFreq(value);
            saveLocalPrefs({ centerFreq: value });
          }} />
          <div className="grid grid-cols-2 gap-2">
            <AnalogButton onClick={applyFreq} disabled={!service.state.rtlConnected}>Set Freq</AnalogButton>
            <div />
          </div>
          <div className="flex gap-2">
            <select
              className="bg-ocp-bg border border-ocp-border rounded px-2 py-1 text-xs text-ocp-text"
              value={gainMode}
              onChange={(e) => {
                const value = e.target.value as "auto" | "manual";
                setGainMode(value);
                saveLocalPrefs({ gainMode: value });
              }}
              disabled={!service.state.rtlConnected}
            >
              <option value="auto">Auto Gain</option>
              <option value="manual">Manual</option>
            </select>
            <TextField label="Gain dB" value={gainValue} onChange={(value) => {
              setGainValue(value);
              saveLocalPrefs({ gainValue: value });
            }} disabled={gainMode === "auto" || !service.state.rtlConnected} />
          </div>
          <AnalogButton onClick={applyGain} disabled={!service.state.rtlConnected}>Set Gain</AnalogButton>
        </div>

        <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
          <div className="text-xs uppercase tracking-wider text-ocp-dim">Display</div>
          <AnalogToggle label="Peak Hold" checked={peakHoldEnabled} onChange={(value) => {
            setPeakHoldEnabled(value);
            saveLocalPrefs({ peakHoldEnabled: value });
          }} />
          <AnalogToggle label="VFO Band" checked={showVfo} onChange={(value) => {
            setShowVfo(value);
            saveLocalPrefs({ showVfo: value });
          }} />
        </div>

        {showVfo && (
          <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
            <VfoReadout
              vfo={vfo}
              onBandwidthChange={(bw) => {
                setVfo((prev) => ({ ...prev, bandwidth: bw }));
                saveLocalPrefs({ vfoBandwidth: bw });
              }}
            />
          </div>
        )}

        <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
          <div className="text-xs uppercase tracking-wider text-ocp-dim">I/Q Recording</div>
          <div className="text-[10px] text-ocp-dim mb-1">
            Capture raw I/Q data to ~/ocp-recordings/
          </div>
          <AnalogButton
            onClick={toggleRecording}
            variant={isRecording ? "danger" : "default"}
            disabled={!service.state.rtlConnected}
          >
            {isRecording ? "■ Stop Recording" : "● Start Recording"}
          </AnalogButton>
        </div>

        <BookmarksPanel onTune={tuneToBookmark} centerFreq={vfo.centerFreq} />

        {service.rtlError && (
          <div className="p-2 rounded border border-red-900/50 bg-red-900/20 text-xs text-red-300 font-mono">
            {service.rtlError}
          </div>
        )}
      </div>
    </div>
  );
}
