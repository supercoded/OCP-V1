import { listSerialPortsDirectOrBridge } from "./serialBridge.js";

/** USB-serial chip patterns common on Baofeng programming cables */
const CABLE_HINTS = [
  "ch340",
  "ch341",
  "wch",
  "prolific",
  "pl2303",
  "cp210",
  "silicon labs",
  "ftdi",
  "usb-serial",
  "usb serial",
  "usbserial",
  "qin heng",
];

/**
 * @typedef {{ path: string, manufacturer?: string, vendorId?: string, productId?: string, friendlyName?: string, serialNumber?: string, pnpId?: string }} SerialPortInfo
 */

/**
 * List OS serial ports via serialport (Node) or Electron serial bridge.
 * @returns {Promise<SerialPortInfo[]>}
 */
export async function listSerialPorts() {
  return listSerialPortsDirectOrBridge();
}

/**
 * Score how likely a port is a Baofeng/USB-serial programming cable.
 * Higher = more likely. Bluetooth / modem-style ports score low or negative.
 * @param {SerialPortInfo} port
 * @returns {number}
 */
export function scoreProgrammingCable(port) {
  const hay = [
    port.manufacturer,
    port.friendlyName,
    port.pnpId,
    port.path,
  ]
    .filter(Boolean)
    .join(" ")
    .toLowerCase();

  if (/bluetooth|ble|bth|modem|com0com|vpn|virtual/i.test(hay)) return -10;

  let score = 0;
  for (const hint of CABLE_HINTS) {
    if (hay.includes(hint)) score += 10;
  }
  // Common CH340 VID 1A86
  if ((port.vendorId || "").toLowerCase() === "1a86") score += 15;
  // Prolific VID 067B
  if ((port.vendorId || "").toLowerCase() === "067b") score += 15;
  // Silicon Labs VID 10C4
  if ((port.vendorId || "").toLowerCase() === "10c4") score += 12;
  // FTDI VID 0403
  if ((port.vendorId || "").toLowerCase() === "0403") score += 10;

  // Prefer COM* / ttyUSB* / ttyACM* style paths slightly if no other signals
  if (/^COM\d+$/i.test(port.path) || /tty(USB|ACM)/i.test(port.path)) {
    score += 1;
  }

  return score;
}

/**
 * Pick the best programming-cable candidate from a port list.
 * @param {SerialPortInfo[]} ports
 * @returns {SerialPortInfo | null}
 */
export function pickBestProgrammingPort(ports) {
  if (!ports?.length) return null;
  let best = null;
  let bestScore = 0;
  for (const p of ports) {
    const s = scoreProgrammingCable(p);
    if (s > bestScore) {
      bestScore = s;
      best = p;
    }
  }
  // Require at least a hint, or sole COM/ttyUSB when only one real candidate
  if (best && bestScore >= 10) return best;
  const real = ports.filter((p) => scoreProgrammingCable(p) >= 0);
  if (real.length === 1) return real[0];
  return bestScore > 0 ? best : null;
}
