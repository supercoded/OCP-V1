import { defineConfig, externalizeDepsPlugin } from "electron-vite";
import react from "@vitejs/plugin-react";
import { resolve } from "node:path";

export default defineConfig({
  main: {
    plugins: [externalizeDepsPlugin()],
    build: {
      rollupOptions: {
        external: [
          "serialport",
          "@abandonware/noble",
          "ws",
          "kissfft-js",
          "@ocp/bridge-baofeng",
          "@ocp/bridge-meshtastic",
          "@ocp/plugin-api",
          "@ocp/plugin-example",
        ],
      },
      lib: {
        entry: resolve("src/main.ts"),
        formats: ["es"],
        fileName: () => "main.js",
      },
    },
  },
  preload: {
    plugins: [externalizeDepsPlugin()],
    build: {
      lib: {
        entry: resolve("src/preload.ts"),
        formats: ["es"],
        fileName: () => "preload.js",
      },
    },
  },
  renderer: {
    plugins: [react()],
    root: resolve("src/renderer"),
    build: {
      rollupOptions: {
        input: resolve("src/renderer/index.html"),
      },
      outDir: resolve("out/renderer"),
    },
  },
});
