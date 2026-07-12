import {
  Radar,
  MessageSquare,
  Network,
  Cpu,
  Activity,
  Map,
  Settings,
} from "lucide-react";
import type { Workspace } from "../App";
import { Link } from "react-router-dom";

const items: { id: Workspace; label: string; icon: React.ElementType; path: string }[] = [
  { id: "sonar", label: "Sonar", icon: Radar, path: "/" },
  { id: "messaging", label: "Messaging", icon: MessageSquare, path: "/messaging" },
  { id: "network", label: "Network", icon: Network, path: "/network" },
  { id: "devices", label: "Devices", icon: Cpu, path: "/devices" },
  { id: "spectrum", label: "Spectrum", icon: Activity, path: "/spectrum" },
  { id: "map", label: "Map", icon: Map, path: "/map" },
  { id: "settings", label: "Settings", icon: Settings, path: "/settings" },
];

export function Sidebar({
  active,
  onChange,
}: {
  active: Workspace;
  onChange: (w: Workspace) => void;
}) {
  return (
    <nav className="w-16 flex flex-col border-r border-ocp-border bg-ocp-panel">
      <div className="h-14 flex items-center justify-center border-b border-ocp-border">
        <div className="w-8 h-8 rounded-full border-2 border-ocp-accent flex items-center justify-center">
          <span className="text-xs font-bold text-ocp-accent">O</span>
        </div>
      </div>

      <div className="flex-1 flex flex-col items-center gap-2 py-3">
        {items.map((item) => {
          const isActive = active === item.id;
          return (
            <Link
              key={item.id}
              to={item.path}
              onClick={() => onChange(item.id)}
              className={[
                "group relative w-12 h-12 rounded-lg flex flex-col items-center justify-center gap-1 transition-all",
                "hover:bg-ocp-panel-2",
                isActive
                  ? "bg-ocp-panel-2 text-ocp-accent shadow-[inset_0_0_12px_rgba(0,240,160,0.15)]"
                  : "text-ocp-text-dim",
              ].join(" ")}
            >
              <item.icon className="w-5 h-5" />
              <span className="text-[8px] uppercase tracking-wider font-medium">{item.label}</span>
              {isActive && (
                <span className="absolute left-0 top-1/2 -translate-y-1/2 w-0.5 h-6 bg-ocp-accent rounded-r" />
              )}
            </Link>
          );
        })}
      </div>
    </nav>
  );
}
