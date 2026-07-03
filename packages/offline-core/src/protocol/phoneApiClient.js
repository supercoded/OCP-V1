import { EventEmitter } from "node:events";
import { DeliveryState, toRadioStartConfig } from "./models.js";

/**
 * Implements a minimal PhoneAPI-like host flow:
 * - send startConfig/wantConfigId on connect
 * - receive node/channel snapshots
 * - queue outbound messages and retry until ack or max retries
 */
export class PhoneApiClient extends EventEmitter {
  constructor({ transport, store, retryIntervalMs = 3000, maxRetries = 3 }) {
    super();
    this.transport = transport;
    this.store = store;
    this.retryIntervalMs = retryIntervalMs;
    this.maxRetries = maxRetries;
    this.retryTimer = null;
    this.pendingByAckId = new Map();
  }

  async start(configId = "offline-app") {
    this.transport.on("frame", (frame) => this.#handleFromRadio(frame));
    await this.transport.connect();
    await this.transport.sendFrame(toRadioStartConfig(configId));
    this.#startRetryLoop();
  }

  async stop() {
    if (this.retryTimer) {
      clearInterval(this.retryTimer);
      this.retryTimer = null;
    }
    await this.transport.disconnect();
  }

  async queueTextMessage({ destination, channelId, text }) {
    const queued = await this.store.enqueueOutbound({
      destination,
      channelId,
      text,
      state: DeliveryState.QUEUED,
      retries: 0
    });
    await this.#sendQueuedMessage(queued);
    return queued;
  }

  async #sendQueuedMessage(message) {
    const ackId = `${message.id}:${message.retries}`;
    const frame = {
      toRadio: {
        packet: {
          ackId,
          destination: message.destination,
          channelId: message.channelId,
          text: message.text
        }
      }
    };
    await this.transport.sendFrame(frame);
    this.pendingByAckId.set(ackId, message.id);
    await this.store.updateOutboundState(message.id, DeliveryState.SENT);
    this.emit("messageState", { id: message.id, state: DeliveryState.SENT });
  }

  async #handleFromRadio(frame) {
    const from = frame?.fromRadio;
    if (!from) return;

    if (Array.isArray(from.nodes)) {
      await this.store.upsertNodes(from.nodes);
    }
    if (Array.isArray(from.channels)) {
      await this.store.upsertChannels(from.channels);
    }
    if (from.packet) {
      await this.store.appendInboundMessage(from.packet);
      this.emit("inboundMessage", from.packet);
    }
    if (from.ackId && this.pendingByAckId.has(from.ackId)) {
      const messageId = this.pendingByAckId.get(from.ackId);
      this.pendingByAckId.delete(from.ackId);
      await this.store.updateOutboundState(messageId, DeliveryState.ACKED);
      this.emit("messageState", { id: messageId, state: DeliveryState.ACKED });
    }
  }

  #startRetryLoop() {
    if (this.retryTimer) return;
    this.retryTimer = setInterval(async () => {
      const retryCandidates = await this.store.listRetryCandidates(this.maxRetries);
      for (const message of retryCandidates) {
        try {
          await this.store.incrementRetries(message.id);
          const next = await this.store.getOutboundMessage(message.id);
          await this.#sendQueuedMessage(next);
        } catch {
          await this.store.updateOutboundState(message.id, DeliveryState.FAILED);
          this.emit("messageState", { id: message.id, state: DeliveryState.FAILED });
        }
      }
    }, this.retryIntervalMs);
  }
}
