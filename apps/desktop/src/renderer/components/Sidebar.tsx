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

const items: { id: Workspace; label: string; icon: React.ElementType }[] = [
  { id: "sonar", label: "Sonar", icon: Radar },
  { id: "messaging", label: "Msg", icon: MessageSquare },
  { id: "network", label: "Net", icon: Network },
  { id: "devices", label: "Devices", icon: Cpu },
  { id: "spectrum", label: "Spectrum", icon: Activity },
  { id: "map", label: "Map", icon: Map },
  { id: "settings", label: "Settings", icon: Settings },
];

export function Sidebar({
  active,
  onChange,
}: {
  active: Workspace;
  onChange: (w: Workspace) => void;
}) {
  return (
    <nav className="w-[60px] flex flex-col border-r border-ocp-border bg-ocp-panel">
      <div className="h-[28px] flex items-center justify-center border-b border-ocp-border">
        <div className="w-[36px] h-[22px] rounded border border-ocp-border-2 bg-ocp-panel-2 flex items-center justify-center">
          <span className="text-[9px] font-bold text-ocp-bright tracking-widest">OCP</span>
        </div>
      </div>

      <div className="flex-1 flex flex-col items-center gap-[2px] py-3">
        {items.map((item) => {
          const isActive = active === item.id;
          return (
            <button
              key={item.id}
              type="button"
              onClick={() => onChange(item.id)}
              className={[
                "w-[40px] h-[40px] rounded flex flex-col items-center justify-center transition-all",
                "hover:bg-ocp-panel-2",
                isActive
                  ? "bg-ocp-panel-3 text-ocp-bright border border-ocp-border-2"
                  : "text-ocp-muted border border-transparent",
              ].join(" ")}
            >
              <item.icon className="w-[20px] h-[20px]" />
              <span className="text-[8px] uppercase tracking-wider font-medium mt-[1px]">{item.label}</span>
            </button>
          );
        })}
      </div>

      <div className="pb-3 flex flex-col items-center">
        <div className="w-[8px] h-[8px] rounded-full bg-ocp-green" />
      </div>
    </nav>
  );
}
