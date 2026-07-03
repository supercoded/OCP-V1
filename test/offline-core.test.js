import test from "node:test";
import assert from "node:assert/strict";
import { mkdtemp, readFile } from "node:fs/promises";
import { join } from "node:path";
import { tmpdir } from "node:os";
import {
  BleTransportConnection,
  JsonFileOfflineStore,
  LocalKeyCipher,
  PhoneApiClient
} from "../packages/offline-core/src/index.js";

test("transport adapter connects and sends", async () => {
  let connectCalled = false;
  let sendCalled = false;
  const transport = new BleTransportConnection("radio-1", {
    async connect() {
      connectCalled = true;
    },
    async sendFrame() {
      sendCalled = true;
    }
  });

  await transport.connect();
  await transport.sendFrame({ hello: "world" });

  assert.equal(connectCalled, true);
  assert.equal(sendCalled, true);
});

test("offline store encrypts channel PSK", async () => {
  const dir = await mkdtemp(join(tmpdir(), "ocp-store-"));
  const dbPath = join(dir, "offline-db.json");
  const store = new JsonFileOfflineStore({
    dbPath,
    keyCipher: new LocalKeyCipher("test-passphrase")
  });
  await store.init();
  await store.upsertChannels([{ id: "chan-1", psk: "my-plaintext-key" }]);

  const raw = await readFile(dbPath, "utf8");
  assert.equal(raw.includes("my-plaintext-key"), false);
});

test("protocol client handles ack flow", async () => {
  const dir = await mkdtemp(join(tmpdir(), "ocp-protocol-"));
  const dbPath = join(dir, "offline-db.json");
  const store = new JsonFileOfflineStore({
    dbPath,
    keyCipher: new LocalKeyCipher("test-passphrase")
  });
  await store.init();

  const sentFrames = [];
  const transport = new BleTransportConnection("radio-1", {
    async connect() {},
    async sendFrame(frame) {
      sentFrames.push(frame);
    }
  });

  const client = new PhoneApiClient({
    transport,
    store,
    retryIntervalMs: 10000
  });

  await client.start("cfg-1");
  const queued = await client.queueTextMessage({
    destination: "node-b",
    channelId: "chan-1",
    text: "hello"
  });

  const outboundBeforeAck = await store.getOutboundMessage(queued.id);
  assert.equal(outboundBeforeAck.state, "sent");

  transport.emitIncomingFrame({
    fromRadio: { ackId: `${queued.id}:0` }
  });

  await new Promise((resolve) => setTimeout(resolve, 10));
  const outboundAfterAck = await store.getOutboundMessage(queued.id);
  assert.equal(outboundAfterAck.state, "acked");
  assert.ok(sentFrames.length >= 2);

  await client.stop();
});
