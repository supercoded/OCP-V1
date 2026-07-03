# Maps & Sonar-View Specification

**Document ID:** OCP-0012
**Version:** 1.0.0
**Status:** Draft

Covers the offline tile-map data model, the `NodePosition` history model, and the
self-centered sonar/radar projection used by the `Maps` workspace. This spec is
authoritative for the `ocp_maps` package (pure logic) and for the `Maps`
workspace in `ocp_app`. It exists before `ocp_maps` is built for the same reason
the ODP handshake got its own spec first: the projection math is the part most
worth pinning down up front.

---

## 1. Design Principles

- **Offline first.** Tiles are pre-fetched into on-disk tile packs during one
  online session, then served from disk with zero network dependency (DG-001).
- **Hardware independence.** `ocp_maps` is pure Dart with no Flutter, no
  `dart:ui`, and no I/O in its math. Tile file reads sit behind a
  `TileProvider` interface so the source (files, memory, test fixtures) can be
  swapped without touching projection logic (DG-002, DG-003).
- **Mock-first / testability.** All bearing/range/velocity/projection math is
  unit-tested against synthetic position streams from `tools/mock_position_feed`
  before any live GPS fix exists (DG-009).

---

## 2. Position Model — `NodePosition` (history, not latest)

`NodePosition` is a **history table**. Every received fix is appended; there is
no single "latest position" field. A motion vector for a moving node needs at
least two samples, so a single-latest design cannot draw one.

| Field      | Type            | Notes                                             |
|------------|-----------------|---------------------------------------------------|
| `nodeId`   | String          | Mesh node identity. Indexed. Not unique.          |
| `lat`      | double          | WGS-84 degrees, `[-90, 90]`.                      |
| `lon`      | double          | WGS-84 degrees, `[-180, 180]`.                    |
| `altitude` | double?         | Meters above ellipsoid, if reported.              |
| `heading`  | double?         | Degrees true, `[0, 360)`, if reported.            |
| `speedMps` | double?         | Ground speed in m/s, if reported.                 |
| `timestamp`| DateTime (UTC)  | Fix time. Indexed for range/pruning queries.      |
| `source`   | enum            | `direct` (from paired device) or `relayed` (ONP). |

- Stored via a composite `[nodeId, timestamp]` index so per-node history reads
  and time-window pruning are both cheap.
- **Retention (Phase 2):** unbounded per-node history is not sustainable. The
  pruning policy keeps at most `N` samples per node and drops samples older than
  a configurable window. The MVP writes history unbounded; pruning hooks are
  defined here so the schema does not change when retention lands.

---

## 3. Tile-Cache Model — `MapRegion`

Tiles live as files on disk (folders of `{z}/{x}/{y}.png`), mirroring how
Meshtastic's own map tooling stores tile packs. Isar only tracks *what* is
cached and *where*.

| Field          | Type           | Notes                                        |
|----------------|----------------|----------------------------------------------|
| `regionId`     | String         | Unique. Stable id for the tile pack.         |
| `minLat/minLon`| double         | South-west corner of the bounds.             |
| `maxLat/maxLon`| double         | North-east corner of the bounds.             |
| `minZoom`      | int            | Lowest zoom level present in the pack.       |
| `maxZoom`      | int            | Highest zoom level present in the pack.      |
| `style`        | String         | Tile style id (e.g. `osm`, `topo`).          |
| `sizeBytes`    | int            | On-disk size, for multi-pack management.     |
| `downloadedAt` | DateTime (UTC) | When the pack was fetched.                   |
| `storagePath`  | String         | Root folder holding `{z}/{x}/{y}` tiles.     |

### 3.1 Slippy-map tile addressing

Standard XYZ / slippy-map scheme. For zoom `z` there are `2^z` tiles per axis.

```
n = 2^z
xtile = floor( (lon + 180) / 360 * n )
ytile = floor( (1 - ln(tan(latRad) + sec(latRad)) / pi) / 2 * n )
```

A tile file resolves to `<storagePath>/<z>/<x>/<y>.png`. A `MapRegion` "covers"
a coordinate at zoom `z` when the coordinate falls inside its bounds and
`minZoom <= z <= maxZoom`.

---

## 4. Sonar / Radar Projection

The sonar view is **self-centered**: every node plots as *bearing + range from
you*, not on a rectangular map projection.

### 4.1 Geodesy (great-circle, spherical earth, R = 6371000 m)

- **Range** — haversine distance between self and node, in meters.
- **Bearing** — initial great-circle bearing from self to node, degrees true
  `[0, 360)`.
- **Velocity** — derived from two consecutive `NodePosition` samples:
  speed = distance / dt, course = bearing between the two samples. Used when the
  device does not report `speedMps`/`heading` directly.

### 4.2 Screen projection

Given a canvas of radius `R_px` centered on self and a `maxRangeMeters` scale:

```
r_px   = (rangeMeters / maxRangeMeters) * R_px      // clamped to R_px
theta  = bearingDeg - rotationOffsetDeg             // north-up => offset 0
x      = center.x + r_px * sin(theta_rad)
y      = center.y - r_px * cos(theta_rad)           // screen y grows downward
```

Nodes beyond `maxRangeMeters` are clamped to the outer ring and flagged
`clamped` so the UI can render them at the edge.

### 4.3 Range rings — auto-scaled

Concentric rings are sized to the farthest currently-tracked node (mesh members
range from ~10 m to ~20 km, so a fixed scale fails). The projector computes a
"nice" max range (rounded up to a 1/2/5 × 10ⁿ step) and evenly spaced ring radii.
A manual zoom override replaces the auto-scale with a fixed `maxRangeMeters`.

### 4.4 Active vs. stale

Each blip carries an `age` (now − last sample time). The projector classifies:

- `active` — within the recency window (default 2 min): rendered bright/pulsing.
- `stale` — older than the window but within the drop age (default 15 min):
  rendered faded.
- Past the drop age: excluded from the sonar view and surfaced in a "last seen"
  list instead.

These thresholds are inputs, not hard-coded, and in Phase 6 read directly off
ONP's last-heard tracking — no new data, just a new presentation.

### 4.5 Moving nodes

A node with ≥ 2 recent samples gets a **motion vector**: a short trail / heading
arrow computed from the last 2–3 `NodePosition` samples. This is the concrete
reason `NodePosition` is a history table.

### 4.6 Rotation mode

- **North-up** for the Phase 1 MVP — `rotationOffsetDeg = 0`, no sensor
  dependency.
- **Heading-up / track-up** rotates the whole view by the phone's compass
  heading (`rotationOffsetDeg = compassHeading`). Needs the magnetometer; it is
  a Phase 7 polish item, not MVP.

### 4.7 Interaction

- **Tap-to-detail.** Tapping a blip opens the *same* node detail sheet the
  Devices/Network workspaces use (name, distance, bearing, battery, last heard).
  Reuse it; do not rebuild it.
- **Toggle.** The Maps workspace toggles between the tile map and the sonar view
  over the same underlying node/position data.

---

## 5. `ocp_maps` Package Surface

Pure Dart, no widgets:

- `geo/` — `GeoPoint`, `GeoMath` (haversine range, initial bearing, velocity
  between samples).
- `tiles/` — `TileCoordinate`, `TileMath` (lat/lon ↔ tile), `TileProvider`
  interface + `MapRegionCoverage` helper.
- `sonar/` — `SonarSample`, `SonarBlip`, `SonarViewModel`, `SonarProjector`
  (range/bearing → screen, auto-scaled rings, active/stale, motion vectors).

Consumers (the app) adapt `ocp_core`'s `NodePosition` domain model into
`SonarSample` at the edge, keeping `ocp_maps` free of any storage/core coupling.

---

## 6. Test Path

Build and unit-test all math in `ocp_maps` against `tools/mock_position_feed`
(synthetic nodes on scripted paths — stationary, linear, and circular) *before*
wiring the projector to live `ocp_core` / ONP data. Same mock-first pattern used
for the ODP codec.
