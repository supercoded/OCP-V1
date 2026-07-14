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
  transportEndpoint?: string;
  localNodeId?: number;
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
  serialPorts?: Array<{
    path: string;
    manufacturer?: string;
    vendorId?: string;
    productId?: string;
    friendlyName?: string;
  }>;
  plugins?: Array<{
    id: string;
    name: string;
    version: string;
    description?: string;
    active: boolean;
    permissions: string[];
    capabilities: string[];
    declaredCapabilities?: string[];
  }>;
  security?: {
    pinConfigured: boolean;
    unlocked: boolean;
  };
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

export interface OnlineReceiver {
  id: string;
  name: string;
  url: string;
  mobileUrl?: string;
  type: "websdr" | "kiwisdr" | "openwebrx" | "directory";
  location?: string;
  region?: string;
  bands: string[];
  capabilities: string[];
  notes?: string;
  embeddable?: boolean;
  favorite?: boolean;
  status?: string;
}

export interface SessionBounds {
  x: number;
  y: number;
  width: number;
  height: number;
}

export type WorkspaceId =
  | "sonar"
  | "messaging"
  | "network"
  | "devices"
  | "spectrum"
  | "map"
  | "settings";

export interface AppPreferences {
  lastWorkspace?: WorkspaceId;
  pages: Partial<Record<WorkspaceId, Record<string, any>>>;
}

const DEFAULT_PREFERENCES: AppPreferences = {
  pages: {},
};

interface OcpServiceAPI {
  state: OcpState;
  preferences: AppPreferences;
  updatePreferences: (patch: Partial<AppPreferences>) => Promise<{ ok: boolean; preferences?: AppPreferences; error?: string }>;
  updatePagePreferences: (page: WorkspaceId, patch: Record<string, any>) => Promise<{ ok: boolean; preferences?: AppPreferences; error?: string }>;
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
  // RTL-SDR Recording
  startRtlRecording: (filename?: string) => Promise<{ ok: boolean; path?: string; error?: string }>;
  stopRtlRecording: () => Promise<{ ok: boolean; path?: string; bytesWritten?: number; duration?: number; error?: string }>;
  getRtlRecordingStatus: () => Promise<{ recording: boolean; path?: string | null; startTime?: number | null; bytesWritten?: number }>;
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
  baofengConnect: (portName: string) => Promise<{ ok: boolean; error?: string; portName?: string }>;
  baofengDisconnect: () => Promise<{ ok: boolean }>;
  baofengReadChannels: () => Promise<{ ok: boolean; channels?: any[]; error?: string }>;
  baofengWriteChannels: (channels: any[]) => Promise<{ ok: boolean; error?: string }>;
  baofengListPorts: () => Promise<{
    ok: boolean;
    ports?: any[];
    best?: any;
    error?: string;
  }>;

  // Plugins
  activatePlugin: (id: string) => Promise<{ ok: boolean; error?: string }>;
  deactivatePlugin: (id: string) => Promise<{ ok: boolean; error?: string }>;
  getPluginStatus: () => Promise<{ ok: boolean; statuses?: any[]; error?: string }>;
  pluginStatuses: any[];

  // Security
  setPin: (pin: string) => Promise<{ ok: boolean; error?: string }>;
  unlock: (pin: string) => Promise<{ ok: boolean; error?: string }>;
  lock: () => Promise<{ ok: boolean; error?: string }>;
  changePin: (params: { currentPin: string; newPin: string }) => Promise<{ ok: boolean; error?: string }>;
  clearPin: (pin: string) => Promise<{ ok: boolean; error?: string }>;

  // Online SDR receivers
  listOnlineReceivers: () => Promise<{ ok: boolean; receivers?: OnlineReceiver[]; lastReceiverId?: string; error?: string }>;
  probeOnlineReceivers: () => Promise<{ ok: boolean; receivers?: OnlineReceiver[]; error?: string }>;
  toggleOnlineFavorite: (id: string) => Promise<{ ok: boolean; favoriteIds?: string[]; receivers?: OnlineReceiver[]; error?: string }>;
  openOnlineExternal: (url: string) => Promise<{ ok: boolean; error?: string }>;
  openOnlineSession: (params: { receiverId: string; mobile?: boolean; bounds: SessionBounds }) =>
    Promise<{ ok: boolean; external?: boolean; url?: string; receiverId?: string; name?: string; error?: string }>;
  resizeOnlineSession: (bounds: SessionBounds) => Promise<{ ok: boolean; error?: string }>;
  closeOnlineSession: () => Promise<{ ok: boolean; error?: string }>;
}

const OcpServiceContext = createContext<OcpServiceAPI | null>(null);

export function OcpServiceProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<OcpState>({
    connected: false,
    nodeCount: 0,
    nodes: [],
    ruViewConnected: false,
    rtlConnected: false,
    baofengConnected: false,
  });
  const [sensing, setSensing] = useState<RuViewSensing[]>([]);
  const [ruViewError, setRuViewError] = useState<string | undefined>(undefined);
  const [rtlSpectrum, setRtlSpectrum] = useState<SpectrumFrame[]>([]);
  const [rtlError, setRtlError] = useState<string | undefined>(undefined);
  const [mapPort, setMapPort] = useState<number | undefined>(undefined);
  const [preferences, setPreferences] = useState<AppPreferences>(DEFAULT_PREFERENCES);

  useEffect(() => {
    const api = (window as any).ocp;
    if (!api) return;

    api.getPreferences?.().then((res: any) => {
      if (res?.ok && res.preferences) {
        setPreferences({ ...DEFAULT_PREFERENCES, ...res.preferences, pages: res.preferences.pages ?? {} });
      }
    });
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

  const updatePreferences = useCallback(async (patch: Partial<AppPreferences>) => {
    const api = (window as any).ocp;
    if (!api?.updatePreferences) return { ok: false, error: "OCP API not available" };
    const result = await api.updatePreferences(patch);
    if (result?.ok && result.preferences) {
      setPreferences({ ...DEFAULT_PREFERENCES, ...result.preferences, pages: result.preferences.pages ?? {} });
    }
    return result;
  }, []);

  const updatePagePreferences = useCallback(async (page: WorkspaceId, patch: Record<string, any>) => {
    const api = (window as any).ocp;
    if (!api?.updatePagePreferences) return { ok: false, error: "OCP API not available" };
    const result = await api.updatePagePreferences(page, patch);
    if (result?.ok && result.preferences) {
      setPreferences({ ...DEFAULT_PREFERENCES, ...result.preferences, pages: result.preferences.pages ?? {} });
    }
    return result;
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

  const startRtlRecording = useCallback(async (filename?: string) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    return await api.startRtlRecording(filename);
  }, []);

  const stopRtlRecording = useCallback(async () => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    return await api.stopRtlRecording();
  }, []);

  const getRtlRecordingStatus = useCallback(async () => {
    const api = (window as any).ocp;
    if (!api) return { recording: false };
    return await api.getRtlRecordingStatus();
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

  const baofengListPorts = useCallback(async () => {
    const api = (window as any).ocp;
    if (!api?.baofengListPorts) return { ok: false, error: "OCP API not available", ports: [] };
    return await api.baofengListPorts();
  }, []);

  const [pluginStatuses, setPluginStatuses] = useState<any[]>([]);

  const refreshPluginStatus = useCallback(async () => {
    const api = (window as any).ocp;
    if (!api?.getPluginStatus) return { ok: false };
    const result = await api.getPluginStatus();
    if (result?.ok && result.statuses) setPluginStatuses(result.statuses);
    return result;
  }, []);

  const activatePlugin = useCallback(async (id: string) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    const result = await api.activatePlugin(id);
    if (result.ok) await refreshPluginStatus();
    return result;
  }, [refreshPluginStatus]);

  const deactivatePlugin = useCallback(async (id: string) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    const result = await api.deactivatePlugin(id);
    if (result.ok) await refreshPluginStatus();
    return result;
  }, [refreshPluginStatus]);

  useEffect(() => {
    void refreshPluginStatus();
  }, [refreshPluginStatus, state.plugins]);

  const setPin = useCallback(async (pin: string) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    return await api.setPin(pin);
  }, []);

  const unlock = useCallback(async (pin: string) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    return await api.unlock(pin);
  }, []);

  const lock = useCallback(async () => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    return await api.lock();
  }, []);

  const changePin = useCallback(async (params: { currentPin: string; newPin: string }) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    return await api.changePin(params);
  }, []);

  const clearPin = useCallback(async (pin: string) => {
    const api = (window as any).ocp;
    if (!api) return { ok: false, error: "OCP API not available" };
    return await api.clearPin(pin);
  }, []);

  const listOnlineReceivers = useCallback(async () => {
    const api = (window as any).ocp;
    if (!api?.listOnlineReceivers) return { ok: false, error: "OCP API not available", receivers: [] };
    return await api.listOnlineReceivers();
  }, []);

  const probeOnlineReceivers = useCallback(async () => {
    const api = (window as any).ocp;
    if (!api?.probeOnlineReceivers) return { ok: false, error: "OCP API not available" };
    return await api.probeOnlineReceivers();
  }, []);

  const toggleOnlineFavorite = useCallback(async (id: string) => {
    const api = (window as any).ocp;
    if (!api?.toggleOnlineFavorite) return { ok: false, error: "OCP API not available" };
    return await api.toggleOnlineFavorite(id);
  }, []);

  const openOnlineExternal = useCallback(async (url: string) => {
    const api = (window as any).ocp;
    if (!api?.openOnlineExternal) return { ok: false, error: "OCP API not available" };
    return await api.openOnlineExternal(url);
  }, []);

  const openOnlineSession = useCallback(async (params: { receiverId: string; mobile?: boolean; bounds: SessionBounds }) => {
    const api = (window as any).ocp;
    if (!api?.openOnlineSession) return { ok: false, error: "OCP API not available" };
    return await api.openOnlineSession(params);
  }, []);

  const resizeOnlineSession = useCallback(async (bounds: SessionBounds) => {
    const api = (window as any).ocp;
    if (!api?.resizeOnlineSession) return { ok: false, error: "OCP API not available" };
    return await api.resizeOnlineSession(bounds);
  }, []);

  const closeOnlineSession = useCallback(async () => {
    const api = (window as any).ocp;
    if (!api?.closeOnlineSession) return { ok: false, error: "OCP API not available" };
    return await api.closeOnlineSession();
  }, []);

  return (
    <OcpServiceContext.Provider
      value={{
        state,
        preferences,
        updatePreferences,
        updatePagePreferences,
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
      startRtlRecording,
      stopRtlRecording,
      getRtlRecordingStatus,
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
      baofengListPorts,
      // Plugins
      activatePlugin,
      deactivatePlugin,
      getPluginStatus: refreshPluginStatus,
      pluginStatuses,
      // Security
      setPin,
      unlock,
      lock,
      changePin,
      clearPin,
      listOnlineReceivers,
      probeOnlineReceivers,
      toggleOnlineFavorite,
      openOnlineExternal,
      openOnlineSession,
      resizeOnlineSession,
      closeOnlineSession,
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
