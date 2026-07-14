import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, readFile } from "node:fs/promises";
import { join } from "node:path";
import { tmpdir } from "node:os";
import {
  LocalKeyCipher,
  PinVault,
  JsonFileOfflineStore,
  crc32,
  appendCrc32,
  verifyCrc32,
  stripAndVerifyCrc32,
} from "../src/index.js";

test("LocalKeyCipher round-trip with random salt", () => {
  const salt = Buffer.from("0123456789abcdef");
  const cipher = new LocalKeyCipher("secret-pin", salt);
  const enc = cipher.encrypt("hello vault");
  assert.equal(cipher.decrypt(enc), "hello vault");
});

test("PinVault set/unlock/lock/clear", async () => {
  const dir = await mkdtemp(join(tmpdir(), "ocp-pin-"));
  const vault = new PinVault(join(dir, "vault.json"));
  assert.equal(await vault.isConfigured(), false);

  await vault.setPin("1234");
  assert.equal(await vault.isConfigured(), true);
  assert.equal(vault.isUnlocked, true);

  vault.lock();
  assert.equal(vault.isUnlocked, false);

  await vault.unlock("1234");
  assert.equal(vault.isUnlocked, true);

  await assert.rejects(() => vault.unlock("9999"), /Incorrect PIN/);

  await assert.rejects(() => vault.setPin("5678"), /already configured/);

  await vault.clearPin();
  assert.equal(await vault.isConfigured(), false);
});

test("changePin rewraps encrypted store", async () => {
  const dir = await mkdtemp(join(tmpdir(), "ocp-rewrap-"));
  const vault = new PinVault(join(dir, "vault.json"));
  const dbPath = join(dir, "offline-db.json");
  await vault.setPin("1111");
  const store = new JsonFileOfflineStore({
    dbPath,
    keyCipher: vault.cipher,
    encryptAtRest: true,
  });
  await store.init();
  await store.saveChatHistory([{ id: 1, text: "secret-chat" }]);

  const { oldCipher, newCipher } = await vault.changePin("1111", "2222");
  await store.rewrap(oldCipher, newCipher);

  const reopened = new JsonFileOfflineStore({
    dbPath,
    keyCipher: newCipher,
    encryptAtRest: true,
  });
  const hist = await reopened.loadChatHistory();
  assert.equal(hist[0].text, "secret-chat");

  // Old key must fail
  const stale = new JsonFileOfflineStore({
    dbPath,
    keyCipher: oldCipher,
    encryptAtRest: true,
  });
  await assert.rejects(() => stale.loadChatHistory());
});

test("encrypted at-rest store hides plaintext DB", async () => {
  const dir = await mkdtemp(join(tmpdir(), "ocp-enc-"));
  const dbPath = join(dir, "offline-db.json");
  const cipher = new LocalKeyCipher("pin-secret", Buffer.alloc(16, 7));
  const store = new JsonFileOfflineStore({
    dbPath,
    keyCipher: cipher,
    encryptAtRest: true,
  });
  await store.init();
  await store.upsertChannels([{ id: "chan-1", psk: "secret-psk-value" }]);

  const raw = await readFile(dbPath, "utf8");
  assert.ok(raw.startsWith("OCPENC1"));
  assert.equal(raw.includes("secret-psk-value"), false);
  assert.equal(raw.includes('"channels"'), false);

  // Reload and decrypt
  const store2 = new JsonFileOfflineStore({
    dbPath,
    keyCipher: cipher,
    encryptAtRest: true,
  });
  await store2.upsertNodes([{ id: 1, name: "n1" }]);
  const raw2 = await readFile(dbPath, "utf8");
  assert.ok(raw2.startsWith("OCPENC1"));
});

test("crc32 append and verify", () => {
  const body = Buffer.from("meshtastic-frame");
  const withCrc = appendCrc32(body);
  assert.equal(verifyCrc32(withCrc), true);
  assert.equal(stripAndVerifyCrc32(withCrc).ok, true);

  withCrc[0] ^= 0xff;
  assert.equal(verifyCrc32(withCrc), false);
  assert.equal(crc32(body) >>> 0, crc32(Buffer.from("meshtastic-frame")) >>> 0);
});
