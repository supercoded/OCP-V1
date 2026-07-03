# OCP — Repo Structure & Build Plan (v2)

**Purpose:** Updated from v1 to add offline maps, a sonar/radar-style live view of active and moving nodes, and a defined path for photos — and to reorder the build so a real, installable, hardware-paired app exists early, rather than only after every layer is finished. Pairs with `PRS v2.1` and `Charter v1.0`; update those with the Maps and photo-sync scope below before starting Phase 0, so Claude Code inherits the same non-negotiables it does today instead of working from a stale spec.

**What changed from v1:**
- New `ocp_maps` package and `Maps` workspace: an offline tile map **and** a sonar/radar-style live view of nearby nodes, bearing/range from you, with motion vectors for anything moving.
- New storage schemas: `NodePosition` (a history, not a single latest fix) and `MapRegion` (tile-pack metadata).
- Photos get a defined path — opportunistic phone-to-phone/internet sync, not the raw LoRa mesh — with the reasoning in §5.
- Phases reordered around a new **Phase 1 — MVP Vertical Slice**, so hardware pairing, messaging, and the map exist as one thin, installable build well before the rest of the layers are hardened. Everything after Phase 1 is depth, not new user-facing capability.

---

## 1. Repo Structure

```
ocp/
├── apps/
│   └── ocp_app/                    # Flutter app — Presentation + Application layer
│       ├── lib/
│       │   ├── workspaces/         # Dashboard, Messaging, Network, Devices, Maps, Diagnostics
│       │   │   └── maps/           # Tile map + sonar/radar view (toggle, shared data)
│       │   ├── widgets/
│       │   └── main.dart
│       └── test/
│
├── packages/
│   ├── ocp_core/                   # Core Services: Session, Device, Network, Identity, Location,
│   │                                # Storage, Plugin, Security, Notification managers
│   ├── ocp_odp/                    # ODP: codec + state machine (App <-> Device)
│   ├── ocp_onp/                    # ONP: codec + state machine (Device <-> Device)
│   ├── ocp_transport/              # Transport abstractions: BLE, USB Serial, + mock transport
│   ├── ocp_storage/                # Isar persistence layer, schemas, migrations
│   ├── ocp_maps/                   # NEW — offline tile cache, bearing/range/velocity math,
│   │                                # sonar-view projection engine. Pure logic, no widgets.
│   ├── ocp_plugin_api/             # Plugin interface contracts (device, UI, widget plugins)
│   └── ocp_bridge_meshtastic/      # Meshtastic bridge — implements ODP/ONP against
│                                    # Meshtastic's native protobufs
│
├── specs/
│   ├── prs.md                      # Copy of the PRS
│   ├── charter.md                  # Copy of the Charter
│   ├── odp-spec.md                 # ODP wire format + handshake, versioned
│   ├── onp-spec.md                 # ONP wire format + routing, versioned
│   └── maps-spec.md                # NEW — position schema, tile-cache format, sonar-view
│                                    # projection + interaction spec (see §4)
│
├── tools/
│   ├── mock_device/                # Standalone mock BLE/USB device for testing without hardware
│   └── mock_position_feed/         # NEW — fabricates moving-node position streams so the
│                                    # sonar view is buildable/testable before real GPS hardware
│
└── melos.yaml
```

**Why this shape (updated):** `ocp_maps` follows the same isolation rule as `ocp_bridge_meshtastic` — the tile source or the projection math can change without touching `ocp_core`, `ocp_odp`, or `ocp_onp`. It's pure logic with no Flutter widgets in it, so it's unit-testable the same way `ocp_odp`'s codec is: against synthetic data, before any real position fix exists. That's what `mock_position_feed` is for.

---

## 2. Data Model Additions (`ocp_storage`)

Two new schemas, needed before Maps can do anything real:

- **`NodePosition`** — `nodeId, lat, lon, altitude, heading, speedMps, timestamp, source (direct | relayed via ONP)`. This has to be a **history table**, not a single latest-position field. The sonar view can't draw a motion vector for a moving node from one sample.
- **`MapRegion`** — metadata for downloaded tile packs: `bounds, zoomRange, style, sizeBytes, downloadedAt, storagePath`. The tiles themselves live as files on disk (this mirrors how Meshtastic's own map tooling stores tile packs — folders of image tiles, not database blobs); Isar just tracks what's cached and where.

---

## 3. Build Order (v2)

### Phase 0 — Scaffolding
- Set up the monorepo, empty packages (including `ocp_maps`), CI, lint rules.
- Commit `prs.md`, `charter.md`, and this build plan into `specs/` — update PRS/Charter with the Maps and photo-sync scope first, so every later session inherits it automatically.

### Phase 1 — MVP Vertical Slice *(new)*
The point of this phase: a real, installable app that pairs with actual hardware, sends a message, and shows a live node view — before every layer underneath it is finished. Deliberately thin:
- `ocp_storage`: Messages, Contacts, Devices, Conversations, `NodePosition`. Nothing else yet.
- `ocp_core`: Storage Manager, Identity Manager, a minimal Location Manager (ingest position updates, write to storage, expose a stream). No Notification Manager yet.
- `ocp_odp`: codec + handshake against the mock device, carrying only the `TEXT_MESSAGE` and `POSITION` port types.
- `ocp_transport`: **BLE only.** Skip USB Serial for now — BLE is the two-tap pairing path most people will actually use with a RAK or LilyGo board.
- `ocp_bridge_meshtastic`: translate Meshtastic's `TEXT_MESSAGE_APP` and `POSITION_APP` frames to/from ODP. Nothing else yet.
- `ocp_maps`: offline tile cache (load a pre-fetched tile pack — you still need one internet session to download tiles before going off-grid) plus the bearing/range/velocity math for the sonar view. Build and test this against `tools/mock_position_feed` before any real GPS fix exists.
- `ocp_app`: three real workspaces — **Devices** (scan + pair flow — this is the "with ease" part: auto-detect known Meshtastic service UUIDs, one-tap connect), **Messaging** (send/receive text), **Maps** (tile view and sonar view, toggled, showing active and moving nodes).
- Smoke-test the pairing flow against at least one RAK4631-based board and one LilyGo board specifically — they both speak the same Meshtastic BLE API, but vendor-level BLE stack quirks are exactly the kind of thing that only shows up on real hardware.
- Explicitly deferred: USB Serial, full ONP link-quality stats, Dashboard/Network/Diagnostics workspaces, plugins, PIN/encryption, telemetry and waypoint port types, photo sync, performance tuning.

### Phase 2 — Core Services & Storage Hardening
- `ocp_core`: add the Notification Manager held back from Phase 1.
- `ocp_storage`: finish the full schema set and migrations groundwork; add a retention/pruning policy for `NodePosition` (unbounded history per node isn't sustainable) and multi-pack management for `MapRegion`.
- Still fully unit-testable, no hardware needed — good second task set for Claude Code end-to-end.

### Phase 3 — ODP Protocol Hardening
- `ocp_odp`: extend the codec and state machine to the remaining port types beyond text and position, and harden version negotiation and reconnect/resume behavior against `tools/mock_device`.
- Still no real hardware needed — this finishes what v1 called the layer worth the most spec-writing time.

### Phase 4 — Transport Hardening
- `ocp_transport`: add USB Serial (Windows/macOS/Linux), and work through the platform-specific BLE quirks Phase 1's happy-path pairing didn't need to handle.
- This is still where platform quirks show up — budget the extra manual QA time per OS.

### Phase 5 — Meshtastic Bridge Hardening *(hardware-in-the-loop)*
- `ocp_bridge_meshtastic`: extend translation to telemetry, waypoints, and the remaining Meshtastic port types.
- Test firmware-version drift and malformed-packet handling against real RAK and LilyGo hardware, not just fixtures.

### Phase 6 — ONP / Network Layer
- `ocp_onp`: peer discovery, last-heard tracking, link quality, routing stats, built on top of the ODP connection and bridge from Phases 1–5.
- Testable with two or more real or simulated nodes. This also becomes the data source for the sonar view's active/stale coloring (§4) — no new data needed, just a new consumer of what ONP already tracks.

### Phase 7 — Full UI Build-Out
- `ocp_app`: add the Dashboard and Network workspaces (PRS §10–§14); round out Diagnostics.
- Sonar-view polish: heading-up/track-up rotation (needs the phone's compass), sweep animation, richer motion trails (§4).
- Photo-sync UI lands here too (§5) — this is also the most parallelizable phase and the lowest-risk to core contracts, same reasoning v1 gave for UI work generally.

### Phase 8 — Plugin System
- `ocp_plugin_api`: formalize the interface contracts sketched while building Phases 1–3.
- Build one throwaway example plugin to validate the contract is usable by someone who isn't you.

### Phase 9 — Security
- PIN lock, encrypted database, CRC validation, replay protection (PRS §16).
- Still sequenced after the data model is stable, including the new `NodePosition`/`MapRegion` schemas — retrofitting encryption onto a shifting schema is more painful than building it once the shape is settled.

### Phase 10 — Performance & Cross-Platform QA
- Validate against PRS §15's hard numbers (launch time, write latency, FPS).
- Add sonar-view render performance as its own benchmark — many moving blips redrawing at once is a different perf question than tile rendering.
- Manual/measured, not a coding hand-off — but Claude Code can help write the instrumentation and benchmarking harness.

---

## 4. Sonar / Radar Node View — Design Notes

Worth its own spec (`specs/maps-spec.md`) before `ocp_maps` gets built, the same way v1 flagged ODP's handshake as worth extra spec time up front. Decisions to settle first:

- **Self-centered, not north-up-by-default.** Everything plots as bearing + range *from you*, not on a conventional map projection. Self-position comes from the paired node's GPS if it has one (T-Beam-class hardware); falls back to the phone's own GPS if it doesn't (a bare RAK4631 needs an add-on GPS module).
- **Range rings, auto-scaled.** Concentric rings sized to the farthest currently-tracked node, with a manual zoom override — mesh members can be 10 meters or 20 kilometers away, so a fixed scale doesn't work.
- **Active vs. stale.** Nodes heard from inside a recency window render bright or pulsing; older ones fade, then drop to a "last seen" list past a configurable age. This reads directly off ONP's last-heard tracking (Phase 6) — no new data, just a new presentation of it.
- **Moving nodes.** Draw a short trail or heading arrow from the last 2–3 `NodePosition` samples. This is the reason position has to be a history table, not a single field.
- **Rotation mode.** North-up for the Phase 1 MVP — simplest, no sensor dependency. Heading-up/track-up (rotates with your direction of travel) is a real nice-to-have but needs the phone's compass; that's a Phase 7 polish item, not MVP.
- **Tap-to-detail.** Tapping a blip opens the same node detail sheet Devices/Network already show — name, distance, bearing, battery, last heard. Reuse it, don't rebuild it.
- **Test path.** Build and unit-test the bearing/range/velocity math in `ocp_maps` against `tools/mock_position_feed` (synthetic nodes on scripted paths) before wiring it to live ONP data — same mock-first approach v1 used for the ODP codec.

---

## 5. Photos — Scoping Note

Not part of the MVP vertical slice. Meshtastic packets cap out around 200 bytes of application payload, and a compressed photo could take hours to cross the mesh while occupying the shared channel for every other node on it — it's why mainline Meshtastic has stayed text-only despite people asking for this repeatedly. Plan for photos to sync **opportunistically** — phone-to-phone Bluetooth/Wi-Fi, or internet when it's available — with, at most, a small "photo waiting" flag riding the LoRa mesh itself. This is a distinct capability from messaging (different transport, no `ocp_bridge_meshtastic` involvement) and lands in Phase 7 alongside the rest of the UI build-out, once the core loop is solid.

---

## 6. How to Brief Claude Code Day-to-Day (updated)

- Keep `specs/prs.md`, `specs/charter.md`, `specs/maps-spec.md`, and the other `specs/*-spec.md` files in the repo as always-available context; reference by path rather than re-pasting.
- For `ocp_maps` sonar-view work, ask for tests against `tools/mock_position_feed` *before* wiring in live ONP data — the same mock-first pattern used for ODP/ONP.
- Scope Phase 1 tasks narrowly and explicitly — e.g. "wire BLE pairing and a single mock position stream into the Devices and Maps workspaces" rather than "build the MVP." The phase is thin on purpose, and a vague prompt will pull in later-phase scope by habit.
- Treat Phase 5 (Meshtastic bridge hardening) and Phase 10 (performance) as the two phases you pair on rather than delegate outright — both need a real device or real measurement in the loop.
