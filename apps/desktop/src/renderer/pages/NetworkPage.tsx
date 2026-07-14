import { useMemo, useState } from "react";
import { StatusLamp } from "../components/StatusLamp";
import { useOcpService } from "../contexts/OcpServiceContext";

function formatHeard(ts: number): string {
  if (!ts) return "—";
  const ageSec = Math.max(0, Math.round((Date.now() - ts) / 1000));
  if (ageSec < 60) return `${ageSec}s ago`;
  if (ageSec < 3600) return `${Math.floor(ageSec / 60)}m ago`;
  return new Date(ts).toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
}

function formatCoord(n?: number): string {
  if (typeof n !== "number" || !Number.isFinite(n)) return "—";
  return n.toFixed(5);
}

function nodeHex(id: number): string {
  return `!${(id >>> 0).toString(16)}`;
}

export function NetworkPage() {
  const service = useOcpService();
  const { state } = service;
  const networkPrefs = service.preferences.pages.network ?? {};
  const [selectedId, setSelectedId] = useState<number | null>(
    typeof networkPrefs.selectedId === "number" ? networkPrefs.selectedId : null
  );

  const nodes = useMemo(
    () => [...state.nodes].sort((a, b) => (b.lastHeard ?? 0) - (a.lastHeard ?? 0)),
    [state.nodes]
  );

  const selected = nodes.find((n) => n.id === selectedId);

  return (
    <div className="absolute inset-0 flex flex-col p-6 gap-4 overflow-hidden">
      <div className="flex items-center justify-between shrink-0">
        <h2 className="text-lg font-semibold tracking-widest uppercase text-ocp-bright">
          Network
        </h2>
        <div className="flex items-center gap-4 text-xs font-mono">
          <StatusLamp
            state={state.connected ? "on" : "off"}
            label={
              state.connected
                ? `Connected · ${state.transportKind ?? "mesh"}${
                    state.transportEndpoint ? ` · ${state.transportEndpoint}` : ""
                  }`
                : "Disconnected"
            }
          />
          <span className="text-ocp-dim">{state.nodeCount} nodes</span>
          <span className="text-ocp-muted">routes: not available yet</span>
        </div>
      </div>

      <div className="flex-1 min-h-0 flex gap-4">
        <div className="flex-1 min-w-0 rounded border border-ocp-border bg-ocp-panel overflow-hidden flex flex-col">
          {nodes.length === 0 ? (
            <div className="flex-1 flex items-center justify-center text-center px-6">
              <div>
                <div className="text-ocp-bright text-sm mb-2 uppercase tracking-widest">
                  No nodes
                </div>
                <div className="text-xs text-ocp-dim max-w-sm">
                  {state.connected
                    ? "Waiting for mesh node announcements…"
                    : "Connect a Meshtastic device in Devices to view the node list."}
                </div>
              </div>
            </div>
          ) : (
            <div className="overflow-auto flex-1">
              <table className="w-full text-left text-xs font-mono">
                <thead className="sticky top-0 bg-ocp-panel-2 text-ocp-dim uppercase tracking-wider border-b border-ocp-border">
                  <tr>
                    <th className="px-3 py-2 font-medium">ID</th>
                    <th className="px-3 py-2 font-medium">Name</th>
                    <th className="px-3 py-2 font-medium">Role</th>
                    <th className="px-3 py-2 font-medium">SNR</th>
                    <th className="px-3 py-2 font-medium">RSSI</th>
                    <th className="px-3 py-2 font-medium">Last heard</th>
                    <th className="px-3 py-2 font-medium">Lat</th>
                    <th className="px-3 py-2 font-medium">Lon</th>
                  </tr>
                </thead>
                <tbody>
                  {nodes.map((n) => {
                    const isLocal = state.localNodeId != null && n.id === state.localNodeId;
                    const isSelected = selectedId === n.id;
                    return (
                      <tr
                        key={n.id}
                        onClick={() => {
                          setSelectedId(n.id);
                          void service.updatePagePreferences("network", { selectedId: n.id });
                        }}
                        className={[
                          "border-b border-ocp-border/60 cursor-pointer transition-colors",
                          isSelected
                            ? "bg-ocp-panel-2 text-ocp-bright"
                            : "text-ocp-text hover:bg-ocp-panel-2/60",
                        ].join(" ")}
                      >
                        <td className="px-3 py-2 whitespace-nowrap">
                          {nodeHex(n.id)}
                          {isLocal ? (
                            <span className="ml-2 text-[10px] text-ocp-green uppercase">self</span>
                          ) : null}
                        </td>
                        <td className="px-3 py-2 truncate max-w-[10rem]">
                          {n.name || n.shortName || "—"}
                        </td>
                        <td className="px-3 py-2 text-ocp-dim">{n.role ?? "—"}</td>
                        <td className="px-3 py-2">
                          {n.avgSnr != null ? n.avgSnr.toFixed(1) : "—"}
                        </td>
                        <td className="px-3 py-2">
                          {n.avgRssi != null ? Math.round(n.avgRssi) : "—"}
                        </td>
                        <td className="px-3 py-2 text-ocp-dim">{formatHeard(n.lastHeard)}</td>
                        <td className="px-3 py-2">{formatCoord(n.lat)}</td>
                        <td className="px-3 py-2">{formatCoord(n.lon)}</td>
                      </tr>
                    );
                  })}
                </tbody>
              </table>
            </div>
          )}
        </div>

        <div className="w-64 shrink-0 rounded border border-ocp-border bg-ocp-panel p-4 flex flex-col gap-3">
          <div className="text-[10px] uppercase tracking-widest text-ocp-dim">Selection</div>
          {selected ? (
            <div className="space-y-2 text-xs font-mono text-ocp-text">
              <div className="text-ocp-bright text-sm">{selected.name || nodeHex(selected.id)}</div>
              <div className="flex justify-between gap-2">
                <span className="text-ocp-dim">Node</span>
                <span>{nodeHex(selected.id)}</span>
              </div>
              <div className="flex justify-between gap-2">
                <span className="text-ocp-dim">Short</span>
                <span>{selected.shortName || "—"}</span>
              </div>
              <div className="flex justify-between gap-2">
                <span className="text-ocp-dim">SNR / RSSI</span>
                <span>
                  {selected.avgSnr != null ? selected.avgSnr.toFixed(1) : "—"} /{" "}
                  {selected.avgRssi != null ? Math.round(selected.avgRssi) : "—"}
                </span>
              </div>
              <div className="flex justify-between gap-2">
                <span className="text-ocp-dim">Position</span>
                <span>
                  {formatCoord(selected.lat)}, {formatCoord(selected.lon)}
                </span>
              </div>
              <div className="flex justify-between gap-2">
                <span className="text-ocp-dim">Heard</span>
                <span>{formatHeard(selected.lastHeard)}</span>
              </div>
            </div>
          ) : (
            <div className="text-xs text-ocp-dim">Select a node to inspect details.</div>
          )}
        </div>
      </div>
    </div>
  );
}
