# OCP-V1 — Project Context

**Generated:** 2026-07-12  
**Owner:** Mike  
**Source repo:** https://github.com/supercoded/OCP-V1

## Stack
- **Monorepo:** Flutter/Dart target (per specs), current scaffold in Node.js/JS.
- **Runtime:** Node.js (v22+ on Pi), future Flutter app shells (`apps/desktop`, `apps/mobile`).
- **Bridge:** Meshtastic protobufs via `protobufjs`.
- **Storage:** JSON file offline store with `LocalKeyCipher` (dev passphrase for now).
- **Build:** npm workspaces, shell scripts for desktop/Android/field validation.

## Hardware / Platform Constraints
- **Primary target:** Android + Desktop MVP.
- **Secondary target:** iOS/macOS parity (requires bridge/gateway due to Apple USB/BLE limits).
- **Radios:** Meshtastic-compatible RAK Wireless module (TCP/Serial/BLE), future Baofeng UV-5RM, future RTL-SDR.
- **Offline-first:** zero cloud dependency, local storage, no cloud relay.
- **Host environment:** Raspberry Pi 5 — Pi-hole/DNS is critical infrastructure, do not break.

## Conventions
- Conventional Commits.
- Lint/build/test before commit (`npm test`, `npm run build:desktop`, `npm run build:android`).
- No destructive commands without confirmation.
- Use `_bmad/` agentic process for multi-step work.
- Specs are source of truth under `specs/`; implementation must stay aligned.

## Non-negotiables
- Offline-first at every layer.
- Modular transport abstraction (BLE/Serial/TCP) so bridges can be swapped.
- 90% unit coverage goal for core modules per charter.
- Architecture changes require spec updates.

## Current status
- Phase 0–4 complete: scaffold, core, protocol, transport, Meshtastic bridge.
- Phase 5+ pending: ONP/network layer, UI workspaces, security hardening, Baofeng/SDR support.

## Key files
| File | Purpose |
|------|---------|
| `specs/build-plan.md` | Phased build order |
| `specs/PROJECT_CHARTER.md` | Governance, scope, success criteria |
| `specs/PRODUCT_REQUIREMENTS_SPECIFICATION_V2.md` | Functional / non-functional requirements |
| `packages/ocp_bridge_meshtastic/` | Meshtastic bridge (codec + TCP transport) |
| `packages/offline-core/` | Transport abstractions, protocol client, storage |
| `apps/desktop/`, `apps/mobile/` | App shells |
