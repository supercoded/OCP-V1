import { test } from "node:test";
import { strict as assert } from "node:assert";
import { scoreProgrammingCable, pickBestProgrammingPort } from "../src/serialPorts.js";

test("scoreProgrammingCable prefers CH340 adapters", () => {
  const score = scoreProgrammingCable({
    path: "COM5",
    manufacturer: "wch.cn USB2.0-Serial",
    vendorId: "1A86",
    productId: "7523",
  });
  assert.ok(score >= 10);
});

test("scoreProgrammingCable deprioritizes bluetooth", () => {
  const score = scoreProgrammingCable({
    path: "COM12",
    manufacturer: "Standard Serial over Bluetooth link",
    friendlyName: "Bluetooth",
  });
  assert.ok(score < 0);
});

test("pickBestProgrammingPort chooses USB-serial over bluetooth", () => {
  const best = pickBestProgrammingPort([
    { path: "COM12", manufacturer: "Bluetooth", friendlyName: "Standard Serial over Bluetooth link" },
    { path: "COM7", manufacturer: "Prolific", vendorId: "067B", productId: "2303" },
  ]);
  assert.equal(best?.path, "COM7");
});
