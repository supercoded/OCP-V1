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

interface OcpServiceAPI {
  state: OcpState;
  connect: (options: any) => Promise<{ ok: boolean; error?: string }>;
  disconnect: () => Promise<void>;
  startRuView: (cfg?: { host?: string; wsPort?: number }) => Promise<void>;
  stopRuView: () => Promise<void>;
  ruViewSensing: RuViewSensing[];
  ruViewError?: string;
}

const OcpServiceContext = createContext<OcpServiceAPI | null>(null);

export function OcpServiceProvider({ children }: { children: ReactNode }) {
  const [state, setState] = useState<OcpState>({
    connected: false,
    nodeCount: 0,
    nodes: [],
    ruViewConnected: false,
  });
  const [sensing, setSensing] = useState<RuViewSensing[]>([]);
  const [error, setError] = useState<string | undefined>(undefined);

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
      setError(undefined);
    });
    const unsubError = api.onRuViewError((msg: string) => setError(msg));

    return () => {
      unsubState?.();
      unsubSensing?.();
      unsubError?.();
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
    setError(undefined);
  }, []);

  return (
    <OcpServiceContext.Provider
      value={{ state, connect, disconnect, startRuView, stopRuView, ruViewSensing: sensing, ruViewError: error }}
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
