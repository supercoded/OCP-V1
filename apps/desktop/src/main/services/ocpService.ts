import { ipcMain, type IpcMainInvokeEvent, BrowserWindow } from "electron";
import { NetworkState } from "@ocp/network";
import { discoverTransport } from "@ocp/offline-core";
import { RuViewClient } from "@ocp/tools-ruview";
import { RtlTcpClient, SpectrumProcessor } from "@ocp/tools-rtlsdr";

export interface SonarNode {
  id: number;
  lastHeard: number;
  avgSnr: number | null;
  avgRssi: number | null;
  lat?: number;
  lon?: number;
  name?: string;
}

export interface SpectrumFrame {
  centerFreq: number;
  sampleRate: number;
  fftSize: number;
  frequencies: Float32Array;
  magnitudes: Float32Array;
}

export interface OcpState {
  connected: boolean;
  transportKind?: string;
  nodeCount: number;
  nodes: SonarNode[];
  ruViewConnected: boolean;
  rtlConnected: boolean;
  rtlCenterFreq?: number;
  rtlSampleRate?: number;
  rtlHost?: string;
  rtlPort?: number;
}

export class OcpService {
  networkState = new NetworkState({ nodeTimeoutMs: 60_000 });
  ruview?: RuViewClient;
  transport: any = null;
  interval?: ReturnType<typeof setInterval>;
  lastState?: OcpState;

  rtlClient?: RtlTcpClient;
  rtlProcessor?: SpectrumProcessor;

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
    this.#stopRtl();
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

    ipcMain.handle("ocp:rtl:connect", async (_evt: IpcMainInvokeEvent, cfg: { host?: string; port?: number; centerFreq?: number; sampleRate?: number }) => {
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

      try {
        await client.connect();
      } catch (err: any) {
        return { ok: false, error: err.message };
      }

      this.rtlClient = client;
      this.rtlProcessor = processor;
      this.#emit();
      return { ok: true, host, port };
    });

    ipcMain.handle("ocp:rtl:disconnect", async () => {
      this.#stopRtl();
      this.#emit();
      return { ok: true };
    });

    ipcMain.handle("ocp:rtl:setFreq", async (_evt: IpcMainInvokeEvent, hz: number) => {
      if (!this.rtlClient) return { ok: false, error: "RTL-SDR not connected" };
      this.rtlClient.setCenterFreq(hz);
      this.rtlProcessor?.configure({ centerFreq: hz });
      this.#emit();
      return { ok: true };
    });

    ipcMain.handle("ocp:rtl:setGain", async (_evt: IpcMainInvokeEvent, { mode, value }: { mode?: "auto" | "manual"; value?: number }) => {
      if (!this.rtlClient) return { ok: false, error: "RTL-SDR not connected" };
      if (mode) this.rtlClient.setGainMode(mode === "manual");
      if (value !== undefined) this.rtlClient.setGain(Math.round(value * 10));
      return { ok: true };
    });

    ipcMain.handle("ocp:rtl:mock", async (_evt: IpcMainInvokeEvent, cfg: { centerFreq?: number; sampleRate?: number; carriers?: { freqOffset: number; amplitude: number }[] }) => {
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
    });

    ipcMain.handle("ocp:state", () => this.#state());
  }

  #stopRtl() {
    this.rtlClient?.disconnect?.();
    this.rtlClient?.destroy?.();
    this.rtlProcessor?.destroy();
    this.rtlClient = undefined;
    this.rtlProcessor = undefined;
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
      rtlConnected: this.rtlClient ? true : false,
      rtlCenterFreq: this.rtlProcessor?.centerFreq,
      rtlSampleRate: this.rtlProcessor?.sampleRate,
      rtlHost: (this.rtlClient as any)?.host,
      rtlPort: (this.rtlClient as any)?.port,
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
