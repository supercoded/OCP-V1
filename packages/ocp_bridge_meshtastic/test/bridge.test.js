import { test } from "node:test";
import { strict as assert } from "node:assert";

test("Bridge components can be imported", async () => {
  // This test just verifies that the modules can be imported without syntax errors
  const module = await import("../src/index.js");
  assert.ok(module.MeshtasticCodec);
  assert.ok(module.MeshtasticTransport);
});

test("MeshtasticCodec can be instantiated", async () => {
  const { MeshtasticCodec } = await import("../src/meshtasticCodec.js");
  
  // This should not throw an error even if protobufs fail to load
  const codec = new MeshtasticCodec();
  assert.ok(codec);
  // The codec properties may be null if protobufs failed to load, but the object should exist
});

test("MeshtasticTransport can be instantiated", async () => {
  const { MeshtasticTransport } = await import("../src/meshtasticTransport.js");
  
  const endpoint = {
    type: "tcp",
    host: "localhost",
    port: 4403
  };
  
  // This should not throw an error
  const transport = new MeshtasticTransport(endpoint);
  assert.equal(transport.kind, "meshtastic");
  assert.equal(transport.endpoint, endpoint);
  assert.equal(transport.connected, false);
});