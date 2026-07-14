/**
 * Host for the system-Node serial bridge worker.
 * Used from Electron main so @serialport/bindings-cpp need not match Electron's ABI.
 */
import { fork } from "node:child_process";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const __dirname = dirname(fileURLToPath(import.meta.url));
const workerFile = resolve(__dirname, "serialBridgeWorker.js");

/** @type {import("node:child_process").ChildProcess | null} */
let child = null;
let seq = 1;
/** @type {Map<number, { resolve: Function, reject: Function }>} */
const pending = new Map();

function systemNodePath() {
  if (process.env.npm_node_execpath && !/electron/i.test(process.env.npm_node_execpath)) {
    return process.env.npm_node_execpath;
  }
  return process.platform === "win32" ? "node.exe" : "node";
}

function ensureChild() {
  if (child && !child.killed && child.connected) return child;

  child = fork(workerFile, [], {
    execPath: systemNodePath(),
    stdio: ["pipe", "pipe", "pipe", "ipc"],
    env: { ...process.env },
  });

  child.on("message", (msg) => {
    if (msg?.event === "ready") return;
    if (msg?.event === "error") {
      console.warn("[serial-bridge]", msg.error);
      return;
    }
    const waiter = pending.get(msg.id);
    if (!waiter) return;
    pending.delete(msg.id);
    if (msg.ok) waiter.resolve(msg);
    else waiter.reject(new Error(msg.error || "serial bridge error"));
  });

  child.on("exit", () => {
    child = null;
    for (const [, waiter] of pending) {
      waiter.reject(new Error("Serial bridge exited"));
    }
    pending.clear();
  });

  child.on("error", (err) => {
    console.warn("[serial-bridge] process error:", err.message);
  });

  return child;
}

function request(payload, timeoutMs = 15000) {
  const proc = ensureChild();
  const id = seq++;
  return new Promise((resolvePromise, reject) => {
    const timer = setTimeout(() => {
      pending.delete(id);
      reject(new Error(`Serial bridge timeout (${payload.cmd})`));
    }, timeoutMs);
    pending.set(id, {
      resolve: (v) => {
        clearTimeout(timer);
        resolvePromise(v);
      },
      reject: (e) => {
        clearTimeout(timer);
        reject(e);
      },
    });
    proc.send({ ...payload, id });
  });
}

export async function bridgeListPorts() {
  const res = await request({ cmd: "list" });
  return res.ports ?? [];
}

export async function bridgeOpen(path, baudRate = 9600) {
  await request({ cmd: "open", path, baudRate });
}

export async function bridgeWrite(data) {
  const arr = data instanceof Uint8Array ? Array.from(data) : Array.from(Buffer.from(data));
  await request({ cmd: "write", data: arr });
}

export async function bridgeRead(maxBytes, timeoutMs) {
  const res = await request({ cmd: "read", maxBytes, timeoutMs }, (timeoutMs ?? 2000) + 5000);
  return Buffer.from(res.data ?? []);
}

export async function bridgeClose() {
  try {
    await request({ cmd: "close" }, 5000);
  } catch {
    // ignore
  }
}

export function shouldUseSerialBridge() {
  return Boolean(process.versions?.electron);
}

export async function listSerialPortsDirectOrBridge() {
  if (!shouldUseSerialBridge()) {
    try {
      const mod = await import("serialport");
      const ports = await mod.SerialPort.list();
      return ports.map((p) => ({
        path: p.path,
        manufacturer: p.manufacturer || undefined,
        vendorId: p.vendorId || undefined,
        productId: p.productId || undefined,
        friendlyName: p.friendlyName || undefined,
        serialNumber: p.serialNumber || undefined,
        pnpId: p.pnpId || undefined,
      }));
    } catch {
      // fall through to bridge
    }
  }
  return bridgeListPorts();
}

export function createBridgeIo() {
  return {
    async open({ portName, baudRate }) {
      await bridgeOpen(portName, baudRate);
    },
    async write(data) {
      await bridgeWrite(data);
    },
    async read(maxBytes, timeoutMs) {
      return bridgeRead(maxBytes, timeoutMs);
    },
    async close() {
      await bridgeClose();
    },
  };
}
