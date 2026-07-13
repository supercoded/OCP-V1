import { useState } from "react";
import { AnalogButton } from "../components/AnalogButton";
import { AnalogToggle } from "../components/AnalogToggle";
import { StatusLamp } from "../components/StatusLamp";
import { TextField } from "../components/TextField";
import { BaofengChannelEditor } from "../components/BaofengChannelEditor";
import { useOcpService } from "../contexts/OcpServiceContext";

export function DevicesPage() {
  const service = useOcpService();
  const [tab, setTab] = useState<"connections" | "ruview" | "firmware" | "baofeng">("connections");

  // Connection form state
  const [auto, setAuto] = useState(true);
  const [tcpHost, setTcpHost] = useState("10.0.0.100");
  const [tcpPort, setTcpPort] = useState("4403");
  const [serialPort, setSerialPort] = useState("/dev/ttyUSB0");
  const [bleId, setBleId] = useState("");
  const [connecting, setConnecting] = useState(false);
  const [lastError, setLastError] = useState<string | null>(null);

  // RuView form state
  const [ruviewHost, setRuviewHost] = useState("localhost");
  const [ruviewPort, setRuviewPort] = useState("3001");

  const onConnect = async () => {
    setConnecting(true);
    setLastError(null);
    let options: any = {};
    if (auto) {
      options = { tcp: { host: tcpHost, port: Number(tcpPort) }, serial: { portName: serialPort }, ble: {} };
    } else {
      if (tcpHost) options.tcp = { host: tcpHost, port: Number(tcpPort) };
      if (serialPort) options.serial = { portName: serialPort };
      if (bleId) options.ble = { deviceId: bleId };
    }
    const res = await service.connect(options);
    if (!res.ok) setLastError(res.error || "Connection failed");
    setConnecting(false);
  };

  const onDisconnect = async () => {
    setLastError(null);
    await service.disconnect();
  };

  const onStartRuView = async () => {
    setLastError(null);
    await service.startRuView({ host: ruviewHost, wsPort: Number(ruviewPort) });
  };

  const onStopRuView = async () => {
    await service.stopRuView();
  };

  return (
    <div className="absolute inset-0 flex flex-col p-6 gap-4 overflow-auto">
      <div className="flex items-center justify-between">
        <h2 className="text-lg font-semibold tracking-widest uppercase text-ocp-accent text-glow">
          Devices
        </h2>
        <div className="flex gap-2">
          {(["connections", "ruview", "firmware", "baofeng"] as const).map((t) => (
            <button
              key={t}
              type="button"
              onClick={() => setTab(t)}
              className={[
                "px-3 py-1.5 rounded border text-[10px] uppercase tracking-wider transition-all",
                tab === t
                  ? "border-ocp-accent text-ocp-accent bg-ocp-panel-2"
                  : "border-ocp-border text-ocp-text-dim hover:border-ocp-text-dim",
              ].join(" ")}
            >
              {t}
            </button>
          ))}
        </div>
      </div>

      {lastError && (
        <div className="px-4 py-2 rounded border border-ocp-red bg-ocp-red/10 text-xs text-ocp-red font-mono">
          {lastError}
        </div>
      )}

      {tab === "connections" && (
        <div className="flex flex-col gap-4 max-w-2xl">
          <div className="p-4 rounded-lg border border-ocp-border bg-ocp-panel flex flex-col gap-4">
            <div className="flex items-center justify-between">
              <span className="text-xs uppercase tracking-wider text-ocp-text-dim">Meshtastic Connection</span>
              <StatusLamp
                state={service.state.connected ? "active" : "off"}
                label={service.state.connected ? `Connected · ${service.state.transportKind}` : "Disconnected"}
              />
            </div>

            <AnalogToggle label="Auto-detect transport" checked={auto} onChange={setAuto} />

            <div className="grid grid-cols-2 gap-4">
              <TextField label="TCP Host" value={tcpHost} onChange={setTcpHost} placeholder="10.0.0.100" />
              <TextField label="TCP Port" value={tcpPort} onChange={setTcpPort} placeholder="4403" />
            </div>
            <div className="grid grid-cols-2 gap-4">
              <TextField label="Serial Port" value={serialPort} onChange={setSerialPort} placeholder="/dev/ttyUSB0" />
              <TextField label="BLE Device ID" value={bleId} onChange={setBleId} placeholder="aa:bb:cc:dd:ee:ff" />
            </div>

            <div className="flex gap-3">
              <AnalogButton variant="accent" onClick={onConnect} disabled={connecting || service.state.connected}>
                {connecting ? "Connecting…" : "Connect"}
              </AnalogButton>
              <AnalogButton onClick={onDisconnect} disabled={!service.state.connected}>
                Disconnect
              </AnalogButton>
            </div>
          </div>

          <div className="p-4 rounded-lg border border-ocp-border bg-ocp-panel text-xs text-ocp-text-dim font-mono">
            <div className="uppercase tracking-wider mb-2 text-ocp-accent">Status</div>
            <div>Transport: {service.state.transportKind || "—"}</div>
            <div>Connected: {service.state.connected ? "yes" : "no"}</div>
            <div>Mesh nodes: {service.state.nodeCount}</div>
          </div>
        </div>
      )}

      {tab === "ruview" && (
        <div className="flex flex-col gap-4 max-w-2xl">
          <div className="p-4 rounded-lg border border-ocp-border bg-ocp-panel flex flex-col gap-4">
            <div className="flex items-center justify-between">
              <span className="text-xs uppercase tracking-wider text-ocp-text-dim">RuView Presence Sensor</span>
              <StatusLamp
                state={service.state.ruViewConnected ? "active" : "off"}
                label={service.state.ruViewConnected ? "Streaming" : "Standby"}
              />
            </div>

            <div className="grid grid-cols-2 gap-4">
              <TextField label="Host" value={ruviewHost} onChange={setRuviewHost} placeholder="localhost" />
              <TextField label="WebSocket Port" value={ruviewPort} onChange={setRuviewPort} placeholder="3001" />
            </div>

            <div className="text-[10px] text-ocp-text-dim leading-relaxed">
              Requires the RuView sensing server. Run the Docker simulator with{" "}
              <code className="text-ocp-accent">bash scripts/run-ruview-simulator.sh</code>.
            </div>

            <div className="flex gap-3">
              <AnalogButton variant="accent" onClick={onStartRuView} disabled={service.state.ruViewConnected}>
                Start RuView
              </AnalogButton>
              <AnalogButton onClick={onStopRuView} disabled={!service.state.ruViewConnected}>
                Stop RuView
              </AnalogButton>
            </div>
          </div>

          <div className="p-4 rounded-lg border border-ocp-border bg-ocp-panel text-xs text-ocp-text-dim font-mono">
            <div className="uppercase tracking-wider mb-2 text-ocp-accent">Targets</div>
            <div>Active targets: {service.ruViewSensing.length}</div>
            {service.ruViewError && <div className="text-ocp-red mt-1">Error: {service.ruViewError}</div>}
          </div>
        </div>
      )}

      {tab === "firmware" && (
        <div className="flex flex-col gap-4 max-w-2xl p-4 rounded-lg border border-ocp-border bg-ocp-panel">
          <span className="text-xs uppercase tracking-wider text-ocp-text-dim">Meshtastic Firmware Updater</span>
          <p className="text-xs text-ocp-text-dim leading-relaxed">
            Use the CLI script to list releases, download assets, and flash firmware with external tools.
          </p>
          <code className="px-3 py-2 rounded bg-ocp-bg border border-ocp-border text-[10px] font-mono text-ocp-accent">
            npm run firmware:list
          </code>
          <code className="px-3 py-2 rounded bg-ocp-bg border border-ocp-border text-[10px] font-mono text-ocp-accent">
            npm run firmware:flash -- --board rak4631 --tag v2.3.13.1 --port COM3
          </code>
          <p className="text-[10px] text-ocp-text-dim">
            Requires <code>esptool.py</code> for ESP32 boards or <code>nrfutil</code> for nRF52/RAK4631 boards.
          </p>
        </div>
      )}

      {tab === "baofeng" && (
        <BaofengChannelEditor
          baofengConnect={service.baofengConnect}
          baofengDisconnect={service.baofengDisconnect}
          baofengReadChannels={service.baofengReadChannels}
          baofengWriteChannels={service.baofengWriteChannels}
          baofengConnected={service.state.baofengConnected}
          baofengPortName={service.state.baofengPortName}
        />
      )}
    </div>
  );
}
