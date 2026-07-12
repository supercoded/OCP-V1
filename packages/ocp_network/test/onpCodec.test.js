import test from "node:test";
import assert from "node:assert/strict";
import {
  encodeDiscoveryBeacon,
  decodeDiscoveryBeacon,
  encodeRouteUpdate,
  decodeRouteUpdate,
} from "../src/onpCodec.js";

test("round-trips a discovery beacon", () => {
  const info = { num: 12345, user: { longName: "Base" }, position: { lat: 1, lon: 2 } };
  const encoded = encodeDiscoveryBeacon(info);
  assert.ok(Buffer.isBuffer(encoded));
  assert.deepEqual(decodeDiscoveryBeacon(encoded), info);
});

test("round-trips route updates", () => {
  const routes = [{ dest: 12345, nextHop: 67890, metric: 2 }];
  const encoded = encodeRouteUpdate(routes);
  assert.deepEqual(decodeRouteUpdate(encoded), routes);
});
