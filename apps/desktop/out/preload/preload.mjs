import { contextBridge, ipcRenderer } from "electron";
const ocpAPI = {
  ping: () => ipcRenderer.invoke("ocp:ping"),
  connect: (options) => ipcRenderer.invoke("ocp:connect", options),
  disconnect: () => ipcRenderer.invoke("ocp:disconnect"),
  getState: () => ipcRenderer.invoke("ocp:state"),
  startRuView: (cfg) => ipcRenderer.invoke("ocp:ruview:start", cfg),
  stopRuView: () => ipcRenderer.invoke("ocp:ruview:stop"),
  onState: (cb) => {
    const listener = (_evt, state) => cb(state);
    ipcRenderer.on("ocp:state:update", listener);
    return () => ipcRenderer.off("ocp:state:update", listener);
  },
  onRuViewSensing: (cb) => {
    const listener = (_evt, sensing) => cb(sensing);
    ipcRenderer.on("ocp:ruview:sensing", listener);
    return () => ipcRenderer.off("ocp:ruview:sensing", listener);
  },
  onRuViewError: (cb) => {
    const listener = (_evt, error) => cb(error);
    ipcRenderer.on("ocp:ruview:error", listener);
    return () => ipcRenderer.off("ocp:ruview:error", listener);
  }
};
contextBridge.exposeInMainWorld("ocp", ocpAPI);
