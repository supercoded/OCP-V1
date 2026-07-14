import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { PluginHost, PERMISSIONS, CAPABILITIES, validateManifest } from "../src/index.js";

describe("validateManifest", () => {
  it("rejects missing id", () => {
    const r = validateManifest({ name: "x", version: "1" });
    assert.equal(r.ok, false);
  });

  it("accepts minimal valid manifest", () => {
    const r = validateManifest({ id: "a", name: "A", version: "0.1.0" });
    assert.equal(r.ok, true);
  });
});

describe("PluginHost", () => {
  it("installs, activates, registers capability, and uninstalls", async () => {
    const host = new PluginHost({
      allowedPermissions: [PERMISSIONS.STATE_READ],
      getAppState: () => ({ connected: true, nodeCount: 3 }),
    });

    const plugin = {
      manifest: {
        id: "test.plugin",
        name: "Test",
        version: "0.0.1",
        permissions: [PERMISSIONS.STATE_READ],
        capabilities: [CAPABILITIES.STATUS_PROVIDER],
      },
      async activate(ctx) {
        ctx.registerCapability(CAPABILITIES.STATUS_PROVIDER, {
          getStatus: () => ({ ...ctx.getAppState(), pluginId: ctx.pluginId }),
        });
      },
      async deactivate() {},
    };

    await host.install(plugin);
    assert.equal(host.list().length, 1);
    assert.equal(host.list()[0].active, false);

    await host.activate("test.plugin");
    assert.equal(host.list()[0].active, true);

    const status = host.getCapability(CAPABILITIES.STATUS_PROVIDER).getStatus();
    assert.equal(status.connected, true);
    assert.equal(status.nodeCount, 3);
    assert.equal(status.pluginId, "test.plugin");

    await host.uninstall("test.plugin");
    assert.equal(host.list().length, 0);
    assert.equal(host.getCapability(CAPABILITIES.STATUS_PROVIDER), null);
  });

  it("rejects install when permission is not allowed", async () => {
    const host = new PluginHost({ allowedPermissions: [] });
    await assert.rejects(
      () =>
        host.install({
          manifest: {
            id: "bad",
            name: "Bad",
            version: "1",
            permissions: [PERMISSIONS.MESSAGING_SEND],
          },
          activate: async () => {},
        }),
      /Permission denied/
    );
  });

  it("rejects undeclared capability registration", async () => {
    const host = new PluginHost({ allowedPermissions: [PERMISSIONS.STATE_READ] });
    await host.install({
      manifest: {
        id: "cap",
        name: "Cap",
        version: "1",
        permissions: [PERMISSIONS.STATE_READ],
        capabilities: [CAPABILITIES.STATUS_PROVIDER],
      },
      activate: async (ctx) => {
        ctx.registerCapability(CAPABILITIES.DEVICE_ADAPTER, {});
      },
    });
    await assert.rejects(() => host.activate("cap"), /not declared/);
  });

  it("rejects getAppState without state.read", async () => {
    const host = new PluginHost({
      allowedPermissions: [],
      getAppState: () => ({ secret: true }),
    });
    await host.install({
      manifest: {
        id: "noscope",
        name: "NoScope",
        version: "1",
        permissions: [],
        capabilities: [CAPABILITIES.STATUS_PROVIDER],
      },
      activate: async (ctx) => {
        ctx.registerCapability(CAPABILITIES.STATUS_PROVIDER, {
          getStatus: () => ctx.getAppState(),
        });
      },
    });
    await host.activate("noscope");
    assert.throws(
      () => host.getCapability(CAPABILITIES.STATUS_PROVIDER).getStatus(),
      /state\.read/
    );
  });
});
