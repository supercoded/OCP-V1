import test from "node:test";
import assert from "node:assert/strict";
import { FirmwareUpdater, runCommand } from "../src/firmwareUpdater.js";
import { mkdir, writeFile, rm } from "node:fs/promises";
import { existsSync } from "node:fs";
import { join } from "node:path";
import { tmpdir } from "node:os";

test("detectChipFamily identifies nRF52 boards", () => {
  const updater = new FirmwareUpdater();
  assert.equal(updater.detectChipFamily("rak4631"), "nrf52");
  assert.equal(updater.detectChipFamily("RAK4631_EINK"), "nrf52");
  assert.equal(updater.detectChipFamily("nrf52840_dk"), "nrf52");
});

test("detectChipFamily identifies ESP32 boards", () => {
  const updater = new FirmwareUpdater();
  assert.equal(updater.detectChipFamily("tbeam"), "esp32");
  assert.equal(updater.detectChipFamily("lilygo_t3s3"), "esp32");
  assert.equal(updater.detectChipFamily("heltec_v3"), "esp32");
  assert.equal(updater.detectChipFamily("rak11200"), "esp32");
});

test("resolveAssetName returns known suffixes", () => {
  const updater = new FirmwareUpdater();
  assert.equal(updater.resolveAssetName("rak4631"), "RAK4631_firmware.zip");
  assert.equal(updater.resolveAssetName("tbeam"), "TBEAM_firmware.zip");
});

test("downloadReleaseAsset caches files locally", async () => {
  const tmpDir = join(tmpdir(), `ocp-firmware-test-${Date.now()}`);
  await mkdir(tmpDir, { recursive: true });

  // Mock fetch via a custom global
  const originalFetch = global.fetch;
  const fakeBuffer = Buffer.from("fake firmware zip");
  global.fetch = async (url) => {
    assert.ok(url.includes("v2.0.0"));
    assert.ok(url.includes("TEST_firmware.zip"));
    return {
      ok: true,
      arrayBuffer: async () => fakeBuffer.buffer.slice(fakeBuffer.byteOffset, fakeBuffer.byteOffset + fakeBuffer.byteLength),
    };
  };

  try {
    const updater = new FirmwareUpdater({ cacheDir: tmpDir });
    const path = await updater.downloadReleaseAsset("v2.0.0", "TEST_firmware.zip");
    assert.ok(path.includes(tmpDir));
    assert.ok(existsSync(path));

    // Second call should be cached
    const path2 = await updater.downloadReleaseAsset("v2.0.0", "TEST_firmware.zip");
    assert.equal(path, path2);
  } finally {
    global.fetch = originalFetch;
    await rm(tmpDir, { recursive: true, force: true });
  }
});

test("flashFirmware requires port, path, and chipFamily", async () => {
  const updater = new FirmwareUpdater();
  await assert.rejects(
    () => updater.flashFirmware({}),
    /requires portName, firmwarePath, and chipFamily/
  );
});
