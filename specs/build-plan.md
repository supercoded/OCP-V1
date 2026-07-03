# OCP — Repo Structure & Build Plan

**Purpose:** A starting brief for building OCP with Claude Code. Pairs with `PRS v2.1` and `Charter v1.0`, which should live in the repo as persistent context.

---

## 1. Repo Structure

A single Dart/Flutter monorepo, organized so the layers in PRS §7 map directly to packages. This lets Claude Code (or any contributor) work on one layer with tests, without needing the layers above it to exist yet.

```
ocp/
├── apps/
│   └── ocp_app/                    # Flutter app — Presentation + Application layer
│       ├── lib/
│       │   ├── workspaces/         # Dashboard, Messaging, Network, Devices, Diagnostics
│       │   ├── widgets/
│       │   └── main.dart
│       └── test/
│
├── packages/
│   ├── ocp_core/                   # Core Services: Session, Device, Network, Identity,
│   │                                # Storage, Plugin, Security, Notification managers
│   ├── ocp_odp/                    # ODP: codec + state machine (App <-> Device)
│   ├── ocp_onp/                    # ONP: codec + state machine (Device <-> Device)
│   ├── ocp_transport/              # Transport abstractions: BLE, USB Serial, + mock transport
│   ├── ocp_storage/                # Isar persistence layer, schemas, migrations
│   ├── ocp_plugin_api/             # Plugin interface contracts (device, UI, widget plugins)
│   └── ocp_bridge_meshtastic/      # Meshtastic bridge — implements ODP/ONP against
│                                    # Meshtastic's native protobufs
│
├── specs/
│   ├── prs.md                      # Copy of the PRS
│   ├── charter.md                  # Copy of the Charter
│   ├── odp-spec.md                 # ODP wire format + handshake, versioned
│   └── onp-spec.md                 # ONP wire format + routing, versioned
│
├── tools/
│   └── mock_device/                # Standalone mock BLE/USB device for testing without hardware
│
└── melos.yaml                      # Monorepo task runner (optional but recommended)
```

**Why this shape:** each `packages/ocp_*` is independently testable and versioned per Charter §5. The Meshtastic bridge is isolated so a second bridge (a different radio, a different mesh protocol) can be added later without touching `ocp_core`, `ocp_odp`, or `ocp_onp` — this is the Charter §6.3 principle in file-tree form.

---

## 2. Build Order

Ordered so each phase can be fully tested before the next depends on it. Phases 1–3 need no real hardware; a mock transport stands in until the bridge is ready.

### Phase 0 — Scaffolding
- Set up the monorepo, empty packages, CI, lint rules.
- Commit `prs.md` and `charter.md` into `specs/` — this is what you point Claude Code at for every subsequent task, so it inherits naming conventions and non-negotiables automatically instead of re-explaining them each session.

### Phase 1 — Core Services & Storage
- `ocp_storage`: Isar schemas for Messages, Contacts, Devices, Conversations.
- `ocp_core`: Storage Manager, Identity Manager, Notification Manager — pure logic, no I/O.
- Fully unit-testable. Good first task set for Claude Code end-to-end.

### Phase 2 — ODP Protocol (against a mock)
- `ocp_odp`: define the codec and connection state machine per `odp-spec.md`.
- `tools/mock_device`: a fake device that speaks ODP over a loopback, so the codec and state machine can be tested without BLE/USB or real firmware.
- This is the layer worth the most spec-writing time — get the handshake and version negotiation right here before touching real hardware.

### Phase 3 — Transport Layer
- `ocp_transport`: BLE (Android/iOS via platform channels) and USB Serial (Windows/macOS/Linux).
- Test against `tools/mock_device` first; this phase is where platform-specific quirks show up, so budget more manual QA time per OS.

### Phase 4 — Meshtastic Bridge *(first hardware-in-the-loop phase)*
- `ocp_bridge_meshtastic`: translate Meshtastic's native protobuf frames into ODP.
- This is where a real Meshtastic node earns its keep — Claude Code can scaffold the translation logic from Meshtastic's published protobufs, but the handshake and edge cases (firmware version drift, malformed packets) need testing against real devices, not just fixtures.

### Phase 5 — ONP / Network Layer
- `ocp_onp`: peer discovery, last-heard tracking, link quality, routing stats — built on top of a working ODP connection + bridge.
- Testable with two or more real or simulated nodes.

### Phase 6 — UI
- `ocp_app`: Dashboard, Messaging, Devices, Network workspaces (PRS §10–§14).
- By this point the data layer and protocols are stable, so this phase is the most parallelizable and the best fit for iterative Claude Code sessions — UI work has fast feedback loops and low risk of breaking core contracts.

### Phase 7 — Plugin System
- `ocp_plugin_api`: formalize the interface contracts sketched during Phase 1–2.
- Build one throwaway example plugin to validate the contract is actually usable by someone who isn't you.

### Phase 8 — Security
- PIN lock, encrypted database, CRC validation, replay protection (PRS §16).
- Do this after the data model is stable — retrofitting encryption onto a shifting schema is more painful than building it once the shape is settled.

### Phase 9 — Performance & Cross-Platform QA
- Validate against PRS §15's hard numbers (launch time, write latency, FPS).
- This is manual/measured, not something to hand off as a coding task — but Claude Code can help write the instrumentation and benchmarking harness.

---

## 3. How to Brief Claude Code Day-to-Day

- Keep `specs/prs.md`, `specs/charter.md`, and the relevant `specs/*-spec.md` in the repo so they're available as context for any session — reference them by path rather than re-pasting them into prompts.
- Scope tasks to one package at a time (e.g., "implement the Isar schema for Conversations in `ocp_storage`, per PRS §5 Storage and Charter §6.7 export requirement") rather than "build the storage layer."
- For anything touching `ocp_odp` or `ocp_onp`, ask for tests against the mock transport/device *before* wiring in real BLE/USB — that mirrors the phase order above and catches protocol bugs cheaply.
- Treat Phase 4 (Meshtastic bridge) and Phase 9 (performance) as the two phases where you're pairing with Claude Code rather than delegating outright — both need a real device or real measurement in the loop.
