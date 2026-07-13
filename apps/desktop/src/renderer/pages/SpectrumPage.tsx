import { useState, useEffect, useCallback, useRef } from "react";
import { useOcpService, type SpectrumFrame } from "../contexts/OcpServiceContext";
import { SpectrumCanvas } from "../components/SpectrumCanvas";
import { WaterfallCanvas } from "../components/WaterfallCanvas";
import { AnalogButton } from "../components/AnalogButton";
import { AnalogToggle } from "../components/AnalogToggle";
import { TextField } from "../components/TextField";
import { StatusLamp } from "../components/StatusLamp";
import { BookmarksPanel } from "../components/BookmarksPanel";
import { VfoIndicator, VfoReadout, type VfoState } from "../components/VfoIndicator";

function formatFreq(hz?: number) {
  if (hz === undefined) return "";
  return (hz / 1e6).toFixed(3);
}

function formatDuration(ms: number) {
  const s = Math.floor(ms / 1000);
  const m = Math.floor(s / 60);
  const sec = s % 60;
  return `${m.toString().padStart(2, "0")}:${sec.toString().padStart(2, "0")}`;
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

  // Peak hold
  const [peakHoldEnabled, setPeakHoldEnabled] = useState(false);
  const peakHoldRef = useRef<Float32Array | null>(null);
  const peakDecayRate = 0.002; // dB per frame

  // VFO state
  const [vfo, setVfo] = useState<VfoState>({ centerFreq: 100000000, bandwidth: 15000 });
  const [showVfo, setShowVfo] = useState(true);

  // Recording state
  const [isRecording, setIsRecording] = useState(false);
  const [recordingStart, setRecordingStart] = useState<number | null>(null);
  const [recordingDuration, setRecordingDuration] = useState(0);
  const recordingTimerRef = useRef<ReturnType<typeof setInterval> | null>(null);

  // Peak hold processing
  const processedPeakHold = useRef<Float32Array | null>(null);

  useEffect(() => {
    const unsub = (window as any).ocp?.onRtlSpectrum((f: SpectrumFrame) => {
      lastFrameRef.current = f;

      // Update peak hold
      if (peakHoldEnabled && f.magnitudes.length > 0) {
        if (!peakHoldRef.current || peakHoldRef.current.length !== f.magnitudes.length) {
          peakHoldRef.current = new Float32Array(f.magnitudes);
        } else {
          const peak = peakHoldRef.current;
          for (let i = 0; i < peak.length; i++) {
            if (f.magnitudes[i] > peak[i]) {
              peak[i] = f.magnitudes[i];
            } else {
              // Slow decay
              peak[i] -= peakDecayRate;
            }
          }
        }
      }

      // Update VFO center frequency to match spectrum if it hasn't been changed
      if (!vfoLockedRef.current) {
        setVfo((prev) => ({ ...prev, centerFreq: f.centerFreq }));
      }

      setFrame(f);
    });
    return () => unsub?.();
  }, [peakHoldEnabled]);

  // Reset peak hold when disabled
  useEffect(() => {
    if (!peakHoldEnabled) {
      peakHoldRef.current = null;
    }
  }, [peakHoldEnabled]);

  // VFO auto-lock: once user clicks spectrum, lock VFO center to their selection
  const vfoLockedRef = useRef(false);

  // Recording timer
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

  // Listen for recording events
  useEffect(() => {
    const api = (window as any).ocp;
    if (!api) return;
    const unsubStarted = api.onRtlRecordingStarted?.((info: any) => {
      setIsRecording(true);
      setRecordingStart(Date.now());
      setRecordingDuration(0);
    });
    const unsubStopped = api.onRtlRecordingStopped?.((info: any) => {
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

  const tuneToBookmark = useCallback(async (freqHz: number) => {
    setCenterFreq((freqHz / 1e6).toFixed(3));
    setVfo((prev) => ({ ...prev, centerFreq: freqHz }));
    vfoLockedRef.current = true;
    if (service.state.rtlConnected) {
      await service.setRtlFreq(freqHz);
    }
  }, [service]);

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

  // Handle click on spectrum canvas to set VFO center
  const handleSpectrumClick = useCallback((e: React.MouseEvent<HTMLDivElement>) => {
    if (!frame || !showVfo) return;
    const rect = e.currentTarget.getBoundingClientRect();
    const x = e.clientX - rect.left;
    const fraction = x / rect.width;
    // Map fraction to frequency
    const startFreq = frame.centerFreq - frame.sampleRate / 2;
    const clickFreq = startFreq + fraction * frame.sampleRate;
    setVfo((prev) => ({ ...prev, centerFreq: clickFreq }));
    vfoLockedRef.current = true;
  }, [frame, showVfo]);

  // Compute VFO bin indices for rendering on SpectrumCanvas
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
    <div className="absolute inset-0 p-4 flex flex-col gap-3">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold tracking-widest uppercase text-ocp-accent text-glow">
          Spectrum
        </h2>
        <div className="flex items-center gap-3">
          {isRecording && (
            <div className="flex items-center gap-2">
              <span className="w-2.5 h-2.5 rounded-full bg-red-500 animate-pulse" />
              <span className="text-xs font-mono text-red-400">
                REC {formatDuration(recordingDuration)}
              </span>
            </div>
          )}
          <StatusLamp active={service.state.rtlConnected} label={service.state.rtlConnected ? "LIVE" : "OFFLINE"} />
          <div className="text-xs font-mono text-ocp-text-dim">
            {frame ? `${(frame.centerFreq / 1e6).toFixed(3)} MHz · ${(frame.sampleRate / 1e6).toFixed(3)} MSPS · ${frame.fftSize} bins` : "No source"}
          </div>
        </div>
      </div>

      <div className="flex flex-col lg:flex-row gap-3 flex-1 min-h-0">
        {/* Spectrum + waterfall */}
        <div className="flex-1 flex flex-col gap-2 min-h-0">
          <div
            className="flex-1 relative rounded border border-ocp-border bg-ocp-panel overflow-hidden"
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
            <div className="absolute bottom-1 right-2 text-[10px] font-mono text-ocp-text-dim/60 pointer-events-none">
              {showVfo ? "Click to set VFO" : ""}
            </div>
          </div>
          <div className="h-48 relative rounded border border-ocp-border bg-ocp-panel overflow-hidden">
            <WaterfallCanvas magnitudes={frame?.magnitudes ?? new Float32Array(0)} />
          </div>
        </div>

        {/* Controls */}
        <div className="w-full lg:w-72 flex flex-col gap-3 shrink-0 overflow-y-auto">
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

          {/* Display controls */}
          <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
            <div className="text-xs uppercase tracking-wider text-ocp-text-dim">Display</div>
            <AnalogToggle label="Peak Hold" checked={peakHoldEnabled} onChange={setPeakHoldEnabled} />
            <AnalogToggle label="VFO Band" checked={showVfo} onChange={setShowVfo} />
          </div>

          {/* VFO Readout */}
          {showVfo && (
            <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
              <VfoReadout
                vfo={vfo}
                onBandwidthChange={(bw) => setVfo((prev) => ({ ...prev, bandwidth: bw }))}
              />
            </div>
          )}

          {/* Recording */}
          <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
            <div className="text-xs uppercase tracking-wider text-ocp-text-dim">I/Q Recording</div>
            <div className="text-[10px] text-ocp-text-dim mb-1">
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

          {/* Bookmarks */}
          <BookmarksPanel onTune={tuneToBookmark} centerFreq={vfo.centerFreq} />

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