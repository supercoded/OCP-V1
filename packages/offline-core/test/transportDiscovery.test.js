import test from "node:test";
import assert from "node:assert/strict";
import {
  discoverTransport,
  MESHTASTIC_USB_IDS,
  MESHTASTIC_BLE_SERVICE_UUIDS,
} from "../src/transport/transportDiscovery.js";
import { TcpTransportConnection } from "../src/transport/tcpTransportConnection.js";
import { SerialTransportConnection } from "../src/transport/serialTransportConnection.js";
import { BleTransportConnection } from "../src/transport/bleTransportConnection.js";

test("discovers TCP transport when it connects", async () => {
  const transport = await discoverTransport({
    preferredOrder: ["tcp"],
    tcp: { host: "127.0.0.1", port: 4403 },
    timeoutMs: 100,
  });
  assert.equal(transport instanceof TcpTransportConnection, true);
  assert.equal(transport.connected, true);
});

test("discovers serial transport when TCP fails", async () => {
  class FailingTcp extends TcpTransportConnection {
    async connect() {
      throw new Error("tcp down");
    }
  }
  const transport = await discoverTransport({
    preferredOrder: ["tcp", "serial"],
    tcp: { host: "192.0.2.1", port: 4403 },
    serial: { portName: "/dev/ttyUSB0", baudRate: 921600 },
    timeoutMs: 100,
    factories: { tcp: FailingTcp },
  });
  assert.equal(transport instanceof SerialTransportConnection, true);
  assert.equal(transport.endpoint.portName, "/dev/ttyUSB0");
  assert.equal(transport.endpoint.baudRate, 921600);
});

test("discovers BLE transport when TCP/serial fail", async () => {
  class FailingTcp extends TcpTransportConnection {
    async connect() {
      throw new Error("tcp down");
    }
  }
  class FailingSerial extends SerialTransportConnection {
    async connect() {
      throw new Error("serial down");
    }
  }

  const transport = await discoverTransport({
    preferredOrder: ["tcp", "serial", "ble"],
    tcp: { host: "192.0.2.1", port: 4403 },
    serial: { portName: "/dev/none" },
    ble: { deviceId: "aa:bb:cc:dd:ee:ff" },
    timeoutMs: 100,
    factories: { tcp: FailingTcp, serial: FailingSerial },
  });
  assert.equal(transport instanceof BleTransportConnection, true);
  assert.equal(transport.endpoint.deviceId, "aa:bb:cc:dd:ee:ff");
});

test("throws when no transport is configured", async () => {
  await assert.rejects(
    () => discoverTransport({ preferredOrder: ["tcp", "serial", "ble"], timeoutMs: 50 }),
    /No transport discovered/
  );
});

test("exports known USB IDs and BLE UUIDs", () => {
  assert.ok(MESHTASTIC_USB_IDS.length > 0);
  assert.ok(MESHTASTIC_BLE_SERVICE_UUIDS.length > 0);
});
