/**
 * Permission identifiers a plugin may request.
 * The host only grants permissions that appear in both the plugin manifest
 * and the host's allowed set (install-time permission model).
 */
export const PERMISSIONS = Object.freeze({
  STATE_READ: "state.read",
  NETWORK_READ: "network.read",
  MESSAGING_SEND: "messaging.send",
  DEVICE_CONNECT: "device.connect",
});

/** Well-known capability IDs plugins can register. */
export const CAPABILITIES = Object.freeze({
  STATUS_PROVIDER: "status.provider",
  DEVICE_ADAPTER: "device.adapter",
  UI_CONTRIBUTION: "ui.contribution",
});

/**
 * Validate a plugin manifest shape.
 * @param {unknown} manifest
 * @returns {{ ok: true } | { ok: false, error: string }}
 */
export function validateManifest(manifest) {
  if (!manifest || typeof manifest !== "object") {
    return { ok: false, error: "Manifest must be an object" };
  }
  const m = /** @type {Record<string, unknown>} */ (manifest);
  if (typeof m.id !== "string" || !m.id.trim()) {
    return { ok: false, error: "Manifest.id is required" };
  }
  if (typeof m.name !== "string" || !m.name.trim()) {
    return { ok: false, error: "Manifest.name is required" };
  }
  if (typeof m.version !== "string" || !m.version.trim()) {
    return { ok: false, error: "Manifest.version is required" };
  }
  if (m.permissions !== undefined && !Array.isArray(m.permissions)) {
    return { ok: false, error: "Manifest.permissions must be an array" };
  }
  if (m.capabilities !== undefined && !Array.isArray(m.capabilities)) {
    return { ok: false, error: "Manifest.capabilities must be an array" };
  }
  return { ok: true };
}
