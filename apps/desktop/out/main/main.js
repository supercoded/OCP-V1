import { ipcMain, BrowserWindow, app } from "electron";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { EventEmitter } from "node:events";
import "node:fs/promises";
import "node:fs";
import "node:crypto";
import { WebSocket } from "ws";
import __cjs_mod__ from "node:module";
const __filename = import.meta.filename;
const __dirname = import.meta.dirname;
const require2 = __cjs_mod__.createRequire(import.meta.url);
class NodeInfo {
  constructor(id, info = {}) {
    this.id = id;
    this.lastHeard = Date.now();
    this.rxSnr = [];
    this.rxRssi = [];
    this.hopLimits = [];
    Object.assign(this, info);
  }
  update(packet) {
    const now = Date.now();
    this.lastHeard = now;
    if (typeof packet.rxSnr === "number") this.rxSnr.push(packet.rxSnr);
    if (typeof packet.rxRssi === "number") this.rxRssi.push(packet.rxRssi);
    if (typeof packet.hopLimit === "number") this.hopLimits.push(packet.hopLimit);
  }
  // Moving average of SNR over last 10 samples
  get avgSnr() {
    const arr = this.rxSnr.slice(-10);
    if (!arr.length) return null;
    return arr.reduce((a, b) => a + b, 0) / arr.length;
  }
}
class NetworkState extends EventEmitter {
  constructor({ nodeTimeoutMs = 5 * 60 * 1e3 } = {}) {
    super();
    this.nodeDB = /* @__PURE__ */ new Map();
    this.nodeTimeoutMs = nodeTimeoutMs;
    this._pruneTimer = setInterval(() => this._pruneStale(), this.nodeTimeoutMs);
  }
  /** Handle an incoming packet (from the transport layer). */
  onPacket(packet) {
    if (!packet?.from) return;
    const nodeId = packet.from;
    const isNew = !this.nodeDB.has(nodeId);
    const node = this.nodeDB.get(nodeId) ?? new NodeInfo(nodeId);
    node.update(packet);
    this.nodeDB.set(nodeId, node);
    if (isNew) this.emit("nodeAdded", node);
    else this.emit("nodeUpdated", node);
    this.emit("packetRelayed", packet);
  }
  /** Handle a NodeInfo broadcast (e.g., discovery beacon). */
  onNodeInfo(nodeInfo) {
    if (!nodeInfo?.num) return;
    const nodeId = nodeInfo.num;
    const isNew = !this.nodeDB.has(nodeId);
    const node = this.nodeDB.get(nodeId) ?? new NodeInfo(nodeId);
    Object.assign(node, nodeInfo);
    node.lastHeard = Date.now();
    this.nodeDB.set(nodeId, node);
    if (isNew) this.emit("nodeAdded", node);
    else this.emit("nodeUpdated", node);
  }
  /** Return an array of all known nodes. */
  getNodes() {
    return Array.from(this.nodeDB.values());
  }
  /** Return a single node by its id. */
  getNode(id) {
    return this.nodeDB.get(id);
  }
  /** Simple neighbor list – nodes heard within the timeout window. */
  getNeighbors() {
    const cutoff = Date.now() - this.nodeTimeoutMs;
    return this.getNodes().filter((n) => n.lastHeard >= cutoff);
  }
  /** Placeholder for route generation – returns empty array for now. */
  getRoutes() {
    return [];
  }
  /** Internal method to prune nodes that have timed out. */
  _pruneStale() {
    const now = Date.now();
    for (const [id, node] of this.nodeDB.entries()) {
      if (now - node.lastHeard > this.nodeTimeoutMs) {
        this.nodeDB.delete(id);
        this.emit("nodeLost", node);
      }
    }
  }
  /** Clean up resources when the instance is no longer needed. */
  destroy() {
    clearInterval(this._pruneTimer);
  }
}
class TransportConnection extends EventEmitter {
  constructor(kind, endpoint) {
    super();
    this.kind = kind;
    this.endpoint = endpoint;
    this.connected = false;
  }
  async connect() {
    throw new Error(`${this.kind} transport must implement connect()`);
  }
  async disconnect() {
    this.connected = false;
    this.emit("disconnected", { kind: this.kind, endpoint: this.endpoint });
  }
  async sendFrame(_frame) {
    throw new Error(`${this.kind} transport must implement sendFrame()`);
  }
  /**
   * Runtime hook used by tests and integration adapters.
   */
  emitIncomingFrame(frame) {
    this.emit("frame", frame);
  }
}
class BleTransportConnection extends TransportConnection {
  constructor(endpoint, io = {}) {
    super("ble", endpoint);
    this.io = io;
  }
  async connect() {
    if (this.io.connect) {
      await this.io.connect(this.endpoint);
    }
    this.connected = true;
    this.emit("connected", { kind: this.kind, endpoint: this.endpoint });
  }
  async sendFrame(frame) {
    if (!this.connected) {
      throw new Error("BLE transport is not connected");
    }
    if (this.io.sendFrame) {
      await this.io.sendFrame(frame);
    }
    this.emit("sent", { kind: this.kind, bytes: frame.length ?? 0 });
  }
}
class SerialTransportConnection extends TransportConnection {
  constructor(endpoint, io = {}) {
    super("serial", endpoint);
    this.io = io;
  }
  async connect() {
    if (this.io.open) {
      await this.io.open(this.endpoint);
    }
    this.connected = true;
    this.emit("connected", { kind: this.kind, endpoint: this.endpoint });
  }
  async sendFrame(frame) {
    if (!this.connected) {
      throw new Error("Serial transport is not connected");
    }
    if (this.io.write) {
      await this.io.write(frame);
    }
    this.emit("sent", { kind: this.kind, bytes: frame.length ?? 0 });
  }
}
class TcpTransportConnection extends TransportConnection {
  constructor(endpoint, io = {}) {
    super("tcp", endpoint);
    this.io = io;
  }
  async connect() {
    if (this.io.connect) {
      await this.io.connect(this.endpoint.host, this.endpoint.port);
    }
    this.connected = true;
    this.emit("connected", { kind: this.kind, endpoint: this.endpoint });
  }
  async sendFrame(frame) {
    if (!this.connected) {
      throw new Error("TCP transport is not connected");
    }
    if (this.io.write) {
      await this.io.write(frame);
    }
    this.emit("sent", { kind: this.kind, bytes: frame.length ?? 0 });
  }
}
const MESHTASTIC_BLE_SERVICE_UUIDS = [
  "6ba1b218-15a8-461f-bfa7-9c53b4a6bd19",
  // newer Meshtastic BLE service
  "0000180a-0000-1000-8000-00805f9b34fb"
  // optional: device info service
];
const MESHTASTIC_USB_IDS = [
  { vendorId: 4292, productId: 6e4, name: "CP210x (RAK, Heltec, etc.)" },
  { vendorId: 6790, productId: 29987, name: "CH340 (some LilyGo/TTGO)" },
  { vendorId: 1027, productId: 24577, name: "FT232 (some custom boards)" },
  { vendorId: 12346, productId: 16385, name: "ESP32-S3 native USB" },
  { vendorId: 12346, productId: 2, name: "ESP32-S2 native USB" }
];
async function discoverTransport(options = {}) {
  const {
    tcp,
    serial,
    ble,
    timeoutMs = 5e3,
    preferredOrder = ["tcp", "serial", "ble"],
    factories = {}
  } = options;
  const TcpFactory = factories.tcp || TcpTransportConnection;
  const SerialFactory = factories.serial || SerialTransportConnection;
  const BleFactory = factories.ble || BleTransportConnection;
  const errors = [];
  for (const kind of preferredOrder) {
    if (kind === "tcp" && tcp) {
      const transport = new TcpFactory(tcp);
      try {
        await withTimeout(transport.connect(), timeoutMs, "tcp connect timeout");
        return transport;
      } catch (err) {
        errors.push({ kind: "tcp", error: err.message });
      }
    }
    if (kind === "serial" && serial) {
      try {
        const endpoint = serial.portName ? serial : await resolveSerialEndpoint(serial, timeoutMs);
        const transport = new SerialFactory(endpoint);
        await withTimeout(transport.connect(), timeoutMs, "serial connect timeout");
        return transport;
      } catch (err) {
        errors.push({ kind: "serial", error: err.message });
      }
    }
    if (kind === "ble" && ble) {
      try {
        const endpoint = ble.deviceId ? ble : await resolveBleEndpoint(ble, timeoutMs);
        const transport = new BleFactory(endpoint);
        await withTimeout(transport.connect(), timeoutMs, "ble connect timeout");
        return transport;
      } catch (err) {
        errors.push({ kind: "ble", error: err.message });
      }
    }
  }
  const summary = errors.map((e) => `${e.kind}: ${e.error}`).join("; ");
  throw new Error(`No transport discovered. ${summary}`);
}
async function withTimeout(promise, ms, message) {
  const timeout = new Promise((_, reject) => {
    setTimeout(() => reject(new Error(message)), ms);
  });
  return Promise.race([promise, timeout]);
}
async function resolveSerialEndpoint(serialOptions, timeoutMs) {
  if (serialOptions.portName) {
    return {
      portName: serialOptions.portName,
      baudRate: serialOptions.baudRate ?? 921600
    };
  }
  if (!serialOptions.scan) {
    throw new Error("No serial portName and scan not enabled");
  }
  let SerialPort;
  try {
    const mod = await import("serialport");
    SerialPort = mod.SerialPort;
  } catch {
    throw new Error("serialport module is not installed; cannot scan serial ports");
  }
  const ports = await SerialPort.list();
  const match = ports.find(
    (p) => MESHTASTIC_USB_IDS.some(
      (id) => id.vendorId === Number(p.vendorId) && id.productId === Number(p.productId)
    )
  );
  if (!match) {
    const available = ports.map((p) => `${p.path} (vid=${p.vendorId},pid=${p.productId})`).join(", ");
    throw new Error(`No known Meshtastic serial port found. Available: ${available || "none"}`);
  }
  return {
    portName: match.path,
    baudRate: serialOptions.baudRate ?? 921600
  };
}
async function resolveBleEndpoint(bleOptions, timeoutMs) {
  if (bleOptions.deviceId) {
    return bleOptions;
  }
  if (!bleOptions.scan) {
    throw new Error("No BLE deviceId and scan not enabled");
  }
  let noble;
  try {
    const mod = await import("@abandonware/noble");
    noble = mod.default ?? mod;
  } catch {
    throw new Error("@abandonware/noble is not installed; cannot scan BLE devices");
  }
  const targetUuid = bleOptions.serviceUuid ?? MESHTASTIC_BLE_SERVICE_UUIDS[0];
  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      noble.stopScanning();
      noble.removeAllListeners("discover");
      reject(new Error(`BLE scan timeout looking for service ${targetUuid}`));
    }, timeoutMs);
    noble.once("stateChange", (state) => {
      if (state === "poweredOn") {
        noble.startScanning([targetUuid], false);
      } else {
        clearTimeout(timer);
        noble.removeAllListeners("discover");
        reject(new Error(`BLE adapter state: ${state}`));
      }
    });
    noble.on("discover", (peripheral) => {
      clearTimeout(timer);
      noble.stopScanning();
      noble.removeAllListeners("discover");
      resolve({ deviceId: peripheral.id, peripheral });
    });
    if (noble._state === "poweredOn") {
      noble.startScanning([targetUuid], false);
    }
  });
}
class RuViewClient extends EventEmitter {
  constructor({
    host = "localhost",
    httpPort = 3e3,
    wsPort = 3001,
    reconnect = true,
    reconnectMs = 3e3
  } = {}) {
    super();
    this.host = host;
    this.httpPort = httpPort;
    this.wsPort = wsPort;
    this.reconnect = reconnect;
    this.reconnectMs = reconnectMs;
    this.ws = null;
    this.closed = false;
  }
  get wsUrl() {
    return `ws://${this.host}:${this.wsPort}/ws/sensing`;
  }
  start() {
    if (this.ws) return;
    this.closed = false;
    this.#connect();
  }
  stop() {
    this.closed = true;
    this.reconnect = false;
    this.ws?.close();
    this.ws = null;
  }
  #connect() {
    try {
      this.ws = new WebSocket(this.wsUrl);
    } catch (err) {
      this.emit("error", err);
      this.#scheduleReconnect();
      return;
    }
    this.ws.on("open", () => {
      this.emit("open");
    });
    this.ws.on("message", (data) => {
      try {
        const text = data.toString("utf8");
        const frame = JSON.parse(text);
        this.#handleFrame(frame);
      } catch (err) {
        this.emit("error", err);
      }
    });
    this.ws.on("error", (err) => this.emit("error", err));
    this.ws.on("close", (code) => {
      this.ws = null;
      this.emit("close", code);
      if (!this.closed && this.reconnect) {
        this.#scheduleReconnect();
      }
    });
  }
  #handleFrame(frame) {
    if (frame.type !== "sensing_update") return;
    const nodes = frame.nodes || [];
    for (const n of nodes) {
      if (!n.position || n.position.length < 2) continue;
      this.emit("sensing", {
        nodeId: n.node_id,
        x: n.position[0],
        y: n.position[1],
        z: n.position[2] ?? 0,
        rssi: n.rssi_dbm ?? null,
        timestamp: typeof frame.timestamp === "number" ? frame.timestamp * 1e3 : Date.now(),
        source: frame.source || "unknown"
      });
    }
  }
  #scheduleReconnect() {
    if (this.closed) return;
    setTimeout(() => this.#connect(), this.reconnectMs);
  }
}
class OcpService {
  networkState = new NetworkState({ nodeTimeoutMs: 6e4 });
  ruview;
  transport = null;
  interval;
  lastState;
  start() {
    this.#registerIpc();
    this.#broadcastLoop();
    this.networkState.on("packetRelayed", () => this.#emit());
    this.networkState.on("nodeAdded", () => this.#emit());
    this.networkState.on("nodeUpdated", () => this.#emit());
    this.networkState.on("nodeLost", () => this.#emit());
  }
  stop() {
    if (this.interval) clearInterval(this.interval);
    this.transport?.disconnect();
    this.ruview?.stop();
  }
  #registerIpc() {
    ipcMain.handle("ocp:connect", async (_evt, options) => {
      try {
        this.transport = await discoverTransport(options);
        this.transport.on("frame", (frame) => {
          if (frame.packet) this.networkState.onPacket(frame.packet);
          if (frame.nodeInfo) this.networkState.onNodeInfo(frame.nodeInfo);
        });
        this.#emit();
        return { ok: true, kind: this.transport.kind, endpoint: this.transport.endpoint };
      } catch (err) {
        return { ok: false, error: err.message };
      }
    });
    ipcMain.handle("ocp:disconnect", async () => {
      await this.transport?.disconnect();
      this.transport = null;
      this.#emit();
      return { ok: true };
    });
    ipcMain.handle("ocp:ruview:start", async (_evt, cfg) => {
      this.ruview?.stop();
      this.ruview = new RuViewClient({
        host: cfg.host || "localhost",
        wsPort: cfg.wsPort ?? 3001,
        reconnect: true
      });
      this.ruview.on("sensing", (sensing) => {
        BrowserWindow.getAllWindows().forEach((win) => {
          win.webContents.send("ocp:ruview:sensing", sensing);
        });
      });
      this.ruview.on("error", (err) => {
        BrowserWindow.getAllWindows().forEach((win) => {
          win.webContents.send("ocp:ruview:error", String(err?.message || err));
        });
      });
      this.ruview.on("open", () => this.#emit());
      this.ruview.on("close", () => this.#emit());
      this.ruview.start();
      return { ok: true };
    });
    ipcMain.handle("ocp:ruview:stop", async () => {
      this.ruview?.stop();
      this.ruview = void 0;
      this.#emit();
      return { ok: true };
    });
    ipcMain.handle("ocp:state", () => this.#state());
  }
  #state() {
    const nodes = this.networkState.getNodes().map((n) => ({
      id: n.id,
      lastHeard: n.lastHeard,
      avgSnr: n.avgSnr,
      avgRssi: n.rxRssi.length ? n.rxRssi.slice(-5).reduce((a, b) => a + b, 0) / n.rxRssi.slice(-5).length : null,
      lat: n.position?.latitude,
      lon: n.position?.longitude,
      name: n.user?.longName
    }));
    return {
      connected: !!this.transport?.connected,
      transportKind: this.transport?.kind,
      nodeCount: nodes.length,
      nodes,
      ruViewConnected: this.ruview ? true : false
    };
  }
  #emit() {
    const state = this.#state();
    if (JSON.stringify(state) === JSON.stringify(this.lastState)) return;
    this.lastState = state;
    BrowserWindow.getAllWindows().forEach((win) => {
      win.webContents.send("ocp:state:update", state);
    });
  }
  #broadcastLoop() {
    this.interval = setInterval(() => this.#emit(), 1e3);
  }
}
const __dirname$1 = path.dirname(fileURLToPath(import.meta.url));
let ocpService = null;
async function createWindow() {
  const win = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 900,
    minHeight: 600,
    title: "OCP-V1",
    darkTheme: true,
    backgroundColor: "#050a0e",
    webPreferences: {
      preload: path.join(__dirname$1, "../preload/preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false
    }
  });
  if (process.env.VITE_DEV_SERVER_URL) {
    await win.loadURL(process.env.VITE_DEV_SERVER_URL);
    win.webContents.openDevTools();
  } else {
    await win.loadFile(path.join(__dirname$1, "../renderer/index.html"));
  }
}
app.whenReady().then(async () => {
  ocpService = new OcpService();
  ocpService.start();
  createWindow();
  app.on("activate", () => {
    if (BrowserWindow.getAllWindows().length === 0) createWindow();
  });
});
app.on("window-all-closed", () => {
  if (process.platform !== "darwin") app.quit();
});
ipcMain.handle("ocp:ping", () => "pong");
