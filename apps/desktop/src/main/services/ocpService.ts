import { app, ipcMain, type IpcMainInvokeEvent, BrowserWindow } from "electron";
import { join } from "node:path";
import { randomBytes } from "node:crypto";
import { NetworkState } from "@ocp/network";
import {
  PinVault,
  JsonFileOfflineStore,
} from "@ocp/offline-core";
import { MeshtasticTransport } from "@ocp/bridge-meshtastic";
import { RuViewClient } from "@ocp/tools-ruview";
import { RtlTcpClient, SpectrumProcessor } from "@ocp/tools-rtlsdr";
import { PmtilesServer } from "@ocp/maps";
import { BaofengTransport } from "@ocp/bridge-baofeng";
import { PluginHost, PERMISSIONS, CAPABILITIES } from "@ocp/plugin-api";
import { createDiagnosticsPlugin } from "@ocp/plugin-example";

const MESSAGE_HISTORY_MAX = 500;
const UNLOCK_MAX_FAILURES = 5;
const UNLOCK_COOLDOWN_MS = 30_000;

export interface SonarNode {
  id: number;
  lastHeard: number;
  avgSnr: number | null;
  avgRssi: number | null;
  lat?: number;
  lon?: number;
  name?: string;
  role?: string;
  shortName?: string;
}

export interface SpectrumFrame {
  centerFreq: number;
  sampleRate: number;
  fftSize: number;
  frequencies: Float32Array;
  magnitudes: Float32Array;
}

export interface PluginSummary {
  id: string;
  name: string;
  version: string;
  description?: string;
  active: boolean;
  permissions: string[];
  capabilities: string[];
  declaredCapabilities?: string[];
}

export interface SecurityState {
  pinConfigured: boolean;
  unlocked: boolean;
}

export interface OcpState {
  connected: boolean;
  transportKind?: string;
  transportEndpoint?: string;
  localNodeId?: number;
  nodeCount: number;
  nodes: SonarNode[];
  ruViewConnected: boolean;
  rtlConnected: boolean;
  rtlCenterFreq?: number;
  rtlSampleRate?: number;
  rtlHost?: string;
  rtlPort?: number;
  mapPort?: number;
  baofengConnected: boolean;
  baofengPortName?: string;
  plugins?: PluginSummary[];
  security?: SecurityState;
}

/** Meshtastic Position uses integer microdegrees (latitudeI / 1e7). */
function extractLatLon(position: any): { lat?: number; lon?: number } {
  if (!position) return {};
  let lat = position.latitude;
  let lon = position.longitude;
  if (typeof lat !== "number" && typeof position.latitudeI === "number") {
    lat = position.latitudeI / 1e7;
  }
  if (typeof lon !== "number" && typeof position.longitudeI === "number") {
    lon = position.longitudeI / 1e7;
  }
  if (typeof lat === "number" && typeof lon === "number" && Number.isFinite(lat) && Number.isFinite(lon)) {
    return { lat, lon };
  }
  return {};
}

function isTextMessage(decoded: any): boolean {
  if (!decoded) return false;
  const port = decoded.portnum;
  return port === "TEXT_MESSAGE_APP" || port === 1;
}

function packetDecoded(packet: any): any {
  return packet?.decoded ?? packet?.payload;
}

function formatEndpoint(endpoint: any): string | undefined {
  if (!endpoint) return undefined;
  if (endpoint.host && endpoint.port) return `${endpoint.host}:${endpoint.port}`;
  if (endpoint.portName) return String(endpoint.portName);
  if (endpoint.deviceId) return String(endpoint.deviceId);
  return undefined;
}

export class OcpService {
  networkState = new NetworkState({ nodeTimeoutMs: 60_000, replayWindowSize: 512 });
  ruview?: RuViewClient;
  transport: any = null;
  localNodeId?: number;
  /** Holds a lightweight history of text messages for the UI */
  messageHistory: any[] = [];
  interval?: ReturnType<typeof setInterval>;
  lastState?: OcpState;

  rtlClient?: RtlTcpClient;
  rtlProcessor?: SpectrumProcessor;
  // Map server for offline PMTiles handling
  mapServer?: PmtilesServer;
  mapPort?: number;

  // Baofeng serial transport
  baofeng?: BaofengTransport;
  baofengConnected: boolean = false;
  baofengPortName?: string;

  pinVault!: PinVault;
  offlineStore!: JsonFileOfflineStore;
  pinConfigured = false;
  securityUnlocked = true;
  unlockFailures = 0;
  unlockBlockedUntil = 0;

  pluginHost = new PluginHost({
    allowedPermissions: [
      PERMISSIONS.STATE_READ,
      PERMISSIONS.NETWORK_READ,
      PERMISSIONS.MESSAGING_SEND,
      PERMISSIONS.DEVICE_CONNECT,
    ],
    getAppState: () => this.#stateWithoutPlugins(),
  });

  start() {
    const userData = app.getPath("userData");
    this.pinVault = new PinVault(join(userData, "ocp-pin-vault.json"));
    this.offlineStore = new JsonFileOfflineStore({
      dbPath: join(userData, "ocp-offline-db.json"),
      encryptAtRest: true,
    });

    this.#registerIpc();
    this.#broadcastLoop();
    void this.#initSecurity();
    void this.#initPlugins();

    this.networkState.on("packetRelayed", () => this.#emit());
    this.networkState.on("packetReplay", () => this.#emit());
    this.networkState.on("nodeAdded", () => this.#emit());
    this.networkState.on("nodeUpdated", () => this.#emit());
    this.networkState.on("nodeLost", () => this.#emit());
  }

  stop() {
    if (this.interval) clearInterval(this.interval);
    this.transport?.disconnect();
    this.ruview?.stop();
    this.#stopRtl();
  }

  #registerIpc() {
    ipcMain.handle("ocp:connect", async (_evt: IpcMainInvokeEvent, options: any) => {
      try {
        this.#assertUnlocked();
        await this.transport?.disconnect?.();
        this.transport = null;
        this.localNodeId = undefined;

        const tcp = options?.tcp;
        if (!tcp?.host || !tcp?.port) {
          return {
            ok: false,
            error: "TCP Meshtastic only in this build — provide tcp.host and tcp.port",
          };
        }
        const endpoint = { host: String(tcp.host), port: Number(tcp.port) };
        const transport = new MeshtasticTransport(endpoint, {
          reconnectInterval: 5000,
          maxRetries: 10,
          networkState: this.networkState,
        });
        this.#wireTransportFrames(transport);
        transport.on("connected", () => this.#emit());
        transport.on("disconnected", () => this.#emit());
        transport.on("error", () => this.#emit());
        await transport.connect();
        this.transport = transport;

        this.#emit();
        return { ok: true, kind: this.transport.kind, endpoint: this.transport.endpoint };
      } catch (err: any) {
        this.transport = null;
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:disconnect", async () => {
      try {
        this.#assertUnlocked();
        await this.transport?.disconnect();
        this.transport = null;
        this.localNodeId = undefined;
        this.#emit();
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:ruview:start", async (_evt: IpcMainInvokeEvent, cfg: { host?: string; wsPort?: number }) => {
      try {
        this.#assertUnlocked();
        this.ruview?.stop();
        this.ruview = new RuViewClient({
          host: cfg.host || "localhost",
          wsPort: cfg.wsPort ?? 3001,
          reconnect: true,
        });
        this.ruview.on("sensing", (sensing: any) => {
          BrowserWindow.getAllWindows().forEach((win) => {
            win.webContents.send("ocp:ruview:sensing", sensing);
          });
        });
        this.ruview.on("error", (err: any) => {
          BrowserWindow.getAllWindows().forEach((win) => {
            win.webContents.send("ocp:ruview:error", String(err?.message || err));
          });
        });
        this.ruview.on("open", () => this.#emit());
        this.ruview.on("close", () => this.#emit());
        this.ruview.start();
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:ruview:stop", async () => {
      try {
        this.#assertUnlocked();
        this.ruview?.stop();
        this.ruview = undefined;
        this.#emit();
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:rtl:connect", async (_evt: IpcMainInvokeEvent, cfg: { host?: string; port?: number; centerFreq?: number; sampleRate?: number }) => {
      try {
        this.#assertUnlocked();
        this.#stopRtl();
        const host = cfg.host || "localhost";
        const port = cfg.port ?? 1234;
        const client = new RtlTcpClient({ host, port, autoReconnect: true });
        const processor = new SpectrumProcessor({
          fftSize: 2048,
          sampleRate: cfg.sampleRate || 2048000,
          centerFreq: cfg.centerFreq || 100000000,
        });

        client.on("dongleInfo", () => this.#emit());
        client.on("iq", (samples: Uint8Array) => processor.feedInterleavedUint8(samples));
        client.on("error", (err: any) => {
          BrowserWindow.getAllWindows().forEach((win) => {
            win.webContents.send("ocp:rtl:error", String(err?.message || err));
          });
        });
        client.on("close", () => {
          this.#emit();
          this.#stopRtl();
        });

        processor.on("spectrum", (frame: SpectrumFrame) => {
          BrowserWindow.getAllWindows().forEach((win) => {
            win.webContents.send("ocp:rtl:spectrum", frame);
          });
        });

        client.on("recording:started", (info: any) => {
          BrowserWindow.getAllWindows().forEach((win) => {
            win.webContents.send("ocp:rtl:recording:started", info);
          });
        });
        client.on("recording:stopped", (info: any) => {
          BrowserWindow.getAllWindows().forEach((win) => {
            win.webContents.send("ocp:rtl:recording:stopped", info);
          });
        });
        client.on("recording:error", (err: any) => {
          BrowserWindow.getAllWindows().forEach((win) => {
            win.webContents.send("ocp:rtl:error", `Recording error: ${err?.message || err}`);
          });
        });

        await client.connect();
        this.rtlClient = client;
        this.rtlProcessor = processor;
        this.#emit();
        return { ok: true, host, port };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:rtl:disconnect", async () => {
      try {
        this.#assertUnlocked();
        this.#stopRtl();
        this.#emit();
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:rtl:setFreq", async (_evt: IpcMainInvokeEvent, hz: number) => {
      try {
        this.#assertUnlocked();
        if (!this.rtlClient) return { ok: false, error: "RTL-SDR not connected" };
        this.rtlClient.setCenterFreq(hz);
        this.rtlProcessor?.configure({ centerFreq: hz });
        this.#emit();
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:rtl:setGain", async (_evt: IpcMainInvokeEvent, { mode, value }: { mode?: "auto" | "manual"; value?: number }) => {
      try {
        this.#assertUnlocked();
        if (!this.rtlClient) return { ok: false, error: "RTL-SDR not connected" };
        if (mode) this.rtlClient.setGainMode(mode === "manual");
        if (value !== undefined) this.rtlClient.setGain(Math.round(value * 10));
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:rtl:mock", async (_evt: IpcMainInvokeEvent, cfg: { centerFreq?: number; sampleRate?: number; carriers?: { freqOffset: number; amplitude: number }[] }) => {
      try {
        this.#assertUnlocked();
        this.#stopRtl();
        const { MockRtlSource } = await import("@ocp/tools-rtlsdr");
        const processor = new SpectrumProcessor({
          fftSize: 2048,
          sampleRate: cfg.sampleRate || 2048000,
          centerFreq: cfg.centerFreq || 100000000,
        });
        const mock = new MockRtlSource({
          sampleRate: cfg.sampleRate || 2048000,
          centerFreq: cfg.centerFreq || 100000000,
          carriers: cfg.carriers || [{ freqOffset: 256000, amplitude: 0.9 }],
        });
        mock.on("iq", (samples: Uint8Array) => processor.feedInterleavedUint8(samples));
        mock.start();
        processor.on("spectrum", (frame: SpectrumFrame) => {
          BrowserWindow.getAllWindows().forEach((win) => {
            win.webContents.send("ocp:rtl:spectrum", frame);
          });
        });
        this.rtlClient = mock as any;
        this.rtlProcessor = processor;
        this.#emit();
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:rtl:startRecording", async (_evt: IpcMainInvokeEvent, filename?: string) => {
      try {
        this.#assertUnlocked();
        if (!this.rtlClient) return { ok: false, error: "RTL-SDR not connected" };
        if (typeof (this.rtlClient as any).startRecording !== "function") {
          return { ok: false, error: "Recording not supported on this source" };
        }
        return (this.rtlClient as any).startRecording(filename);
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:rtl:stopRecording", async () => {
      try {
        this.#assertUnlocked();
        if (!this.rtlClient) return { ok: false, error: "RTL-SDR not connected" };
        if (typeof (this.rtlClient as any).stopRecording !== "function") {
          return { ok: false, error: "Recording not supported on this source" };
        }
        return (this.rtlClient as any).stopRecording();
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:rtl:recordingStatus", async () => {
      try {
        this.#assertUnlocked();
        if (!this.rtlClient) return { recording: false };
        const client = this.rtlClient as any;
        if (typeof client.isRecording === "undefined") return { recording: false };
        return {
          recording: client.isRecording,
          path: client.recordingPath ?? null,
          startTime: client.recordingStartTime ?? null,
          bytesWritten: client.recordingBytesWritten ?? 0,
        };
      } catch (err: any) {
        return { recording: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:state", () => this.#state());

    ipcMain.handle("ocp:message:send", async (_evt: IpcMainInvokeEvent, params: any) => {
      try {
        this.#assertUnlocked();
        const { text, channel = 0, destinationNodeId } = params ?? {};
        if (!this.transport?.connected) {
          return { ok: false, error: "No Meshtastic transport connected" };
        }
        if (!text || typeof text !== "string" || !text.trim()) {
          return { ok: false, error: "Message text required" };
        }
        const packet: any = {
          to: destinationNodeId ?? 0,
          id: randomBytes(4).readUInt32LE(0),
          hopLimit: 3,
          channel,
          payload: {
            portnum: 1,
            text,
          },
        };
        await this.transport.sendFrame({ packet });
        const msg = {
          id: packet.id,
          text,
          from: "you",
          to: destinationNodeId ?? 0,
          channel,
          timestamp: Date.now(),
          outgoing: true,
        };
        await this.#pushMessage(msg);
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:message:onReceive", async () => {
      try {
        this.#assertUnlocked();
        return { ok: this.transport ? true : false, error: this.transport ? undefined : "Transport not initialized" };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:message:getHistory", async () => {
      try {
        this.#assertUnlocked();
        return { ok: true, history: this.messageHistory };
      } catch (err: any) {
        return { ok: false, error: err.message, history: [] };
      }
    });

    ipcMain.handle("ocp:map:start", async (_evt: IpcMainInvokeEvent, filePath: string) => {
      try {
        this.#assertUnlocked();
        if (this.mapServer) {
          await this.mapServer.stop();
          this.mapServer = undefined;
          this.mapPort = undefined;
        }
        const server = new PmtilesServer(filePath);
        const port = await server.start();
        this.mapServer = server;
        this.mapPort = port;
        return { ok: true, port };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:map:stop", async () => {
      try {
        this.#assertUnlocked();
        if (this.mapServer) {
          await this.mapServer.stop();
          this.mapServer = undefined;
          this.mapPort = undefined;
        }
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("baofeng:connect", async (_evt: IpcMainInvokeEvent, portName: string) => {
      try {
        this.#assertUnlocked();
        if (this.baofeng) {
          await this.baofeng.disconnect();
        }
        const transport = new BaofengTransport({ portName, baudRate: 9600 });
        transport.onProgress = (info: { current: number; total: number; phase: string }) => {
          BrowserWindow.getAllWindows().forEach((win) => {
            win.webContents.send("baofeng:progress", info);
          });
        };
        await transport.connect();
        this.baofeng = transport;
        this.baofengConnected = true;
        this.baofengPortName = portName;
        this.#emit();
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("baofeng:disconnect", async () => {
      try {
        this.#assertUnlocked();
        try {
          await this.baofeng?.disconnect();
        } catch {}
        this.baofeng = undefined;
        this.baofengConnected = false;
        this.baofengPortName = undefined;
        this.#emit();
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("baofeng:readChannels", async () => {
      try {
        this.#assertUnlocked();
        if (!this.baofeng || !this.baofengConnected) {
          return { ok: false, error: "Not connected to Baofeng radio" };
        }
        const channels = await this.baofeng.readAllChannels();
        const serialized = channels.map((ch: any) => ({ ...ch }));
        return { ok: true, channels: serialized };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("baofeng:writeChannels", async (_evt: IpcMainInvokeEvent, channels: any[]) => {
      try {
        this.#assertUnlocked();
        if (!this.baofeng || !this.baofengConnected) {
          return { ok: false, error: "Not connected to Baofeng radio" };
        }
        await this.baofeng.writeAllChannels(channels);
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:plugins:list", async () => {
      try {
        this.#assertUnlocked();
        return { ok: true, plugins: this.pluginHost.list() };
      } catch (err: any) {
        return { ok: false, error: err.message, plugins: [] };
      }
    });

    ipcMain.handle("ocp:plugins:activate", async (_evt: IpcMainInvokeEvent, id: string) => {
      try {
        this.#assertUnlocked();
        await this.pluginHost.activate(id);
        this.#emit();
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:plugins:deactivate", async (_evt: IpcMainInvokeEvent, id: string) => {
      try {
        this.#assertUnlocked();
        await this.pluginHost.deactivate(id);
        this.#emit();
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:plugins:status", async () => {
      try {
        this.#assertUnlocked();
        const providers = this.pluginHost.getCapabilities(CAPABILITIES.STATUS_PROVIDER);
        const statuses = providers.map(({ pluginId, impl }) => {
          try {
            return { pluginId, ok: true, status: impl?.getStatus?.() ?? null };
          } catch (err: any) {
            return { pluginId, ok: false, error: err.message };
          }
        });
        return { ok: true, statuses };
      } catch (err: any) {
        return { ok: false, error: err.message, statuses: [] };
      }
    });

    ipcMain.handle("ocp:security:status", async () => ({
      ok: true,
      pinConfigured: this.pinConfigured,
      unlocked: this.securityUnlocked,
    }));

    ipcMain.handle("ocp:security:setPin", async (_evt: IpcMainInvokeEvent, pin: string) => {
      try {
        this.#assertUnlocked();
        await this.pinVault.setPin(pin);
        this.pinConfigured = true;
        this.securityUnlocked = true;
        await this.#openEncryptedStore();
        this.#emit();
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:security:unlock", async (_evt: IpcMainInvokeEvent, pin: string) => {
      try {
        this.#assertUnlockAllowed();
        await this.pinVault.unlock(pin);
        this.unlockFailures = 0;
        this.unlockBlockedUntil = 0;
        this.securityUnlocked = true;
        await this.#openEncryptedStore();
        this.#emit();
        return { ok: true };
      } catch (err: any) {
        this.#recordUnlockFailure();
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:security:lock", async () => {
      try {
        await this.transport?.disconnect?.();
        this.transport = null;
        this.#stopRtl();
        this.ruview?.stop();
        this.ruview = undefined;
        this.pinVault.lock();
        this.offlineStore.setKeyCipher(null);
        this.securityUnlocked = !this.pinConfigured;
        this.#emit();
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle(
      "ocp:security:changePin",
      async (_evt: IpcMainInvokeEvent, params: { currentPin: string; newPin: string }) => {
        try {
          this.#assertUnlocked();
          const { oldCipher, newCipher } = await this.pinVault.changePin(
            params.currentPin,
            params.newPin
          );
          this.pinConfigured = true;
          this.securityUnlocked = true;
          await this.offlineStore.rewrap(oldCipher, newCipher);
          this.offlineStore.encryptAtRest = true;
          this.offlineStore.setKeyCipher(newCipher);
          this.#emit();
          return { ok: true };
        } catch (err: any) {
          return { ok: false, error: err.message };
        }
      }
    );

    ipcMain.handle("ocp:security:clearPin", async (_evt: IpcMainInvokeEvent, pin: string) => {
      try {
        this.#assertUnlocked();
        if (this.pinConfigured) {
          await this.pinVault.unlock(pin);
        }
        await this.pinVault.clearPin();
        this.pinConfigured = false;
        this.securityUnlocked = true;
        this.offlineStore.setKeyCipher(null);
        this.offlineStore.encryptAtRest = false;
        this.#emit();
        return { ok: true };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });
  }

  #assertUnlocked() {
    if (this.pinConfigured && !this.securityUnlocked) {
      throw new Error("App is locked — unlock with PIN first");
    }
  }

  #assertUnlockAllowed() {
    if (Date.now() < this.unlockBlockedUntil) {
      const secs = Math.ceil((this.unlockBlockedUntil - Date.now()) / 1000);
      throw new Error(`Too many failed PIN attempts — try again in ${secs}s`);
    }
  }

  #recordUnlockFailure() {
    this.unlockFailures += 1;
    if (this.unlockFailures >= UNLOCK_MAX_FAILURES) {
      this.unlockBlockedUntil = Date.now() + UNLOCK_COOLDOWN_MS;
      this.unlockFailures = 0;
    }
  }

  async #pushMessage(msg: any) {
    this.messageHistory.push(msg);
    if (this.messageHistory.length > MESSAGE_HISTORY_MAX) {
      this.messageHistory = this.messageHistory.slice(-MESSAGE_HISTORY_MAX);
    }
    if (this.securityUnlocked && this.pinVault.cipher) {
      try {
        await this.offlineStore.saveChatHistory(this.messageHistory, MESSAGE_HISTORY_MAX);
      } catch {
        // non-fatal
      }
    }
  }

  async #initSecurity() {
    try {
      this.pinConfigured = await this.pinVault.isConfigured();
      this.securityUnlocked = !this.pinConfigured;
      if (this.securityUnlocked && this.pinVault.cipher) {
        await this.#openEncryptedStore();
      }
      this.#emit();
    } catch (err: any) {
      console.error("Security init failed:", err?.message || err);
    }
  }

  async #openEncryptedStore() {
    if (!this.pinVault.cipher) return;
    this.offlineStore.encryptAtRest = true;
    this.offlineStore.setKeyCipher(this.pinVault.cipher);
    await this.offlineStore.init();
    try {
      const hist = await this.offlineStore.loadChatHistory();
      if (hist.length) this.messageHistory = hist.slice(-MESSAGE_HISTORY_MAX);
    } catch {
      // ignore corrupt history
    }
  }

  async #initPlugins() {
    try {
      await this.pluginHost.install(createDiagnosticsPlugin());
      await this.pluginHost.activate("ocp.example.diagnostics");
      this.#emit();
    } catch (err: any) {
      console.error("Plugin init failed:", err?.message || err);
    }
  }

  #stopRtl() {
    this.rtlClient?.disconnect?.();
    this.rtlClient?.destroy?.();
    this.rtlProcessor?.destroy();
    this.rtlClient = undefined;
    this.rtlProcessor = undefined;
  }

  #wireTransportFrames(transport: any) {
    if (!transport?.on) return;
    transport.on("frame", (frame: any) => {
      if (frame?.myInfo?.myNodeNum != null) {
        this.localNodeId = Number(frame.myInfo.myNodeNum);
      }
      // MeshtasticTransport already feeds NetworkState when options.networkState is set;
      // still feed when using discoverTransport fallback.
      if (!transport.options?.networkState) {
        if (frame.packet) this.networkState.onPacket(frame.packet);
        if (frame.nodeInfo) this.networkState.onNodeInfo(frame.nodeInfo);
      }
      const decoded = packetDecoded(frame?.packet);
      if (isTextMessage(decoded)) {
        const msg = {
          id: frame.packet.id,
          text: decoded.text ?? "",
          from: frame.packet.from,
          to: frame.packet.to,
          channel: typeof frame.packet.channel === "number" ? frame.packet.channel : 0,
          timestamp: Date.now(),
          outgoing: false,
        };
        void this.#pushMessage(msg).then(() => {
          BrowserWindow.getAllWindows().forEach((win) => {
            win.webContents.send("ocp:message:received", msg);
          });
        });
      }
      this.#emit();
    });
  }

  #stateWithoutPlugins(): Omit<OcpState, "plugins"> {
    const nodes: SonarNode[] = this.networkState.getNodes().map((n: any) => {
      const { lat, lon } = extractLatLon(n.position);
      return {
        id: n.id,
        lastHeard: n.lastHeard,
        avgSnr: n.avgSnr ?? (typeof n.snr === "number" ? n.snr : null),
        avgRssi: n.rxRssi?.length
          ? n.rxRssi.slice(-5).reduce((a: number, b: number) => a + b, 0) /
            n.rxRssi.slice(-5).length
          : null,
        lat,
        lon,
        name: n.user?.longName,
        shortName: n.user?.shortName,
        role: n.user?.role ?? n.role,
      };
    });
    return {
      connected: !!this.transport?.connected,
      transportKind: this.transport?.kind,
      transportEndpoint: formatEndpoint(this.transport?.endpoint),
      localNodeId: this.localNodeId,
      nodeCount: nodes.length,
      nodes,
      ruViewConnected: this.ruview ? true : false,
      rtlConnected: this.rtlClient ? true : false,
      rtlCenterFreq: this.rtlProcessor?.centerFreq,
      rtlSampleRate: this.rtlProcessor?.sampleRate,
      rtlHost: (this.rtlClient as any)?.host,
      rtlPort: (this.rtlClient as any)?.port,
      mapPort: this.mapPort,
      baofengConnected: this.baofengConnected,
      baofengPortName: this.baofengPortName,
      security: {
        pinConfigured: this.pinConfigured,
        unlocked: this.securityUnlocked,
      },
    };
  }

  #state(): OcpState {
    return {
      ...this.#stateWithoutPlugins(),
      plugins: this.pluginHost.list() as PluginSummary[],
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
    this.interval = setInterval(() => this.#emit(), 1000);
  }
}
