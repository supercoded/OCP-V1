import {
  createContext,
  useContext,
  useEffect,
  useState,
  useCallback,
  type ReactNode,
} from "react";

export interface OcpState {
  connected: boolean;
  transportKind?: string;
  nodeCount: number;
  nodes: any[];
  ruViewConnected: boolean;
  rtlConnected: boolean;
  rtlCenterFreq?: number;
  rtlSampleRate?: number;
  rtlHost?: string;
  rtlPort?: number;
}

export interface RuViewSensing {
  nodeId: number;
  x: number;
  y: number;
  z: number;
  rssi: number | null;
  timestamp: number;
  source: string;
}

export interface SpectrumFrame {
  centerFreq: number;
  sampleRate: number;
  fftSize: number;
  frequencies: Float32Array;
  magnitudes: Float32Array;
}

interface OcpServiceAPI {
  state: OcpState;
  connect: (options: any) => Promise<{ ok: boolean; error?: string }>;
  disconnect: () => Promise<void>;
  startRuView: (cfg?: { host?: string; wsPort?: number }) => Promise<void>;
  stopRuView: () => Promise<void>;
  ruViewSensing: RuViewSensing[];
  ruViewError?: string;

  connectRtl: (cfg?: { host?: string; port?: number; centerFreq?: number; sampleRate?: number }) => Promise<{ ok: boolean; error?: string }>;
  disconnectRtl: () => Promise<void>;
  setRtlFreq: (hz: number) => Promise<{ ok: boolean; error?: string }>;
  setRtlGain: (gain: { mode?: "auto" | "manual"; value?: number }) => Promise<{ ok: boolean; error?: string }>;
  startRtlMock: (cfg?: { centerFreq?: number; sampleRate?: number; carriers?: { freqOffset: number; amplitude: number }[] }) => Promise<{ ok: boolean; error?: string }>;
  rtlSpectrum: SpectrumFrame[];
  rtlError?: string;
}

const OcpServiceContext = createContext<OcpServiceAPI | null>(null);

export function OcpServiceProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<OcpState>({
    connected: false,
    nodeCount: 0,
    nodes: [],
    ruViewConnected: false,
    rtlConnected: false,
  });
  const [sensing, setSensing] = useState<RuViewSensing[]>([]);
  const [ruViewError, setRuViewError] = useState<string | undefined>(undefined);
  const [rtlSpectrum, setRtlSpectrum] = useState<SpectrumFrame[]>([]);
  const [rtlError, setRtlError] = useState<string | undefined>(undefined);

  useEffect(() => {
    const api = (window as any).ocp;
    if (!api) return;

    api.getState().then((s: OcpState) => setState(s));
    const unsubState = api.onState(setState);
    const unsubSensing = api.onRuViewSensing((s: RuViewSensing) => {
      setSensing((prev) => {
        const filtered = prev.filter((x) => x.nodeId !== s.nodeId);
        return [...filtered, s].slice(-50);
      });
      setRuViewError(undefined);
    });
    const unsubRuViewError = api.onRuViewError((msg: string) => setRuViewError(msg));

    const unsubRtlSpectrum = api.onRtlSpectrum((frame: SpectrumFrame) => {
      setRtlSpectrum((prev) => [...prev.slice(-199), frame]);
      setRtlError(undefined);
    });
    const unsubRtlError = api.onRtlError((msg: string) => setRtlError(msg));

    return () => {
      unsubState?.();
      unsubSensing?.();
      unsubRuViewError?.();
      unsubRtlSpectrum?.();
      unsubRtlError?.();
    };
  }, []);

  const connect = useCallback(async (options: any) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    return await api.connect(options);
  }, []);

  const disconnect = useCallback(async () => {
    await (window as any).ocp?.disconnect();
  }, []);

  const startRuView = useCallback(async (cfg?: { host?: string; wsPort?: number }) => {
    await (window as any).ocp?.startRuView(cfg ?? {});
  }, []);

  const stopRuView = useCallback(async () => {
    await (window as any).ocp?.stopRuView();
    setSensing([]);
    setRuViewError(undefined);
  }, []);

  const connectRtl = useCallback(async (cfg?: { host?: string; port?: number; centerFreq?: number; sampleRate?: number }) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    const result = await api.connectRtl(cfg ?? {});
    if (!result.ok) setRtlError(result.error);
    return result;
  }, []);

  const disconnectRtl = useCallback(async () => {
    await (window as any).ocp?.disconnectRtl();
    setRtlSpectrum([]);
    setRtlError(undefined);
  }, []);

  const setRtlFreq = useCallback(async (hz: number) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    return await api.setRtlFreq(hz);
  }, []);

  const setRtlGain = useCallback(async (gain: { mode?: "auto" | "manual"; value?: number }) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    return await api.setRtlGain(gain);
  }, []);

  const startRtlMock = useCallback(async (cfg?: { centerFreq?: number; sampleRate?: number; carriers?: { freqOffset: number; amplitude: number }[] }) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    const result = await api.startRtlMock(cfg ?? {});
    if (!result.ok) setRtlError(result.error);
    return result;
  }, []);

  return (
    <OcpServiceContext.Provider
      value={{
        state,
        connect,
        disconnect,
        startRuView,
        stopRuView,
        ruViewSensing: sensing,
        ruViewError,
        connectRtl,
        disconnectRtl,
        setRtlFreq,
        setRtlGain,
        startRtlMock,
        rtlSpectrum,
        rtlError,
      }}
    >
      {children}
    </OcpServiceContext.Provider>
  );
}

export function useOcpService() {
  const ctx = useContext(OcpServiceContext);
  if (!ctx) throw new Error("useOcpService must be used within OcpServiceProvider");
  return ctx;
}
