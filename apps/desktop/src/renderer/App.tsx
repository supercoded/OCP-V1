import { Routes, Route } from "react-router-dom";
import { useState } from "react";
import { Sidebar } from "./components/Sidebar";
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

export default function App() {
  const [active, setActive] = useState<Workspace>("sonar");
  const service = useOcpService();

  return (
    <div className="flex h-screen w-screen overflow-hidden bg-ocp-bg text-ocp-text">
      <Sidebar active={active} onChange={setActive} />
      <div className="flex flex-1 flex-col min-w-0">
        <header className="h-14 border-b border-ocp-border bg-ocp-panel flex items-center justify-between px-4 shrink-0">
          <h1 className="text-lg font-semibold tracking-widest uppercase text-ocp-accent">
            OCP-V1 Command
          </h1>
          <div className="flex items-center gap-3 text-xs text-ocp-text-dim font-mono">
            <span className="inline-flex items-center gap-1.5">
              <span className="w-2 h-2 rounded-full bg-ocp-accent animate-pulse" />
              Sonar active
            </span>
            <span>| Windows</span>
          </div>
        </header>

        <main className="flex-1 relative min-h-0">
          <Routes>
            <Route path="/" element={<SonarPage />} />
            <Route path="/messaging" element={<MessagingPage />} />
            <Route path="/network" element={<NetworkPage />} />
            <Route path="/devices" element={<DevicesPage />} />
            <Route path="/spectrum" element={<SpectrumPage />} />
            <Route path="/map" element={<MapPage />} />
            <Route path="/settings" element={<SettingsPage />} />
          </Routes>
        </main>

        <footer className="h-8 border-t border-ocp-border bg-ocp-panel flex items-center justify-between px-3 text-[10px] text-ocp-text-dim font-mono uppercase tracking-wide shrink-0">
          <div className="flex items-center gap-4">
            <span className="inline-flex items-center gap-1.5">
              <span
                className={[
                  "w-1.5 h-1.5 rounded-full",
                  service.state.connected ? "bg-ocp-accent animate-pulse" : "bg-ocp-amber",
                ].join(" ")}
              />
              {service.state.connected ? `Meshtastic ${service.state.transportKind}` : "Meshtastic standby"}
            </span>
            <span className="inline-flex items-center gap-1.5">
              <span
                className={[
                  "w-1.5 h-1.5 rounded-full",
                  service.state.ruViewConnected ? "bg-ocp-red animate-pulse" : "bg-ocp-text-dim",
                ].join(" ")}
              />
              RuView {service.state.ruViewConnected ? "connected" : "standby"}
            </span>
          </div>
          <div>Nodes: {service.state.nodeCount} · RuView targets: {service.ruViewSensing.length}</div>
        </footer>
      </div>
    </div>
  );
}
