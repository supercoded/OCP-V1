import { app, BrowserWindow, ipcMain, dialog } from "electron";
import path from "node:path";
import { fileURLToPath } from "node:url";
import { OcpService } from "./main/services/ocpService.js";

const __dirname = path.dirname(fileURLToPath(import.meta.url));

let ocpService: OcpService | null = null;

async function createWindow() {
  const win = new BrowserWindow({
    width: 1280,
    height: 800,
    minWidth: 900,
    minHeight: 600,
    title: "OCP-V1",
    darkTheme: true,
    backgroundColor: "#111111",
    icon: path.join(__dirname, "../build/icon.png"),
    webPreferences: {
      preload: path.join(__dirname, "../preload/preload.js"),
      contextIsolation: true,
      nodeIntegration: false,
      sandbox: false,
    },
  });

  if (process.env.VITE_DEV_SERVER_URL) {
    await win.loadURL(process.env.VITE_DEV_SERVER_URL);
    win.webContents.openDevTools();
  } else {
    await win.loadFile(path.join(__dirname, "../renderer/index.html"));
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

// IPC handlers for main-process APIs will go here.
ipcMain.handle("ocp:ping", () => "pong");

// File dialog for loading map tiles
ipcMain.handle(
  "ocp:dialog:openFile",
  async (_evt, opts: { title?: string; filters?: { name: string; extensions: string[] }[]; properties?: string[] }) => {
    const result = await dialog.showOpenDialog({
      title: opts?.title || "Open Map Tiles",
      filters: opts?.filters || [{ name: "Map Tiles", extensions: ["pmtiles", "mbtiles", "mvt"] }],
      properties: opts?.properties || ["openFile"],
    });
    if (result.canceled || result.filePaths.length === 0) {
      return { ok: false, canceled: true };
    }
    return { ok: true, filePath: result.filePaths[0] };
  }
);
