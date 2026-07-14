import { EventEmitter } from "node:events";
import { validateManifest } from "./contracts.js";

/**
 * In-process plugin host: install / uninstall / activate / deactivate,
 * capability registration, and permission gating.
 *
 * @typedef {import('./contracts.js').PERMISSIONS} _
 */

export class PluginHost extends EventEmitter {
  /**
   * @param {{ allowedPermissions?: string[], getAppState?: () => any }} [options]
   */
  constructor(options = {}) {
    super();
    /** @type {Set<string>} */
    this.allowedPermissions = new Set(options.allowedPermissions ?? []);
    /** @type {() => any} */
    this.getAppState = options.getAppState ?? (() => ({}));
    /** @type {Map<string, { plugin: any, active: boolean, granted: string[], capabilities: Map<string, any> }>} */
    this.#registry = new Map();
  }

  #registry;

  /**
   * Register (install) a plugin. Does not activate it.
   * @param {any} plugin - { manifest, activate, deactivate? }
   */
  async install(plugin) {
    if (!plugin || typeof plugin.activate !== "function") {
      throw new Error("Plugin must provide an activate() function");
    }
    const check = validateManifest(plugin.manifest);
    if (!check.ok) throw new Error(check.error);

    const id = plugin.manifest.id;
    if (this.#registry.has(id)) {
      throw new Error(`Plugin already installed: ${id}`);
    }

    const requested = Array.isArray(plugin.manifest.permissions)
      ? plugin.manifest.permissions.map(String)
      : [];
    const denied = requested.filter((p) => !this.allowedPermissions.has(p));
    if (denied.length) {
      throw new Error(`Permission denied for plugin ${id}: ${denied.join(", ")}`);
    }

    this.#registry.set(id, {
      plugin,
      active: false,
      granted: [...requested],
      capabilities: new Map(),
    });
    this.emit("installed", { id, manifest: plugin.manifest });
    return { ok: true, id };
  }

  /**
   * Deactivate (if needed) and remove a plugin.
   * @param {string} id
   */
  async uninstall(id) {
    const entry = this.#registry.get(id);
    if (!entry) throw new Error(`Plugin not found: ${id}`);
    if (entry.active) await this.deactivate(id);
    this.#registry.delete(id);
    this.emit("uninstalled", { id });
    return { ok: true };
  }

  /**
   * Activate a previously installed plugin.
   * @param {string} id
   */
  async activate(id) {
    const entry = this.#registry.get(id);
    if (!entry) throw new Error(`Plugin not found: ${id}`);
    if (entry.active) return { ok: true, already: true };

    const capabilities = new Map();
    const ctx = {
      pluginId: id,
      permissions: Object.freeze([...entry.granted]),
      hasPermission: (perm) => entry.granted.includes(perm),
      getAppState: () => {
        if (!entry.granted.includes("state.read")) {
          throw new Error("Permission denied: state.read required for getAppState");
        }
        return this.getAppState();
      },
      registerCapability: (name, impl) => {
        if (typeof name !== "string" || !name) {
          throw new Error("Capability name required");
        }
        const declared = entry.plugin.manifest.capabilities ?? [];
        if (declared.length && !declared.includes(name)) {
          throw new Error(`Capability not declared in manifest: ${name}`);
        }
        capabilities.set(name, impl);
      },
    };

    await entry.plugin.activate(ctx);
    entry.capabilities = capabilities;
    entry.active = true;
    this.emit("activated", { id });
    return { ok: true };
  }

  /**
   * Deactivate an active plugin and clear its capabilities.
   * @param {string} id
   */
  async deactivate(id) {
    const entry = this.#registry.get(id);
    if (!entry) throw new Error(`Plugin not found: ${id}`);
    if (!entry.active) return { ok: true, already: true };

    if (typeof entry.plugin.deactivate === "function") {
      await entry.plugin.deactivate();
    }
    entry.capabilities.clear();
    entry.active = false;
    this.emit("deactivated", { id });
    return { ok: true };
  }

  /** @returns {Array<{ id: string, name: string, version: string, description?: string, active: boolean, permissions: string[], capabilities: string[] }>} */
  list() {
    return [...this.#registry.entries()].map(([id, entry]) => ({
      id,
      name: entry.plugin.manifest.name,
      version: entry.plugin.manifest.version,
      description: entry.plugin.manifest.description,
      active: entry.active,
      permissions: [...entry.granted],
      capabilities: [...entry.capabilities.keys()],
      declaredCapabilities: [...(entry.plugin.manifest.capabilities ?? [])],
    }));
  }

  /**
   * Return all implementations registered for a capability name.
   * @param {string} name
   * @returns {Array<{ pluginId: string, impl: any }>}
   */
  getCapabilities(name) {
    const out = [];
    for (const [id, entry] of this.#registry) {
      if (!entry.active) continue;
      if (entry.capabilities.has(name)) {
        out.push({ pluginId: id, impl: entry.capabilities.get(name) });
      }
    }
    return out;
  }

  /**
   * First active implementation of a capability, or null.
   * @param {string} name
   */
  getCapability(name) {
    const all = this.getCapabilities(name);
    return all.length ? all[0].impl : null;
  }
}

export default PluginHost;
