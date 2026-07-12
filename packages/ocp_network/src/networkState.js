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
 */
export default class NetworkState extends EventEmitter {
  constructor({ nodeTimeoutMs = 5 * 60 * 1000 } = {}) {
    super();
    this.nodeDB = new Map(); // nodeId -> NodeInfo
    this.nodeTimeoutMs = nodeTimeoutMs;
    this._pruneTimer = setInterval(() => this._pruneStale(), this.nodeTimeoutMs);
  }

  /** Handle an incoming packet (from the transport layer). */
  onPacket(packet) {
    if (!packet?.from) return;
    const nodeId = packet.from;
    const isNew = !this.nodeDB.has(nodeId);
    const node = this.nodeDB.get(nodeId) ?? new NodeInfo(nodeId);
    node.update(packet);
    this.nodeDB.set(nodeId, node);
    if (isNew) this.emit("nodeAdded", node);
    else this.emit("nodeUpdated", node);
    this.emit("packetRelayed", packet);
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

