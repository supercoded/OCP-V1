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
    <div className="flex h-screen w-screen overflow-hidden bg-ocp-bg text-ocp-text font-mono">
      <Sidebar active={active} onChange={setActive} />
      <div className="flex flex-1 flex-col min-w-0">
        {/* Top bar — INDI-style flat gray */}
        <header className="h-[32px] border-b border-ocp-border bg-ocp-panel flex items-center justify-between px-3 shrink-0">
          <div className="flex items-center gap-3">
            <span className="text-[11px] font-bold text-ocp-bright tracking-[1px] uppercase">
              {active === "sonar" && "SONAR PPI"}
              {active === "messaging" && "MESSAGING"}
              {active === "network" && "NETWORK"}
              {active === "devices" && "DEVICES"}
              {active === "spectrum" && "SPECTRUM"}
              {active === "map" && "MAP"}
              {active === "settings" && "SETTINGS"}
            </span>
            <span className="flex items-center gap-[5px] text-[10px] text-ocp-dim">
              <span className="w-[6px] h-[6px] rounded-full bg-ocp-green" />
              {service.state.connected
                ? `Meshtastic ${service.state.transportKind}`
                : "Meshtastic standby"}
            </span>
          </div>
          <div className="text-[10px] text-ocp-muted flex items-center gap-[10px]">
            {service.state.connected && (
              <>
                <span>Nodes <span className="text-ocp-bright">{service.state.nodeCount}</span></span>
                <span>·</span>
              </>
            )}
            <span>RuView {service.state.ruViewConnected ? "connected" : "standby"}</span>
          </div>
        </header>

        {/* Main content */}
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

        {/* Bottom status bar */}
        <footer className="h-[28px] border-t border-ocp-border bg-ocp-panel flex items-center justify-between px-3 text-[10px] text-ocp-muted font-mono tracking-wide shrink-0">
          <div className="flex items-center gap-4">
            <span>OCP-V1 v0.6.0 · {active.toUpperCase()}</span>
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