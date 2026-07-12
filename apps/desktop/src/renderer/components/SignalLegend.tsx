export function SignalLegend({
  filters,
  onToggle,
}: {
  filters: Record<string, boolean>;
  onToggle: (key: string) => void;
}) {
  const items = [
    { key: "meshtastic", label: "Meshtastic", color: "#00f0a0" },
    { key: "ruview", label: "RuView Presence", color: "#ff5555" },
    { key: "sdr", label: "RTL-SDR", color: "#00ccff" },
    { key: "baofeng", label: "Baofeng", color: "#ffaa00" },
    { key: "mock", label: "Mock", color: "#888888" },
  ];

  return (
    <div className="flex flex-wrap gap-2 p-3 border-t border-ocp-border bg-ocp-panel">
      {items.map((item) => {
        const active = filters[item.key] !== false;
        return (
          <button
            key={item.key}
            type="button"
            onClick={() => onToggle(item.key)}
            className={[
              "flex items-center gap-2 px-3 py-1.5 rounded border text-[10px] uppercase tracking-wider transition-all",
              active
                ? "border-ocp-border bg-ocp-panel-2 text-ocp-text"
                : "border-ocp-border/50 bg-ocp-panel text-ocp-text-dim opacity-60",
            ].join(" ")}
          >
            <span
              className="w-2 h-2 rounded-full"
              style={{ backgroundColor: item.color, boxShadow: `0 0 6px ${item.color}` }}
            />
            {item.label}
          </button>
        );
      })}
    </div>
  );
}
