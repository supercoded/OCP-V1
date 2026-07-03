import { readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { randomUUID } from "node:crypto";
import { DeliveryState } from "../protocol/models.js";

function emptyDb() {
  return {
    nodes: [],
    channels: [],
    messages: [],
    outbound: []
  };
}

export class JsonFileOfflineStore {
  constructor({ dbPath, keyCipher }) {
    this.dbPath = dbPath;
    this.keyCipher = keyCipher;
  }

  async init() {
    if (!existsSync(this.dbPath)) {
      await this.#save(emptyDb());
    }
  }

  async upsertNodes(nodes) {
    const db = await this.#load();
    const byId = new Map(db.nodes.map((n) => [n.id, n]));
    for (const node of nodes) {
      byId.set(node.id, { ...byId.get(node.id), ...node });
    }
    db.nodes = [...byId.values()];
    await this.#save(db);
  }

  async upsertChannels(channels) {
    const db = await this.#load();
    const byId = new Map(db.channels.map((c) => [c.id, c]));
    for (const channel of channels) {
      const maybeKey = channel.psk ? this.keyCipher.encrypt(channel.psk) : undefined;
      byId.set(channel.id, { ...byId.get(channel.id), ...channel, psk: maybeKey ?? channel.psk });
    }
    db.channels = [...byId.values()];
    await this.#save(db);
  }

  async appendInboundMessage(packet) {
    const db = await this.#load();
    db.messages.push({
      id: packet.id ?? randomUUID(),
      direction: "inbound",
      at: new Date().toISOString(),
      payload: packet
    });
    await this.#save(db);
  }

  async enqueueOutbound(message) {
    const db = await this.#load();
    const record = {
      id: randomUUID(),
      createdAt: new Date().toISOString(),
      ...message
    };
    db.outbound.push(record);
    await this.#save(db);
    return record;
  }

  async listRetryCandidates(maxRetries) {
    const db = await this.#load();
    return db.outbound.filter(
      (m) => (m.state === DeliveryState.QUEUED || m.state === DeliveryState.SENT) && m.retries < maxRetries
    );
  }

  async incrementRetries(id) {
    const db = await this.#load();
    db.outbound = db.outbound.map((m) => (m.id === id ? { ...m, retries: m.retries + 1 } : m));
    await this.#save(db);
  }

  async updateOutboundState(id, state) {
    const db = await this.#load();
    db.outbound = db.outbound.map((m) => (m.id === id ? { ...m, state } : m));
    await this.#save(db);
  }

  async getOutboundMessage(id) {
    const db = await this.#load();
    const message = db.outbound.find((m) => m.id === id);
    if (!message) {
      throw new Error(`Outbound message ${id} not found`);
    }
    return message;
  }

  async #load() {
    const raw = await readFile(this.dbPath, "utf8");
    return JSON.parse(raw);
  }

  async #save(db) {
    await writeFile(this.dbPath, JSON.stringify(db, null, 2), "utf8");
  }
}
