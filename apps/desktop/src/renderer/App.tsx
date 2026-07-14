import { useCallback, useEffect, useRef, useState, Component, type ReactNode, type ErrorInfo } from "react";
import { Sidebar } from "./components/Sidebar";
import { LockScreen } from "./components/LockScreen";
import { SonarPage } from "./pages/SonarPage";
import { MessagingPage } from "./pages/MessagingPage";
import { DevicesPage } from "./pages/DevicesPage";
import { NetworkPage } from "./pages/NetworkPage";
import { SpectrumPage } from "./pages/SpectrumPage";
import { MapPage } from "./pages/MapPage";
import { SettingsPage } from "./pages/SettingsPage";
import { useOcpService } from "./contexts/OcpServiceContext";

export type Workspace =
  | "sonar"
  | "messaging"
  | "network"
  | "devices"
  | "spectrum"
  | "map"
  | "settings";

const WORKSPACES: Array<{ id: Workspace; label: string; page: ReactNode }> = [
  { id: "sonar", label: "SONAR PPI", page: <SonarPage /> },
  { id: "messaging", label: "MESSAGING", page: <MessagingPage /> },
  { id: "network", label: "NETWORK", page: <NetworkPage /> },
  { id: "devices", label: "DEVICES", page: <DevicesPage /> },
  { id: "spectrum", label: "SPECTRUM", page: <SpectrumPage /> },
  { id: "map", label: "MAP", page: <MapPage /> },
  { id: "settings", label: "SETTINGS", page: <SettingsPage /> },
];

function isWorkspace(value: unknown): value is Workspace {
  return WORKSPACES.some((workspace) => workspace.id === value);
}

class PageErrorBoundary extends Component<
  { children: ReactNode; label: string },
  { error: Error | null }
> {
  state: { error: Error | null } = { error: null };

  static getDerivedStateFromError(error: Error) {
    return { error };
  }

  componentDidCatch(error: Error, info: ErrorInfo) {
    console.error(`[OCP] ${this.props.label} crashed:`, error, info);
  }

  render() {
    if (this.state.error) {
      return (
        <div className="absolute inset-0 flex flex-col items-center justify-center gap-3 p-6 text-center">
          <div className="text-ocp-amber text-xs uppercase tracking-widest font-semibold">
            {this.props.label} failed to render
          </div>
          <pre className="max-w-xl text-[11px] text-ocp-dim whitespace-pre-wrap font-mono">
            {this.state.error.message}
          </pre>
          <button
            type="button"
            className="px-3 py-1.5 text-[11px] border border-ocp-border bg-ocp-panel-2 text-ocp-bright hover:bg-ocp-panel-3"
            onClick={() => this.setState({ error: null })}
          >
            Retry
          </button>
        </div>
      );
    }
    return this.props.children;
  }
}

export default function App() {
  const service = useOcpService();
  const [active, setActive] = useState<Workspace>(() =>
    isWorkspace(service.preferences.lastWorkspace) ? service.preferences.lastWorkspace : "sonar"
  );
  const [hydratedWorkspace, setHydratedWorkspace] = useState(false);
  const userChangedWorkspaceRef = useRef(false);
  const locked =
    !!service.state.security?.pinConfigured && !service.state.security?.unlocked;
  const activeLabel = WORKSPACES.find((workspace) => workspace.id === active)?.label ?? "SONAR PPI";

  useEffect(() => {
    if (hydratedWorkspace) return;
    if (userChangedWorkspaceRef.current) {
      setHydratedWorkspace(true);
      return;
    }
    if (isWorkspace(service.preferences.lastWorkspace)) {
      setActive(service.preferences.lastWorkspace);
    }
    if (service.preferences.lastWorkspace !== undefined) {
      setHydratedWorkspace(true);
    }
  }, [hydratedWorkspace, service.preferences.lastWorkspace]);

  const handleWorkspaceChange = useCallback((workspace: Workspace) => {
    userChangedWorkspaceRef.current = true;
    setActive(workspace);
    void service.updatePreferences({ lastWorkspace: workspace });
  }, [service]);

  useEffect(() => {
    const api = (window as any).ocp;
    if (!api?.resizeOnlineSession) return;
    if (locked || active !== "spectrum") {
      window.dispatchEvent(new Event("ocp:online-sdr:hide-bounds"));
      void api.resizeOnlineSession({ x: 0, y: 0, width: 0, height: 0 });
      return;
    }
    const timer = setTimeout(() => {
      window.dispatchEvent(new Event("ocp:online-sdr:restore-bounds"));
    }, 50);
    return () => clearTimeout(timer);
  }, [active, locked]);

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-ocp-bg text-ocp-text font-mono relative">
      {locked ? <LockScreen /> : null}
      <Sidebar active={active} onChange={handleWorkspaceChange} />
      <div className="flex flex-1 flex-col min-w-0">
        <header className="h-[32px] border-b border-ocp-border bg-ocp-panel flex items-center justify-between px-3 shrink-0">
          <div className="flex items-center gap-3">
            <span className="text-[11px] font-bold text-ocp-bright tracking-[1px] uppercase">
              {activeLabel}
            </span>
            <span className="flex items-center gap-[5px] text-[10px] text-ocp-dim">
              <span className="w-[6px] h-[6px] rounded-full bg-ocp-green" />
              {service.state.connected
                ? `Meshtastic ${service.state.transportKind}`
                : "Meshtastic standby"}
            </span>
          </div>
          <div className="text-[10px] text-ocp-muted flex items-center gap-[10px]">
            {service.state.security?.pinConfigured ? (
              <>
                <span className={service.state.security.unlocked ? "text-ocp-green" : "text-ocp-amber"}>
                  {service.state.security.unlocked ? "UNLOCKED" : "LOCKED"}
                </span>
                <span>·</span>
              </>
            ) : null}
            {service.state.connected && (
              <>
                <span>Nodes <span className="text-ocp-bright">{service.state.nodeCount}</span></span>
                <span>·</span>
              </>
            )}
            <span>RuView {service.state.ruViewConnected ? "connected" : "standby"}</span>
          </div>
        </header>

        <main className="flex-1 relative min-h-0 bg-ocp-bg">
          {WORKSPACES.map((workspace) => {
            const isActive = active === workspace.id;
            return (
              <section
                key={workspace.id}
                aria-hidden={!isActive}
                className={[
                  "absolute inset-0 min-h-0",
                  isActive ? "block" : "hidden pointer-events-none",
                ].join(" ")}
              >
                <PageErrorBoundary label={workspace.label}>
                  {workspace.page}
                </PageErrorBoundary>
              </section>
            );
          })}
        </main>

        <footer className="h-[28px] border-t border-ocp-border bg-ocp-panel flex items-center justify-between px-3 text-[10px] text-ocp-muted font-mono tracking-wide shrink-0">
          <div className="flex items-center gap-4">
            <span>OCP-V1 v0.8.0 · {active.toUpperCase()}</span>
          </div>
          <div className="flex items-center gap-[14px]">
            {service.state.connected && (
              <>
                <span>Nodes <span className="text-ocp-bright">{service.state.nodeCount}</span></span>
                <span>·</span>
              </>
            )}
            <span>
              <span className={[
                "w-[6px] h-[6px] rounded-full inline-block mr-1",
                service.state.connected ? "bg-ocp-green" : "bg-ocp-amber",
              ].join(" ")} />
              {service.state.connected ? "CONNECTED" : "STANDBY"}
            </span>
          </div>
        </footer>
      </div>
    </div>
  );
}
