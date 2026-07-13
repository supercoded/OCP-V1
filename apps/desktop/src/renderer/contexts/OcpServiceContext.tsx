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
  mapPort?: number;
  baofengConnected: boolean;
  baofengPortName?: string;
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
  mapPort?: number;
  // Map server
  startMap: (filePath: string) => Promise<{ ok: boolean; port?: number; error?: string }>;
  stopMap: () => Promise<{ ok: boolean }>;
  // File dialog
  openFileDialog: (opts?: { title?: string; filters?: { name: string; extensions: string[] }[]; properties?: string[] }) =>
    Promise<{ ok: boolean; canceled?: boolean; filePath?: string; error?: string }>;
  // Messaging API
  messages: any[];
  sendMessage: (params: { text: string; channel?: number; destinationNodeId?: number }) => Promise<{ ok: boolean; error?: string }>;
  getMessageHistory: () => Promise<{ ok: boolean; history?: any[] }>;
  sendError?: string;

  // Baofeng IPC
  baofengConnect: (portName: string) => Promise<{ ok: boolean; error?: string }>;
  baofengDisconnect: () => Promise<{ ok: boolean }>;
  baofengReadChannels: () => Promise<{ ok: boolean; channels?: any[]; error?: string }>;
  baofengWriteChannels: (channels: any[]) => Promise<{ ok: boolean; error?: string }>;
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
  const [mapPort, setMapPort] = useState<number | undefined>(undefined);

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

  const startMap = useCallback(async (filePath: string) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    const result = await api.startMap(filePath);
    if (result.ok && result.port) setMapPort(result.port);
    return result;
  }, []);

  const stopMap = useCallback(async () => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    const result = await api.stopMap();
    if (result.ok) setMapPort(undefined);
    return result;
  }, []);

  const openFileDialog = useCallback(async (opts?: { title?: string; filters?: { name: string; extensions: string[] }[]; properties?: string[] }) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    return await api.openFileDialog(opts ?? {});
  }, []);

  // --- Messaging state ---
  const [messages, setMessages] = useState<any[]>([]);
  const [sendError, setSendError] = useState<string | undefined>(undefined);

  // Subscribe to incoming messages on mount
  useEffect(() => {
    const api = (window as any).ocp;
    if (!api) return;

    // Load existing history
    api.getMessageHistory().then((res: any) => {
      if (res?.ok && res.history) setMessages(res.history);
    });

    // Subscribe to incoming messages
    const unsubMessages = api.onMessageReceived((msg: any) => {
      setMessages((prev) => [...prev, msg]);
    });

    return () => {
      unsubMessages?.();
    };
  }, []);

  const sendMessage = useCallback(async (params: { text: string; channel?: number; destinationNodeId?: number }) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    setSendError(undefined);
    const result = await api.sendMessage(params);
    if (!result.ok) {
      setSendError(result.error);
    } else {
      // Optimistically add the sent message to the local list
      setMessages((prev) => [
        ...prev,
        {
          id: Date.now() & 0xffff,
          text: params.text,
          from: "you",
          to: params.destinationNodeId ?? 0,
          channel: params.channel ?? 0,
          timestamp: Date.now(),
          outgoing: true,
        },
      ]);
    }
    return result;
  }, []);

  const getMessageHistory = useCallback(async () => {
    const api = (window as any).ocp;
    if (!api) return { ok: false };
    const result = await api.getMessageHistory();
    if (result?.ok && result.history) setMessages(result.history);
    return result;
  }, []);

  // --- Baofeng IPC ---
  const baofengConnect = useCallback(async (portName: string) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    return await api.baofengConnect(portName);
  }, []);

  const baofengDisconnect = useCallback(async () => {
    const api = (window as any).ocp;
    if (!api) return { ok: false };
    return await api.baofengDisconnect();
  }, []);

  const baofengReadChannels = useCallback(async () => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    return await api.baofengReadChannels();
  }, []);

  const baofengWriteChannels = useCallback(async (channels: any[]) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    return await api.baofengWriteChannels(channels);
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
      mapPort,
      // Map functions
      startMap,
      stopMap,
      // File dialog
      openFileDialog,
      // Messaging
      messages,
      sendMessage,
      getMessageHistory,
      sendError,
      // Baofeng
      baofengConnect,
      baofengDisconnect,
      baofengReadChannels,
      baofengWriteChannels,
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
