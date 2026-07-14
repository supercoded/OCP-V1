import { useState } from "react";
import { useOcpService } from "../contexts/OcpServiceContext";

export function LockScreen() {
  const service = useOcpService();
  const [pin, setPin] = useState("");
  const [error, setError] = useState<string | null>(null);
  const [busy, setBusy] = useState(false);

  const onUnlock = async () => {
    setBusy(true);
    setError(null);
    const res = await service.unlock(pin);
    if (!res.ok) setError(res.error || "Unlock failed");
    else setPin("");
    setBusy(false);
  };

  return (
    <div className="absolute inset-0 z-50 flex items-center justify-center bg-ocp-bg/95 backdrop-blur-sm">
      <div className="w-full max-w-sm border border-ocp-border bg-ocp-panel p-6 rounded flex flex-col gap-4">
        <div>
          <div className="text-xs uppercase tracking-widest text-ocp-dim mb-1">Security</div>
          <h2 className="text-lg text-ocp-bright tracking-wide uppercase">PIN Required</h2>
          <p className="text-[11px] text-ocp-dim mt-2">
            Enter your PIN to unlock the encrypted offline store and operator console.
          </p>
        </div>
        <input
          type="password"
          inputMode="numeric"
          autoComplete="off"
          value={pin}
          onChange={(e) => setPin(e.target.value)}
          onKeyDown={(e) => {
            if (e.key === "Enter") void onUnlock();
          }}
          placeholder="PIN"
          className="w-full bg-ocp-bg border border-ocp-border px-3 py-2 text-sm text-ocp-bright font-mono outline-none focus:border-ocp-cyan"
        />
        {error ? <div className="text-[11px] text-ocp-red font-mono">{error}</div> : null}
        <button
          type="button"
          disabled={busy || pin.length < 4}
          onClick={() => void onUnlock()}
          className="px-3 py-2 text-[11px] uppercase tracking-wider border border-ocp-green text-ocp-green disabled:opacity-40 hover:bg-ocp-panel-2"
        >
          {busy ? "Unlocking…" : "Unlock"}
        </button>
      </div>
    </div>
  );
}
