/**
 * Serial port worker — runs under system Node (not Electron) so native
 * serialport bindings work without an Electron ABI rebuild.
 *
 * Protocol (IPC messages):
 *   { id, cmd: "list" }
 *   { id, cmd: "open", path, baudRate }
 *   { id, cmd: "write", data: number[] }
 *   { id, cmd: "read", maxBytes, timeoutMs }
 *   { id, cmd: "close" }
 *   { id, cmd: "drain" }
 */
import { SerialPort } from "serialport";

/** @type {import("serialport").SerialPort | null} */
let port = null;
/** @type {Buffer[]} */
const rxQueue = [];

function flushRx() {
  if (!rxQueue.length) return Buffer.alloc(0);
  const out = Buffer.concat(rxQueue);
  rxQueue.length = 0;
  return out;
}

function attachPort(p) {
  port = p;
  port.on("data", (chunk) => {
    rxQueue.push(Buffer.from(chunk));
  });
  port.on("error", (err) => {
    process.send?.({ event: "error", error: err.message });
  });
}

async function handle(msg) {
  const { id, cmd } = msg;
  try {
    if (cmd === "list") {
      const ports = await SerialPort.list();
      return {
        id,
        ok: true,
        ports: ports.map((p) => ({
          path: p.path,
          manufacturer: p.manufacturer || undefined,
          vendorId: p.vendorId || undefined,
          productId: p.productId || undefined,
          friendlyName: p.friendlyName || undefined,
          serialNumber: p.serialNumber || undefined,
          pnpId: p.pnpId || undefined,
        })),
      };
    }

    if (cmd === "open") {
      if (port?.isOpen) {
        await new Promise((resolve) => port.close(() => resolve()));
        port = null;
      }
      rxQueue.length = 0;
      const p = new SerialPort({
        path: msg.path,
        baudRate: msg.baudRate ?? 9600,
        dataBits: 8,
        stopBits: 1,
        parity: "none",
        autoOpen: false,
      });
      await new Promise((resolve, reject) => {
        p.open((err) => (err ? reject(err) : resolve()));
      });
      attachPort(p);
      return { id, ok: true };
    }

    if (cmd === "write") {
      if (!port?.isOpen) throw new Error("Port not open");
      const buf = Buffer.from(msg.data ?? []);
      await new Promise((resolve, reject) => {
        port.write(buf, (err) => (err ? reject(err) : resolve()));
      });
      await new Promise((resolve, reject) => {
        port.drain((err) => (err ? reject(err) : resolve()));
      });
      return { id, ok: true };
    }

    if (cmd === "read") {
      if (!port?.isOpen) throw new Error("Port not open");
      const maxBytes = msg.maxBytes ?? 256;
      const timeoutMs = msg.timeoutMs ?? 2000;
      const deadline = Date.now() + timeoutMs;
      let buf = flushRx();
      while (buf.length < maxBytes && Date.now() < deadline) {
        await new Promise((r) => setTimeout(r, 20));
        if (rxQueue.length) buf = Buffer.concat([buf, flushRx()]);
      }
      const slice = buf.subarray(0, Math.min(buf.length, maxBytes));
      const rest = buf.subarray(slice.length);
      if (rest.length) rxQueue.unshift(rest);
      return { id, ok: true, data: Array.from(slice) };
    }

    if (cmd === "close") {
      if (port) {
        await new Promise((resolve) => {
          if (!port.isOpen) return resolve();
          port.close(() => resolve());
        });
        port = null;
      }
      rxQueue.length = 0;
      return { id, ok: true };
    }

    throw new Error(`Unknown cmd: ${cmd}`);
  } catch (err) {
    return { id, ok: false, error: err?.message ?? String(err) };
  }
}

process.on("message", async (msg) => {
  const result = await handle(msg);
  process.send?.(result);
});

process.send?.({ event: "ready" });
