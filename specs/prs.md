# Product Requirements Specification

This file redirects to the canonical PRS document:

**[PRODUCT_REQUIREMENTS_SPECIFICATION_V2.md](PRODUCT_REQUIREMENTS_SPECIFICATION_V2.md)** — Document ID OCP-0005, Version 2.0.0-draft

---

## v2.1 Scope Addendum — Maps & Photo Sync

Added per [build-plan-v2.md](build-plan-v2.md). These requirements are
non-negotiables that every later build session inherits. Full behavior is
specified in [maps-spec.md](maps-spec.md) (OCP-0012).

### R-MAPS — Offline Maps & Sonar View
- The app SHALL provide a **Maps** workspace with two views over the same node
  data, toggled: an **offline tile map** and a **self-centered sonar/radar view**.
- Tiles SHALL be served from on-disk tile packs (pre-fetched in one online
  session) with zero runtime network dependency (offline-first, DG-001).
- The sonar view SHALL plot nodes by **bearing + range from self**, with
  auto-scaled range rings and a manual zoom override.
- The sonar view SHALL distinguish **active** (recently heard) from **stale**
  nodes and SHALL draw **motion vectors** for moving nodes from position history.
- Self-position SHALL come from the paired node's GPS when available, falling
  back to the phone's GPS.
- North-up is the MVP rotation mode; heading-up/track-up is deferred to Phase 7.

### R-POS — Position History
- `NodePosition` SHALL be stored as a **history** (multiple samples per node),
  not a single latest fix, so motion vectors are derivable.
- A retention/pruning policy for `NodePosition` SHALL be defined (Phase 2);
  unbounded per-node history is out of scope for steady-state operation.

### R-PHOTO — Photo Sync (deferred to Phase 7)
- Photos SHALL NOT be sent over the raw LoRa mesh. Meshtastic application
  payloads cap around ~200 bytes; a photo would occupy the shared channel for
  hours.
- Photos SHALL sync **opportunistically** over phone-to-phone Bluetooth/Wi-Fi or
  internet when available. At most a small "photo waiting" flag MAY ride the mesh.
- Photo sync is a distinct capability from messaging (different transport, no
  `ocp_bridge_meshtastic` involvement) and lands in the Phase 7 UI build-out.
