import { useState } from "react";
import { useOcpService } from "../contexts/OcpServiceContext";

const DEPS = [
  {
    name: "esptool.py",
    purpose: "Flash Meshtastic firmware to ESP32 boards",
    install: "pip install esptool",
  },
  {
    name: "nrfutil",
    purpose: "Flash Meshtastic firmware to nRF52 / RAK4631 boards",
    install: "pip install nrfutil",
  },
  {
    name: "rtl_tcp / RTL-SDR drivers",
    purpose: "Stream SDR spectrum data to OCP-V1",
    install: "https://rtl-sdr.com/",
  },
  {
    name: "RuView Docker simulator",
    purpose: "Through-wall presence/vitals sensing via Wi-Fi CSI",
    install: "bash scripts/run-ruview-simulator.sh (Docker required)",
  },
];

export function SettingsPage() {
  const service = useOcpService();
  const plugins = service.state.plugins ?? [];
  const security = service.state.security ?? { pinConfigured: false, unlocked: true };

  const [pin, setPin] = useState("");
  const [pinConfirm, setPinConfirm] = useState("");
  const [currentPin, setCurrentPin] = useState("");
  const [newPin, setNewPin] = useState("");
  const [secMsg, setSecMsg] = useState<string | null>(null);
  const [secErr, setSecErr] = useState<string | null>(null);

  const flash = (ok: boolean, msg: string) => {
    setSecErr(ok ? null : msg);
    setSecMsg(ok ? msg : null);
  };

  const onSetPin = async () => {
    if (pin.length < 4) return flash(false, "PIN must be at least 4 characters");
    if (pin !== pinConfirm) return flash(false, "PIN confirmation does not match");
    const res = await service.setPin(pin);
    if (!res.ok) return flash(false, res.error || "Failed to set PIN");
    setPin("");
    setPinConfirm("");
    flash(true, "PIN set — offline store encrypted");
  };

  const onChangePin = async () => {
    if (newPin.length < 4) return flash(false, "New PIN must be at least 4 characters");
    const res = await service.changePin({ currentPin, newPin });
    if (!res.ok) return flash(false, res.error || "Failed to change PIN");
    setCurrentPin("");
    setNewPin("");
    flash(true, "PIN changed");
  };

  const onClearPin = async () => {
    const res = await service.clearPin(currentPin || pin);
    if (!res.ok) return flash(false, res.error || "Failed to clear PIN");
    setCurrentPin("");
    setPin("");
    flash(true, "PIN removed");
  };

  return (
    <div className="absolute inset-0 p-6 overflow-auto">
      <h2 className="text-lg font-semibold tracking-widest uppercase text-ocp-bright  mb-4">
        Settings
      </h2>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
        <div className="p-4 rounded-lg border border-ocp-border bg-ocp-panel">
          <div className="text-xs uppercase tracking-wider text-ocp-dim mb-3">Security (PIN)</div>
          <div className="space-y-2 text-xs font-mono text-ocp-text mb-4">
            <div className="flex justify-between">
              <span>PIN configured</span>
              <span className={security.pinConfigured ? "text-ocp-green" : "text-ocp-dim"}>
                {security.pinConfigured ? "YES" : "NO"}
              </span>
            </div>
            <div className="flex justify-between">
              <span>Session</span>
              <span className={security.unlocked ? "text-ocp-green" : "text-ocp-amber"}>
                {security.unlocked ? "UNLOCKED" : "LOCKED"}
              </span>
            </div>
          </div>

          {!security.pinConfigured ? (
            <div className="space-y-2">
              <input
                type="password"
                value={pin}
                onChange={(e) => setPin(e.target.value)}
                placeholder="New PIN (min 4)"
                className="w-full bg-ocp-bg border border-ocp-border px-2 py-1.5 text-xs outline-none focus:border-ocp-cyan"
              />
              <input
                type="password"
                value={pinConfirm}
                onChange={(e) => setPinConfirm(e.target.value)}
                placeholder="Confirm PIN"
                className="w-full bg-ocp-bg border border-ocp-border px-2 py-1.5 text-xs outline-none focus:border-ocp-cyan"
              />
              <button
                type="button"
                onClick={() => void onSetPin()}
                className="px-2 py-1.5 text-[10px] uppercase tracking-wider border border-ocp-green text-ocp-green"
              >
                Enable PIN lock
              </button>
            </div>
          ) : (
            <div className="space-y-2">
              <div className="flex flex-wrap gap-2">
                <button
                  type="button"
                  onClick={() => void service.lock()}
                  className="px-2 py-1.5 text-[10px] uppercase tracking-wider border border-ocp-amber text-ocp-amber"
                >
                  Lock now
                </button>
              </div>
              <input
                type="password"
                value={currentPin}
                onChange={(e) => setCurrentPin(e.target.value)}
                placeholder="Current PIN"
                className="w-full bg-ocp-bg border border-ocp-border px-2 py-1.5 text-xs outline-none focus:border-ocp-cyan"
              />
              <input
                type="password"
                value={newPin}
                onChange={(e) => setNewPin(e.target.value)}
                placeholder="New PIN (optional)"
                className="w-full bg-ocp-bg border border-ocp-border px-2 py-1.5 text-xs outline-none focus:border-ocp-cyan"
              />
              <div className="flex flex-wrap gap-2">
                <button
                  type="button"
                  onClick={() => void onChangePin()}
                  className="px-2 py-1.5 text-[10px] uppercase tracking-wider border border-ocp-cyan text-ocp-cyan"
                >
                  Change PIN
                </button>
                <button
                  type="button"
                  onClick={() => void onClearPin()}
                  className="px-2 py-1.5 text-[10px] uppercase tracking-wider border border-ocp-red text-ocp-red"
                >
                  Remove PIN
                </button>
              </div>
            </div>
          )}

          {secMsg ? <div className="mt-3 text-[10px] text-ocp-green font-mono">{secMsg}</div> : null}
          {secErr ? <div className="mt-3 text-[10px] text-ocp-red font-mono">{secErr}</div> : null}
          <div className="mt-3 text-[10px] text-ocp-dim leading-relaxed">
            PIN derives an AES-256-GCM key (scrypt) for the offline DB. Mesh inbound
            packets use a sliding-window replay filter. CRC-32 helpers are available for
            OCP payloads — Meshtastic TCP/serial streams use official 0x94C3 framing
            (no app-level CRC on the wire).
          </div>
        </div>

        <div className="p-4 rounded-lg border border-ocp-border bg-ocp-panel">
          <div className="text-xs uppercase tracking-wider text-ocp-dim mb-3">Connection Status</div>
          <div className="space-y-2 text-xs font-mono text-ocp-text">
            <div className="flex justify-between">
              <span>Meshtastic connected</span>
              <span className={service.state.connected ? "text-ocp-bright" : "text-ocp-dim"}>
                {service.state.connected ? "YES" : "NO"}
              </span>
            </div>
            <div className="flex justify-between">
              <span>Transport kind</span>
              <span className="text-ocp-dim">{service.state.transportKind || "—"}</span>
            </div>
            <div className="flex justify-between">
              <span>Mesh nodes</span>
              <span className="text-ocp-dim">{service.state.nodeCount}</span>
            </div>
            <div className="flex justify-between">
              <span>RuView connected</span>
              <span className={service.state.ruViewConnected ? "text-ocp-bright" : "text-ocp-dim"}>
                {service.state.ruViewConnected ? "YES" : "NO"}
              </span>
            </div>
            <div className="flex justify-between">
              <span>RuView targets</span>
              <span className="text-ocp-dim">{service.ruViewSensing.length}</span>
            </div>
          </div>
        </div>

        <div className="p-4 rounded-lg border border-ocp-border bg-ocp-panel">
          <div className="text-xs uppercase tracking-wider text-ocp-dim mb-3">External Tools</div>
          <div className="space-y-3">
            {DEPS.map((d) => (
              <div key={d.name} className="flex flex-col gap-1">
                <div className="flex items-center justify-between">
                  <span className="text-xs font-medium text-ocp-text">{d.name}</span>
                  <span className="text-[10px] text-ocp-dim">{d.purpose}</span>
                </div>
                <code className="text-[10px] font-mono text-ocp-bright bg-ocp-bg px-2 py-1 rounded border border-ocp-border">
                  {d.install}
                </code>
              </div>
            ))}
          </div>
          <div className="mt-4 text-[10px] text-ocp-dim leading-relaxed">
            OCP-V1 does not bundle these tools because their licenses and architectures vary.
            The installer will prompt you to install missing tools on first run in a future update.
          </div>
        </div>

        <div className="p-4 rounded-lg border border-ocp-border bg-ocp-panel lg:col-span-2">
          <div className="flex items-center justify-between mb-3">
            <div className="text-xs uppercase tracking-wider text-ocp-dim">Plugins</div>
            <span className="text-[10px] font-mono text-ocp-muted">{plugins.length} installed</span>
          </div>

          {plugins.length === 0 ? (
            <div className="text-xs text-ocp-dim">No plugins loaded.</div>
          ) : (
            <div className="space-y-3">
              {plugins.map((p) => {
                const statusEntry = service.pluginStatuses.find((s) => s.pluginId === p.id);
                const status = statusEntry?.status;
                return (
                  <div
                    key={p.id}
                    className="flex flex-col gap-2 border border-ocp-border rounded p-3 bg-ocp-bg"
                  >
                    <div className="flex items-start justify-between gap-3">
                      <div>
                        <div className="text-sm text-ocp-bright font-medium">{p.name}</div>
                        <div className="text-[10px] font-mono text-ocp-dim">
                          {p.id} · v{p.version}
                        </div>
                        {p.description ? (
                          <div className="text-[10px] text-ocp-muted mt-1">{p.description}</div>
                        ) : null}
                      </div>
                      <button
                        type="button"
                        onClick={() =>
                          p.active
                            ? void service.deactivatePlugin(p.id)
                            : void service.activatePlugin(p.id)
                        }
                        className={[
                          "px-2 py-1 text-[10px] uppercase tracking-wider border rounded",
                          p.active
                            ? "border-ocp-amber text-ocp-amber"
                            : "border-ocp-green text-ocp-green",
                        ].join(" ")}
                      >
                        {p.active ? "Deactivate" : "Activate"}
                      </button>
                    </div>
                    <div className="flex flex-wrap gap-2 text-[10px] font-mono">
                      <span className={p.active ? "text-ocp-green" : "text-ocp-dim"}>
                        {p.active ? "ACTIVE" : "INACTIVE"}
                      </span>
                      {p.permissions.map((perm) => (
                        <span key={perm} className="text-ocp-cyan border border-ocp-border px-1 rounded">
                          {perm}
                        </span>
                      ))}
                      {(p.capabilities.length ? p.capabilities : p.declaredCapabilities ?? []).map(
                        (cap) => (
                          <span
                            key={cap}
                            className="text-ocp-dim border border-ocp-border px-1 rounded"
                          >
                            {cap}
                          </span>
                        )
                      )}
                    </div>
                    {status ? (
                      <div className="text-[10px] font-mono text-ocp-text grid grid-cols-2 sm:grid-cols-4 gap-2 pt-1 border-t border-ocp-border">
                        <span>healthy: {String(status.healthy)}</span>
                        <span>mesh: {status.meshConnected ? "yes" : "no"}</span>
                        <span>nodes: {status.nodeCount ?? "—"}</span>
                        <span>rtl: {status.rtlConnected ? "yes" : "no"}</span>
                      </div>
                    ) : null}
                  </div>
                );
              })}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
