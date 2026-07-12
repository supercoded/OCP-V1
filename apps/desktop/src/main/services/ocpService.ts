import { ipcMain, type IpcMainInvokeEvent, BrowserWindow } from "electron";
import { NetworkState } from "@ocp/network";
import { discoverTransport } from "@ocp/offline-core";
import { RuViewClient } from "@ocp/tools-ruview";

export interface SonarNode {
  id: number;
  lastHeard: number;
  avgSnr: number | null;
  avgRssi: number | null;
  lat?: number;
  lon?: number;
  name?: string;
}

export interface OcpState {
  connected: boolean;
  transportKind?: string;
  nodeCount: number;
  nodes: SonarNode[];
  ruViewConnected: boolean;
}

export class OcpService {
  networkState = new NetworkState({ nodeTimeoutMs: 60_000 });
  ruview?: RuViewClient;
  transport: any = null;
  interval?: ReturnType<typeof setInterval>;
  lastState?: OcpState;

  start() {
    this.#registerIpc();
    this.#broadcastLoop();

    // Feed Meshtastic packets into NetworkState
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
    ipcMain.handle("ocp:connect", async (_evt: IpcMainInvokeEvent, options: any) => {
      try {
        this.transport = await discoverTransport(options);
        this.transport.on("frame", (frame: any) => {
          if (frame.packet) this.networkState.onPacket(frame.packet);
          if (frame.nodeInfo) this.networkState.onNodeInfo(frame.nodeInfo);
        });
        this.#emit();
        return { ok: true, kind: this.transport.kind, endpoint: this.transport.endpoint };
      } catch (err: any) {
        return { ok: false, error: err.message };
      }
    });

    ipcMain.handle("ocp:disconnect", async () => {
      await this.transport?.disconnect();
      this.transport = null;
      this.#emit();
      return { ok: true };
    });

    ipcMain.handle("ocp:ruview:start", async (_evt: IpcMainInvokeEvent, cfg: { host?: string; wsPort?: number }) => {
      this.ruview?.stop();
      this.ruview = new RuViewClient({
        host: cfg.host || "localhost",
        wsPort: cfg.wsPort ?? 3001,
        reconnect: true,
      });
      this.ruview.on("sensing", (sensing: any) => {
        // Forward to renderer
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
    });

    ipcMain.handle("ocp:ruview:stop", async () => {
      this.ruview?.stop();
      this.ruview = undefined;
      this.#emit();
      return { ok: true };
    });

    ipcMain.handle("ocp:state", () => this.#state());
  }

  #state(): OcpState {
    const nodes: SonarNode[] = this.networkState.getNodes().map((n: any) => ({
      id: n.id,
      lastHeard: n.lastHeard,
      avgSnr: n.avgSnr,
      avgRssi: n.rxRssi.length
        ? n.rxRssi.slice(-5).reduce((a: number, b: number) => a + b, 0) /
          n.rxRssi.slice(-5).length
        : null,
      lat: n.position?.latitude,
      lon: n.position?.longitude,
      name: n.user?.longName,
    }));
    return {
      connected: !!this.transport?.connected,
      transportKind: this.transport?.kind,
      nodeCount: nodes.length,
      nodes,
      ruViewConnected: this.ruview ? true : false,
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
