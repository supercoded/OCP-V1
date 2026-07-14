import { readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { randomUUID } from "node:crypto";
import { DeliveryState } from "../protocol/models.js";

function emptyDb() {
  return {
    nodes: [],
    channels: [],
    messages: [],
    outbound: [],
    chatHistory: [],
  };
}

const ENC_MAGIC = "OCPENC1";

/**
 * JSON offline store. With `encryptAtRest: true` and a keyCipher, the whole
 * database file is stored as an AES-GCM envelope (not plaintext JSON).
 */
export class JsonFileOfflineStore {
  /**
   * @param {{ dbPath: string, keyCipher?: import('./localKeyCipher.js').LocalKeyCipher, encryptAtRest?: boolean }} opts
   */
  constructor({ dbPath, keyCipher, encryptAtRest = false }) {
    this.dbPath = dbPath;
    this.keyCipher = keyCipher;
    this.encryptAtRest = !!encryptAtRest;
  }

  /** Swap the active cipher (e.g. after PIN unlock). Pass null to clear. */
  setKeyCipher(keyCipher) {
    this.keyCipher = keyCipher ?? null;
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
      const maybeKey =
        channel.psk && this.keyCipher ? this.keyCipher.encrypt(channel.psk) : undefined;
      byId.set(channel.id, {
        ...byId.get(channel.id),
        ...channel,
        psk: maybeKey ?? channel.psk,
      });
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
      payload: packet,
    });
    await this.#save(db);
  }

  async enqueueOutbound(message) {
    const db = await this.#load();
    const record = {
      id: randomUUID(),
      createdAt: new Date().toISOString(),
      ...message,
    };
    db.outbound.push(record);
    await this.#save(db);
    return record;
  }

  async listRetryCandidates(maxRetries) {
    const db = await this.#load();
    return db.outbound.filter(
      (m) =>
        (m.state === DeliveryState.QUEUED || m.state === DeliveryState.SENT) &&
        m.retries < maxRetries
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

  /**
   * Re-encrypt an existing at-rest DB from oldCipher to newCipher.
   * @param {import('./localKeyCipher.js').LocalKeyCipher} oldCipher
   * @param {import('./localKeyCipher.js').LocalKeyCipher} newCipher
   */
  async rewrap(oldCipher, newCipher) {
    this.encryptAtRest = true;
    if (!existsSync(this.dbPath)) {
      this.keyCipher = newCipher;
      await this.#save(emptyDb());
      return;
    }
    this.keyCipher = oldCipher;
    const db = await this.#load();
    this.keyCipher = newCipher;
    await this.#save(db);
  }

  /** Persist UI chat history (capped). */
  async saveChatHistory(messages, max = 500) {
    const db = await this.#load();
    db.chatHistory = Array.isArray(messages) ? messages.slice(-max) : [];
    await this.#save(db);
  }

  async loadChatHistory() {
    if (!existsSync(this.dbPath)) return [];
    const db = await this.#load();
    return Array.isArray(db.chatHistory) ? db.chatHistory : [];
  }

  async #load() {
    const raw = await readFile(this.dbPath, "utf8");
    if (raw.startsWith(ENC_MAGIC)) {
      if (!this.keyCipher) {
        throw new Error("Encrypted database requires unlock (key cipher missing)");
      }
      const b64 = raw.slice(ENC_MAGIC.length).trim();
      const json = this.keyCipher.decrypt(b64);
      return JSON.parse(json);
    }
    return JSON.parse(raw);
  }

  async #save(db) {
    const json = JSON.stringify(db, null, 2);
    if (this.encryptAtRest) {
      if (!this.keyCipher) {
        throw new Error("encryptAtRest requires a keyCipher");
      }
      const payload = this.keyCipher.encrypt(json);
      await writeFile(this.dbPath, `${ENC_MAGIC}\n${payload}\n`, "utf8");
      return;
    }
    await writeFile(this.dbPath, json, "utf8");
  }
}
