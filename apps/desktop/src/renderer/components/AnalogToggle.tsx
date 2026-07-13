export function AnalogToggle({
  label,
  checked,
  onChange,
}: {
  label: string;
  checked: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <button
      type="button"
      onClick={() => onChange(!checked)}
      className={[
        "flex items-center gap-3 px-3 py-2 rounded-md border transition-all",
        checked
          ? "border-ocp-bright bg-ocp-panel-2 text-ocp-bright "
          : "border-ocp-border bg-ocp-panel text-ocp-dim hover:border-ocp-text-dim",
      ].join(" ")}
    >
      <span
        className={[
          "w-8 h-4 rounded-full relative transition-colors",
          checked ? "bg-ocp-green" : "bg-ocp-border",
        ].join(" ")}
      >
        <span
          className={[
            "absolute top-0.5 left-0.5 w-3 h-3 rounded-full bg-white transition-transform",
            checked ? "translate-x-4" : "",
          ].join(" ")}
        />
      </span>
      <span className="text-xs uppercase tracking-wider font-medium">{label}</span>
    </button>
  );
}
