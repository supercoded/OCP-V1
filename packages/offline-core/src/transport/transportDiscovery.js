import { TcpTransportConnection } from "./tcpTransportConnection.js";
import { SerialTransportConnection } from "./serialTransportConnection.js";
import { BleTransportConnection } from "./bleTransportConnection.js";

/**
 * Known Meshtastic BLE service UUIDs and characteristics.
 * Meshtastic uses a custom Nordic UART-style service on BLE.
 */
export const MESHTASTIC_BLE_SERVICE_UUIDS = [
  "6ba1b218-15a8-461f-bfa7-9c53b4a6bd19", // newer Meshtastic BLE service
  "0000180a-0000-1000-8000-00805f9b34fb", // optional: device info service
];

/**
 * Common USB vendor/product IDs for Meshtastic/RAK serial bridges.
 */
export const MESHTASTIC_USB_IDS = [
  { vendorId: 0x10c4, productId: 0xea60, name: "CP210x (RAK, Heltec, etc.)" },
  { vendorId: 0x1a86, productId: 0x7523, name: "CH340 (some LilyGo/TTGO)" },
  { vendorId: 0x0403, productId: 0x6001, name: "FT232 (some custom boards)" },
  { vendorId: 0x303a, productId: 0x4001, name: "ESP32-S3 native USB" },
  { vendorId: 0x303a, productId: 0x0002, name: "ESP32-S2 native USB" },
];

/**
 * Options object describing how to reach each transport kind.
 * @typedef {Object} DiscoveryOptions
 * @property {{ host: string, port: number }} [tcp]
 * @property {{ portName: string, baudRate?: number } | { scan: true }} [serial]
 * @property {{ deviceId: string } | { scan: true, serviceUuid?: string }} [ble]
 * @property {number} [timeoutMs=5000] - per-transport attempt timeout
 * @property {string[]} [preferredOrder=["tcp","serial","ble"]]
 */

/**
 * Attempt to discover and connect to a Meshtastic-compatible transport.
 * Tries each kind in preferredOrder, returning the first successful connection.
 *
 * @param {DiscoveryOptions} options
 * @returns {Promise<TransportConnection>}
 */
export async function discoverTransport(options = {}) {
  const {
    tcp,
    serial,
    ble,
    timeoutMs = 5000,
    preferredOrder = ["tcp", "serial", "ble"],
    factories = {},
  } = options;

  const TcpFactory = factories.tcp || TcpTransportConnection;
  const SerialFactory = factories.serial || SerialTransportConnection;
  const BleFactory = factories.ble || BleTransportConnection;

  const errors = [];

  for (const kind of preferredOrder) {
    if (kind === "tcp" && tcp) {
      const transport = new TcpFactory(tcp);
      try {
        await withTimeout(transport.connect(), timeoutMs, "tcp connect timeout");
        return transport;
      } catch (err) {
        errors.push({ kind: "tcp", error: err.message });
      }
    }

    if (kind === "serial" && serial) {
      try {
        const endpoint = serial.portName
          ? serial
          : await resolveSerialEndpoint(serial, timeoutMs);
        const transport = new SerialFactory(endpoint);
        await withTimeout(transport.connect(), timeoutMs, "serial connect timeout");
        return transport;
      } catch (err) {
        errors.push({ kind: "serial", error: err.message });
      }
    }

    if (kind === "ble" && ble) {
      try {
        const endpoint = ble.deviceId ? ble : await resolveBleEndpoint(ble, timeoutMs);
        const transport = new BleFactory(endpoint);
        await withTimeout(transport.connect(), timeoutMs, "ble connect timeout");
        return transport;
      } catch (err) {
        errors.push({ kind: "ble", error: err.message });
      }
    }
  }

  const summary = errors.map((e) => `${e.kind}: ${e.error}`).join("; ");
  throw new Error(`No transport discovered. ${summary}`);
}

async function withTimeout(promise, ms, message) {
  const timeout = new Promise((_, reject) => {
    setTimeout(() => reject(new Error(message)), ms);
  });
  return Promise.race([promise, timeout]);
}

async function resolveSerialEndpoint(serialOptions, timeoutMs) {
  if (serialOptions.portName) {
    return {
      portName: serialOptions.portName,
      baudRate: serialOptions.baudRate ?? 921600,
    };
  }

  if (!serialOptions.scan) {
    throw new Error("No serial portName and scan not enabled");
  }

  // Optional dynamic import so the core package doesn't hard-depend on serialport.
  let SerialPort;
  try {
    const mod = await import("serialport");
    SerialPort = mod.SerialPort;
  } catch {
    throw new Error("serialport module is not installed; cannot scan serial ports");
  }

  const ports = await SerialPort.list();
  const match = ports.find((p) =>
    MESHTASTIC_USB_IDS.some(
      (id) => id.vendorId === Number(p.vendorId) && id.productId === Number(p.productId)
    )
  );

  if (!match) {
    const available = ports.map((p) => `${p.path} (vid=${p.vendorId},pid=${p.productId})`).join(", ");
    throw new Error(`No known Meshtastic serial port found. Available: ${available || "none"}`);
  }

  return {
    portName: match.path,
    baudRate: serialOptions.baudRate ?? 921600,
  };
}

async function resolveBleEndpoint(bleOptions, timeoutMs) {
  if (bleOptions.deviceId) {
    return bleOptions;
  }

  if (!bleOptions.scan) {
    throw new Error("No BLE deviceId and scan not enabled");
  }

  // Optional dynamic import for noble.
  let noble;
  try {
    const mod = await import("@abandonware/noble");
    noble = mod.default ?? mod;
  } catch {
    throw new Error("@abandonware/noble is not installed; cannot scan BLE devices");
  }

  const targetUuid = bleOptions.serviceUuid ?? MESHTASTIC_BLE_SERVICE_UUIDS[0];

  return new Promise((resolve, reject) => {
    const timer = setTimeout(() => {
      noble.stopScanning();
      noble.removeAllListeners("discover");
      reject(new Error(`BLE scan timeout looking for service ${targetUuid}`));
    }, timeoutMs);

    noble.once("stateChange", (state) => {
      if (state === "poweredOn") {
        noble.startScanning([targetUuid], false);
      } else {
        clearTimeout(timer);
        noble.removeAllListeners("discover");
        reject(new Error(`BLE adapter state: ${state}`));
      }
    });

    noble.on("discover", (peripheral) => {
      clearTimeout(timer);
      noble.stopScanning();
      noble.removeAllListeners("discover");
      resolve({ deviceId: peripheral.id, peripheral });
    });

    // If noble is already powered on, start scanning immediately too.
    if (noble._state === "poweredOn") {
      noble.startScanning([targetUuid], false);
    }
  });
}
