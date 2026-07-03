# OCP Charter

This file redirects to the canonical charter document:

**[PROJECT_CHARTER.md](PROJECT_CHARTER.md)** — Document ID OCP-0002, Version 2.0.0-draft

---

## v1.0 Scope Addendum — Maps, Sonar View & Photos

Aligned with [build-plan-v2.md](build-plan-v2.md). The charter's scope now
includes:

- **Offline maps and a sonar/radar node view** as a first-class deliverable,
  landing in the Phase 1 MVP vertical slice (tile view + sonar view). Ownership
  sits in a dedicated `ocp_maps` package (pure logic) plus a `Maps` workspace.
- **Position history** (`NodePosition`) and **tile-pack metadata** (`MapRegion`)
  as new storage schemas, with `NodePosition` retention treated as a Phase 2
  hardening item.
- **Photos** as an explicitly scoped, deferred capability: opportunistic
  phone-to-phone/internet sync, never the raw LoRa mesh, landing in Phase 7.

### Success criteria addition
- The Phase 1 MVP is a **real, installable, hardware-paired app** that pairs over
  BLE, sends/receives a text message, and shows a live sonar node view — before
  the deeper layers are hardened.
- `ocp_maps` projection math maintains the same >90% unit-coverage bar as the
  other core packages, tested against synthetic feeds before live data.
