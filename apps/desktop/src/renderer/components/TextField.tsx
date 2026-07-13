export function TextField({
  label,
  value,
  onChange,
  placeholder,
  type = "text",
  disabled = false,
}: {
  label: string;
  value: string;
  onChange: (v: string) => void;
  placeholder?: string;
  type?: string;
  disabled?: boolean;
}) {
  return (
    <div className="flex flex-col gap-1">
      <label className="text-[10px] uppercase tracking-wider text-ocp-dim">{label}</label>
      <input
        type={type}
        value={value}
        placeholder={placeholder}
        disabled={disabled}
        onChange={(e) => onChange(e.target.value)}
        className="px-3 py-2 rounded-md border border-ocp-border bg-ocp-panel text-ocp-text text-xs placeholder:text-ocp-dim/50 focus:outline-none focus:border-ocp-bright transition-colors disabled:opacity-50 disabled:cursor-not-allowed"
      />
    </div>
  );
}
