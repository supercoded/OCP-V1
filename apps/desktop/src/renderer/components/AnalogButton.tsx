import { type ReactNode } from "react";

export function AnalogButton({
  children,
  onClick,
  variant = "default",
  disabled = false,
}: {
  children: ReactNode;
  onClick?: () => void;
  variant?: "default" | "accent" | "danger";
  disabled?: boolean;
}) {
  const color =
    variant === "accent"
      ? "border-ocp-bright text-ocp-bright hover:bg-ocp-green/10 "
      : variant === "danger"
        ? "border-ocp-red text-ocp-red hover:bg-ocp-red/10 shadow-[0_0_12px_rgba(255,51,51,0.12)]"
        : "border-ocp-border text-ocp-text hover:border-ocp-text-dim";

  return (
    <button
      type="button"
      disabled={disabled}
      onClick={onClick}
      className={[
        "px-4 py-2 rounded-md border text-xs uppercase tracking-wider font-semibold transition-all",
        "disabled:opacity-40 disabled:cursor-not-allowed",
        color,
      ].join(" ")}
    >
      {children}
    </button>
  );
}
