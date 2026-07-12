/**
 * Minimal ONP codec helpers for discovery beacons and route updates.
 * For this scaffold we JSON‑serialize objects into buffers.
 */

/** Encode a discovery beacon containing the local node's static info. */
export function encodeDiscoveryBeacon(localNodeInfo) {
  return Buffer.from(JSON.stringify(localNodeInfo), "utf8");
}

/** Decode a discovery beacon buffer back to an object. */
export function decodeDiscoveryBeacon(buffer) {
  return JSON.parse(buffer.toString("utf8"));
}

/** Encode a route‑update payload (array of routes). */
export function encodeRouteUpdate(routes) {
  return Buffer.from(JSON.stringify(routes), "utf8");
}

/** Decode a route‑update buffer back to a routes array. */
export function decodeRouteUpdate(buffer) {
  return JSON.parse(buffer.toString("utf8"));
}

