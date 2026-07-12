import test from "node:test";
import assert from "node:assert/strict";
import { NetworkState } from "../src/index.js";

test("NetworkState adds a node on first packet", () => {
  const net = new NetworkState({ nodeTimeoutMs: 1000 });
  let added = null;
  net.on("nodeAdded", (n) => (added = n));

  net.onPacket({ from: 12345, rxSnr: 8, hopLimit: 3 });
  assert.equal(added?.id, 12345);
  assert.equal(added.avgSnr, 8);
  net.destroy();
});

test("NetworkState updates existing node", () => {
  const net = new NetworkState({ nodeTimeoutMs: 1000 });
  let updated = null;
  net.on("nodeUpdated", (n) => (updated = n));

  net.onPacket({ from: 12345, rxSnr: 8 });
  net.onPacket({ from: 12345, rxSnr: 4 });
  assert.equal(updated?.id, 12345);
  assert.equal(updated.avgSnr, 6);
  net.destroy();
});

test("NetworkState handles nodeInfo", () => {
  const net = new NetworkState();
  net.onNodeInfo({ num: 12345, user: { longName: "Test Node" }, snr: 7 });
  const node = net.getNode(12345);
  assert.equal(node.user.longName, "Test Node");
  assert.equal(node.snr, 7);
  net.destroy();
});

test("NetworkState prunes stale nodes", async () => {
  const net = new NetworkState({ nodeTimeoutMs: 50 });
  let lost = null;
  net.on("nodeLost", (n) => (lost = n));

  net.onPacket({ from: 12345 });
  assert.equal(net.getNodes().length, 1);

  await new Promise((r) => setTimeout(r, 120));
  assert.equal(lost?.id, 12345);
  assert.equal(net.getNodes().length, 0);
  net.destroy();
});
