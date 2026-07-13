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

  return (
    <div className="absolute inset-0 p-6 overflow-auto">
      <h2 className="text-lg font-semibold tracking-widest uppercase text-ocp-bright  mb-4">
        Settings
      </h2>

      <div className="grid grid-cols-1 lg:grid-cols-2 gap-4">
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
      </div>
    </div>
  );
}
