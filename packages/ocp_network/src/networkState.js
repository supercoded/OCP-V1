import { EventEmitter } from "node:events";

/**
 * Represents a single node's runtime information.
 */
class NodeInfo {
  constructor(id, info = {}) {
    this.id = id; // numeric nodeId / nodeNum
    this.lastHeard = Date.now();
    this.rxSnr = [];
    this.rxRssi = [];
    this.hopLimits = [];
    Object.assign(this, info);
  }

  update(packet) {
    const now = Date.now();
    this.lastHeard = now;
    if (typeof packet.rxSnr === "number") this.rxSnr.push(packet.rxSnr);
    if (typeof packet.rxRssi === "number") this.rxRssi.push(packet.rxRssi);
    if (typeof packet.hopLimit === "number") this.hopLimits.push(packet.hopLimit);
  }

  // Moving average of SNR over last 10 samples
  get avgSnr() {
    const arr = this.rxSnr.slice(-10);
    if (!arr.length) return null;
    return arr.reduce((a, b) => a + b, 0) / arr.length;
  }
}

/**
 * NetworkState tracks all known nodes, their last‑heard timestamps, and simple
 * link‑quality statistics. It emits events that higher‑level code can subscribe
 * to for UI updates or routing decisions.
 *
 * Replay protection: packets with a non-null `id` are keyed as `${from}:${id}`
 * in a sliding window; duplicates are dropped and emit `packetReplay`.
 */
export default class NetworkState extends EventEmitter {
  /**
   * @param {{ nodeTimeoutMs?: number, replayWindowSize?: number }} [opts]
   */
  constructor({ nodeTimeoutMs = 5 * 60 * 1000, replayWindowSize = 512 } = {}) {
    super();
    this.nodeDB = new Map(); // nodeId -> NodeInfo
    this.nodeTimeoutMs = nodeTimeoutMs;
    this.replayWindowSize = replayWindowSize;
    /** @type {Map<string, number>} */
    this._seenPackets = new Map();
    this._pruneTimer = setInterval(() => this._pruneStale(), this.nodeTimeoutMs);
  }

  #replayKey(packet) {
    if (packet?.id == null || packet?.from == null) return null;
    return `${packet.from}:${packet.id}`;
  }

  /**
   * @param {any} packet
   * @returns {boolean} true if this is a replay and should be ignored
   */
  #isReplay(packet) {
    const key = this.#replayKey(packet);
    if (!key) return false;
    if (this._seenPackets.has(key)) return true;
    this._seenPackets.set(key, Date.now());
    while (this._seenPackets.size > this.replayWindowSize) {
      const oldest = this._seenPackets.keys().next().value;
      this._seenPackets.delete(oldest);
    }
    return false;
  }

  /** Handle an incoming packet (from the transport layer). */
  onPacket(packet) {
    if (!packet?.from) return false;
    if (this.#isReplay(packet)) {
      this.emit("packetReplay", packet);
      return false;
    }
    const nodeId = packet.from;
    const isNew = !this.nodeDB.has(nodeId);
    const node = this.nodeDB.get(nodeId) ?? new NodeInfo(nodeId);
    node.update(packet);
    this.nodeDB.set(nodeId, node);
    if (isNew) this.emit("nodeAdded", node);
    else this.emit("nodeUpdated", node);
    this.emit("packetRelayed", packet);
    return true;
  }

  /** Handle a NodeInfo broadcast (e.g., discovery beacon). */
  onNodeInfo(nodeInfo) {
    if (!nodeInfo?.num) return;
    const nodeId = nodeInfo.num;
    const isNew = !this.nodeDB.has(nodeId);
    const node = this.nodeDB.get(nodeId) ?? new NodeInfo(nodeId);
    Object.assign(node, nodeInfo);
    node.lastHeard = Date.now();
    this.nodeDB.set(nodeId, node);
    if (isNew) this.emit("nodeAdded", node);
    else this.emit("nodeUpdated", node);
  }

  /** Return an array of all known nodes. */
  getNodes() {
    return Array.from(this.nodeDB.values());
  }

  /** Return a single node by its id. */
  getNode(id) {
    return this.nodeDB.get(id);
  }

  /** Simple neighbor list – nodes heard within the timeout window. */
  getNeighbors() {
    const cutoff = Date.now() - this.nodeTimeoutMs;
    return this.getNodes().filter((n) => n.lastHeard >= cutoff);
  }

  /** Placeholder for route generation – returns empty array for now. */
  getRoutes() {
    return [];
  }

  /** Number of packet IDs currently remembered for replay checks. */
  getSeenPacketCount() {
    return this._seenPackets.size;
  }

  /** Internal method to prune nodes that have timed out. */
  _pruneStale() {
    const now = Date.now();
    for (const [id, node] of this.nodeDB.entries()) {
      if (now - node.lastHeard > this.nodeTimeoutMs) {
        this.nodeDB.delete(id);
        this.emit("nodeLost", node);
      }
    }
  }

  /** Clean up resources when the instance is no longer needed. */
  destroy() {
    clearInterval(this._pruneTimer);
  }
}
