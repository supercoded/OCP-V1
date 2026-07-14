import { contextBridge, ipcRenderer } from "electron";

export interface SpectrumFrame {
  centerFreq: number;
  sampleRate: number;
  fftSize: number;
  frequencies: Float32Array;
  magnitudes: Float32Array;
}

const ocpAPI = {
  ping: () => ipcRenderer.invoke("ocp:ping"),
  connect: (options: any) => ipcRenderer.invoke("ocp:connect", options),
  disconnect: () => ipcRenderer.invoke("ocp:disconnect"),
  getState: () => ipcRenderer.invoke("ocp:state"),

  startRuView: (cfg: { host?: string; wsPort?: number }) => ipcRenderer.invoke("ocp:ruview:start", cfg),
  stopRuView: () => ipcRenderer.invoke("ocp:ruview:stop"),

  connectRtl: (cfg: { host?: string; port?: number; centerFreq?: number; sampleRate?: number }) =>
    ipcRenderer.invoke("ocp:rtl:connect", cfg),
  disconnectRtl: () => ipcRenderer.invoke("ocp:rtl:disconnect"),
  setRtlFreq: (hz: number) => ipcRenderer.invoke("ocp:rtl:setFreq", hz),
  setRtlGain: (gain: { mode?: "auto" | "manual"; value?: number }) => ipcRenderer.invoke("ocp:rtl:setGain", gain),
  startRtlMock: (cfg?: { centerFreq?: number; sampleRate?: number; carriers?: { freqOffset: number; amplitude: number }[] }) =>
    ipcRenderer.invoke("ocp:rtl:mock", cfg ?? {}),

  // RTL-SDR Recording
  startRtlRecording: (filename?: string) => ipcRenderer.invoke("ocp:rtl:startRecording", filename),
  stopRtlRecording: () => ipcRenderer.invoke("ocp:rtl:stopRecording"),
  getRtlRecordingStatus: () => ipcRenderer.invoke("ocp:rtl:recordingStatus"),

  // Map server control
  startMap: (filePath: string) => ipcRenderer.invoke("ocp:map:start", filePath),
  stopMap: () => ipcRenderer.invoke("ocp:map:stop"),
  openFileDialog: (opts: { title?: string; filters?: { name: string; extensions: string[] }[]; properties?: string[] }) =>
    ipcRenderer.invoke("ocp:dialog:openFile", opts),

  onState: (cb: (state: any) => void) => {
    const listener = (_evt: Electron.IpcRendererEvent, state: any) => cb(state);
    ipcRenderer.on("ocp:state:update", listener);
    return () => ipcRenderer.off("ocp:state:update", listener);
  },
  onRuViewSensing: (cb: (sensing: any) => void) => {
    const listener = (_evt: Electron.IpcRendererEvent, sensing: any) => cb(sensing);
    ipcRenderer.on("ocp:ruview:sensing", listener);
    return () => ipcRenderer.off("ocp:ruview:sensing", listener);
  },
  onRuViewError: (cb: (error: string) => void) => {
    const listener = (_evt: Electron.IpcRendererEvent, error: string) => cb(error);
    ipcRenderer.on("ocp:ruview:error", listener);
    return () => ipcRenderer.off("ocp:ruview:error", listener);
  },
  onRtlSpectrum: (cb: (frame: SpectrumFrame) => void) => {
    const listener = (_evt: Electron.IpcRendererEvent, frame: SpectrumFrame) => cb(frame);
    ipcRenderer.on("ocp:rtl:spectrum", listener);
    return () => ipcRenderer.off("ocp:rtl:spectrum", listener);
  },
  onRtlError: (cb: (error: string) => void) => {
    const listener = (_evt: Electron.IpcRendererEvent, error: string) => cb(error);
    ipcRenderer.on("ocp:rtl:error", listener);
    return () => ipcRenderer.off("ocp:rtl:error", listener);
  },
  onRtlRecordingStarted: (cb: (info: any) => void) => {
    const listener = (_evt: Electron.IpcRendererEvent, info: any) => cb(info);
    ipcRenderer.on("ocp:rtl:recording:started", listener);
    return () => ipcRenderer.off("ocp:rtl:recording:started", listener);
  },
  onRtlRecordingStopped: (cb: (info: any) => void) => {
    const listener = (_evt: Electron.IpcRendererEvent, info: any) => cb(info);
    ipcRenderer.on("ocp:rtl:recording:stopped", listener);
    return () => ipcRenderer.off("ocp:rtl:recording:stopped", listener);
  },

  // Baofeng IPC APIs
  baofengConnect: (portName: string) => ipcRenderer.invoke("baofeng:connect", portName),
  baofengDisconnect: () => ipcRenderer.invoke("baofeng:disconnect"),
  baofengReadChannels: () => ipcRenderer.invoke("baofeng:readChannels"),
  baofengWriteChannels: (channels: any[]) => ipcRenderer.invoke("baofeng:writeChannels", channels),
  onBaofengProgress: (cb: (info: { current: number; total: number; phase: string }) => void) => {
    const listener = (_evt: Electron.IpcRendererEvent, info: any) => cb(info);
    ipcRenderer.on("baofeng:progress", listener);
    return () => ipcRenderer.off("baofeng:progress", listener);
  },
  // Messaging APIs
  sendMessage: (params: { text: string; channel?: number; destinationNodeId?: number }) =>
    ipcRenderer.invoke("ocp:message:send", params),
  onMessageReceived: (cb: (msg: any) => void) => {
    const listener = (_evt: Electron.IpcRendererEvent, msg: any) => cb(msg);
    ipcRenderer.on("ocp:message:received", listener);
    // Return a cleanup function
    return () => ipcRenderer.off("ocp:message:received", listener);
  },
  getMessageHistory: () => ipcRenderer.invoke("ocp:message:getHistory"),

  // Plugins (Phase 7)
  listPlugins: () => ipcRenderer.invoke("ocp:plugins:list"),
  activatePlugin: (id: string) => ipcRenderer.invoke("ocp:plugins:activate", id),
  deactivatePlugin: (id: string) => ipcRenderer.invoke("ocp:plugins:deactivate", id),
  getPluginStatus: () => ipcRenderer.invoke("ocp:plugins:status"),

  // Security (Phase 8)
  securityStatus: () => ipcRenderer.invoke("ocp:security:status"),
  setPin: (pin: string) => ipcRenderer.invoke("ocp:security:setPin", pin),
  unlock: (pin: string) => ipcRenderer.invoke("ocp:security:unlock", pin),
  lock: () => ipcRenderer.invoke("ocp:security:lock"),
  changePin: (params: { currentPin: string; newPin: string }) =>
    ipcRenderer.invoke("ocp:security:changePin", params),
  clearPin: (pin: string) => ipcRenderer.invoke("ocp:security:clearPin", pin),
};

contextBridge.exposeInMainWorld("ocp", ocpAPI);

export type OcpAPI = typeof ocpAPI;
