import { PERMISSIONS, CAPABILITIES } from "@ocp/plugin-api";

/**
 * Example diagnostics plugin — registers a `status.provider` capability.
 * Validates that a third-party-shaped module can use @ocp/plugin-api alone.
 */
export function createDiagnosticsPlugin() {
  let active = false;

  return {
    manifest: {
      id: "ocp.example.diagnostics",
      name: "Diagnostics Status",
      version: "0.1.0",
      description: "Example plugin that reports mesh/app health via status.provider",
      permissions: [PERMISSIONS.STATE_READ],
      capabilities: [CAPABILITIES.STATUS_PROVIDER],
    },

    async activate(ctx) {
      if (!ctx.hasPermission(PERMISSIONS.STATE_READ)) {
        throw new Error("state.read permission required");
      }
      active = true;
      ctx.registerCapability(CAPABILITIES.STATUS_PROVIDER, {
        getStatus() {
          const s = ctx.getAppState() ?? {};
          return {
            pluginId: ctx.pluginId,
            healthy: true,
            active,
            meshConnected: !!s.connected,
            nodeCount: s.nodeCount ?? 0,
            transportKind: s.transportKind ?? null,
            ruViewConnected: !!s.ruViewConnected,
            rtlConnected: !!s.rtlConnected,
            checkedAt: Date.now(),
          };
        },
      });
    },

    async deactivate() {
      active = false;
    },
  };
}

export default createDiagnosticsPlugin;
