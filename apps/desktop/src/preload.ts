import { contextBridge, ipcRenderer } from "electron";

const ocpAPI = {
  ping: () => ipcRenderer.invoke("ocp:ping"),
  connect: (options: any) => ipcRenderer.invoke("ocp:connect", options),
  disconnect: () => ipcRenderer.invoke("ocp:disconnect"),
  getState: () => ipcRenderer.invoke("ocp:state"),
  startRuView: (cfg: { host?: string; wsPort?: number }) => ipcRenderer.invoke("ocp:ruview:start", cfg),
  stopRuView: () => ipcRenderer.invoke("ocp:ruview:stop"),
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
};

contextBridge.exposeInMainWorld("ocp", ocpAPI);

export type OcpAPI = typeof ocpAPI;
