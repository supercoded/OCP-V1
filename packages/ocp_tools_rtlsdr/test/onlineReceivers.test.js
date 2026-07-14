import { test } from "node:test";
import assert from "node:assert/strict";
import {
  CURATED_ONLINE_RECEIVERS,
  mergeReceiverFavorites,
  filterReceivers,
  resolveListenUrl,
} from "../src/onlineReceivers.js";

test("curated list includes N8MDP and directories", () => {
  const ids = CURATED_ONLINE_RECEIVERS.map((r) => r.id);
  assert.ok(ids.includes("n8mdp-websdr"));
  assert.ok(ids.includes("receiverbook"));
  assert.ok(ids.includes("twente-websdr"));
});

test("mergeReceiverFavorites marks favorites", () => {
  const merged = mergeReceiverFavorites(CURATED_ONLINE_RECEIVERS, ["n8mdp-websdr"]);
  const n8 = merged.find((r) => r.id === "n8mdp-websdr");
  assert.equal(n8?.favorite, true);
  assert.equal(merged.find((r) => r.id === "twente-websdr")?.favorite, false);
});

test("filterReceivers by type and query", () => {
  const merged = mergeReceiverFavorites(CURATED_ONLINE_RECEIVERS, []);
  const websdr = filterReceivers(merged, { type: "websdr" });
  assert.ok(websdr.every((r) => r.type === "websdr"));
  const ohio = filterReceivers(merged, { query: "ohio" });
  assert.equal(ohio.length, 1);
  assert.equal(ohio[0].id, "n8mdp-websdr");
});

test("resolveListenUrl prefers mobile URL", () => {
  const n8 = CURATED_ONLINE_RECEIVERS.find((r) => r.id === "n8mdp-websdr");
  assert.equal(resolveListenUrl(n8, { mobile: true }), "http://n8mdp.ddns.net:8904/m.html");
  assert.equal(resolveListenUrl(n8), "http://n8mdp.ddns.net:8904/");
});
