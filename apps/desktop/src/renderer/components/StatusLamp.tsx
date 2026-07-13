export function StatusLamp({
  state,
  label,
}: {
  state: "off" | "on" | "active" | "error";
  label: string;
}) {
  const color =
    state === "active"
      ? "bg-ocp-green"
      : state === "on"
        ? "bg-ocp-green"
        : state === "error"
          ? "bg-ocp-red"
          : "bg-ocp-muted";

  return (
    <span className="inline-flex items-center gap-2 text-[10px] uppercase tracking-wider text-ocp-dim">
      <span className={["w-2 h-2 rounded-full", color].join(" ")} />
      {label}
    </span>
  );
}