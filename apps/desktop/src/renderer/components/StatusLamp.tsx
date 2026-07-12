export function StatusLamp({
  state,
  label,
}: {
  state: "off" | "on" | "active" | "error";
  label: string;
}) {
  const color =
    state === "active"
      ? "bg-ocp-accent shadow-[0_0_8px_rgba(0,240,160,0.8)] animate-pulse"
      : state === "on"
        ? "bg-ocp-accent shadow-[0_0_6px_rgba(0,240,160,0.5)]"
        : state === "error"
          ? "bg-ocp-red shadow-[0_0_8px_rgba(255,51,51,0.8)]"
          : "bg-ocp-text-dim";

  return (
    <span className="inline-flex items-center gap-2 text-[10px] uppercase tracking-wider text-ocp-text-dim">
      <span className={["w-2 h-2 rounded-full", color].join(" ")} />
      {label}
    </span>
  );
}
