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
};

contextBridge.exposeInMainWorld("ocp", ocpAPI);

export type OcpAPI = typeof ocpAPI;
