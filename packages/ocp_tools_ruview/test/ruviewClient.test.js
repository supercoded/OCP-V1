import test from "node:test";
import assert from "node:assert/strict";
import { RuViewClient } from "../src/ruviewClient.js";
import { WebSocketServer } from "ws";

test("RuViewClient connects and parses sensing_update frames", async () => {
  const wss = new WebSocketServer({ port: 0 });
  const port = await new Promise((resolve) => {
    wss.on("listening", () => resolve(wss.address().port));
  });

  const client = new RuViewClient({ host: "localhost", wsPort: port, reconnect: false });
  const events = [];
  client.on("sensing", (e) => events.push(e));

  client.start();

  await new Promise((resolve) => client.once("open", resolve));

  const frame = {
    type: "sensing_update",
    timestamp: 1783873709.864,
    source: "simulated",
    tick: 1,
    nodes: [
      { node_id: 1, rssi_dbm: -45, position: [1.5, 0.8, 1.2] },
    ],
  };

  wss.clients.forEach((ws) => ws.send(JSON.stringify(frame)));

  await new Promise((r) => setTimeout(r, 100));
  assert.equal(events.length, 1);
  assert.equal(events[0].nodeId, 1);
  assert.equal(events[0].x, 1.5);
  assert.equal(events[0].y, 0.8);
  assert.equal(events[0].z, 1.2);
  assert.equal(events[0].rssi, -45);
  assert.equal(events[0].source, "simulated");

  client.stop();
  await new Promise((resolve) => wss.close(() => resolve()));
});
