export function SignalLegend({
  filters,
  onToggle,
}: {
  filters: Record<string, boolean>;
  onToggle: (key: string) => void;
}) {
  const items = [
    { key: "meshtastic", label: "Meshtastic", color: "#4caf50", available: true },
    { key: "ruview", label: "RuView Presence", color: "#c62828", available: true },
    { key: "mock", label: "Mock", color: "#888888", available: true },
    { key: "sdr", label: "RTL-SDR (not mapped yet)", color: "#4fc3f7", available: false },
    { key: "baofeng", label: "Baofeng (not mapped yet)", color: "#d4a017", available: false },
  ];

  return (
    <div className="flex flex-wrap gap-2 p-3 border-t border-ocp-border bg-ocp-panel">
      {items.map((item) => {
        const active = filters[item.key] !== false;
        return (
          <button
            key={item.key}
            type="button"
            disabled={!item.available}
            onClick={() => onToggle(item.key)}
            title={item.available ? undefined : "This source is not producing sonar blips yet"}
            className={[
              "flex items-center gap-2 px-3 py-1.5 rounded border text-[10px] uppercase tracking-wider transition-all",
              !item.available
                ? "border-ocp-border/40 bg-ocp-panel text-ocp-dim opacity-50 cursor-not-allowed"
                : active
                ? "border-ocp-border bg-ocp-panel-2 text-ocp-text"
                : "border-ocp-border/50 bg-ocp-panel text-ocp-dim opacity-60",
            ].join(" ")}
          >
            <span
              className="w-2 h-2 rounded-full"
              style={{ backgroundColor: item.color }}
            />
            {item.label}
          </button>
        );
      })}
    </div>
  );
}