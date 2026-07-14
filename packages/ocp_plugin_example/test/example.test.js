import { describe, it } from "node:test";
import assert from "node:assert/strict";
import { PluginHost, PERMISSIONS, CAPABILITIES } from "@ocp/plugin-api";
import { createDiagnosticsPlugin } from "../src/index.js";

describe("createDiagnosticsPlugin", () => {
  it("works against PluginHost as a third-party consumer", async () => {
    const host = new PluginHost({
      allowedPermissions: [PERMISSIONS.STATE_READ],
      getAppState: () => ({
        connected: true,
        nodeCount: 2,
        transportKind: "meshtastic",
        ruViewConnected: false,
        rtlConnected: true,
      }),
    });

    const plugin = createDiagnosticsPlugin();
    await host.install(plugin);
    await host.activate(plugin.manifest.id);

    const listed = host.list();
    assert.equal(listed.length, 1);
    assert.equal(listed[0].id, "ocp.example.diagnostics");
    assert.equal(listed[0].active, true);

    const providers = host.getCapabilities(CAPABILITIES.STATUS_PROVIDER);
    assert.equal(providers.length, 1);
    const status = providers[0].impl.getStatus();
    assert.equal(status.healthy, true);
    assert.equal(status.meshConnected, true);
    assert.equal(status.nodeCount, 2);
    assert.equal(status.rtlConnected, true);

    await host.deactivate(plugin.manifest.id);
    assert.equal(host.list()[0].active, false);
  });
});
