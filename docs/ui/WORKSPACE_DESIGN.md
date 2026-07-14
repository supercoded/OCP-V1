# OCP-V1 Workspace UI Design

**Status:** design v2 — approved direction  
**Target:** Windows desktop first, iOS later  
**Stack:** Electron + React + TypeScript + Tailwind CSS + Radix UI primitives

## Direction update

Mike wants a **very nice looking, analog, tactile UI** with optional sound and a **submarine-style sonar signal mapper**. The sonar mapper is the centerpiece: a rotating sweep line that refreshes radio/Wi-Fi contacts as it passes over them, with distance rings and bearing. This replaces the conventional map as the primary "signal awareness" view.

## Core visual metaphor

- **INDI/ATA operator console:** gray/black dense UI (`#111` / `#1a1a1a`), muted text, status colors only for indicators.
- **Analog feel:** tactile dials and toggles without neon glow or CRT scanlines.
- **Tactile audio:** optional Web Audio sound layer for interactions and the sonar sweep ping.
- **Signal mapper:** circular PPI (Plan Position Indicator) radar/sonar display with:
  - Rotating sweep arm.
  - Concentric range rings.
  - Bearing grid (0–360°).
  - "Blips" for Meshtastic nodes, RTL-SDR peaks, and Wi-Fi probe targets.
  - Blips refresh as sweep passes (subtle trail, no phosphor glow).
  - Distance derived from RSSI or known GPS position.

## Stack

- **Electron** — desktop shell, main-process access to serial/SDR/Wi-Fi tools.
- **React 19 + TypeScript** — renderer UI.
- **Tailwind CSS v4** — utility styling.
- **Radix UI primitives** — accessible, unstyled components we theme ourselves.
- **Lucide icons** — monochrome line icons that fit the tactical look.
- **Web Audio API** — optional click/ping/tick sounds.
- **HTML5 Canvas** — sonar sweep and spectrum/waterfall.

## Top-level workspaces

| # | Workspace | Purpose | Primary screens |
|---|---|---|---|
| 1 | **Sonar** | Submarine-style signal mapper | PPI radar/sonar canvas, signal source selector, target list |
| 2 | **Messaging** | Offline chat | Channel list, conversation thread, compose, delivery status |
| 3 | **Network** | Mesh peer stats | Node list, node detail, SNR/RSSI charts, route table |
| 4 | **Devices** | Transport + firmware + radio | Device discovery, connect/disconnect, firmware updater, Baofeng code-plug editor |
| 5 | **Spectrum** | SDR visualization | rtl_tcp source config, FFT/waterfall, frequency bookmarks |
| 6 | **Map** | Conventional offline mapping | MapLibre/Leaflet view, node markers, waypoints, tracks |
| 7 | **Settings** | App + radio configuration | Channels, radio config, security/PIN, storage, logs, about |

**Sonar is workspace #1 and the default landing view.**

## Layout shell

```
┌────────────────────────────────────────────────────────────────────┐
│ Sidebar │  Main header (workspace title + status indicators)         │
│  ──────┼──────────────────────────────────────────────────────────────│
│  Sonar │                                                           │
│  Chat  │  [workspace content — Sonar fills most of the screen]      │
│  Net   │                                                           │
│  Gear  │                                                           │
│  ──────┴──────────────────────────────────────────────────────────────│
│  Status: ● Meshtastic · 3 nodes · Wi-Fi tracker: 8 blips · Sweep 12 RPM │
└────────────────────────────────────────────────────────────────────┘
```

Sidebar collapses to a rail of glowing icon buttons. Bottom status bar shows live telemetry.

## Sonar workspace (PPI mapper)

### Canvas elements
- **Sweep arm** rotating continuously at configurable RPM (default ~6–12 RPM).
- **Range rings** at 25/50/75/100% of max range; labels show distance units (meters / km / miles).
- **Bearing ticks** every 30° with N/E/S/W labels.
- **Blips** for each signal target:
  - Position: angle from self, radius from distance estimate.
  - Size/color by signal type and strength.
  - Glow/afterglow effect; brightness peaks as sweep passes, then decays.
- **Target legend** — toggles for Meshtastic nodes, RuView presence, RTL-SDR peaks, Baofeng hits, and mock demo blips.
- **Controls** — sweep speed, max range, audio on/off, pause/continue.

### Data sources
1. **Meshtastic nodes** — from `NetworkState` (node positions + RSSI/SNR).
2. **RuView presence / vitals** — WebSocket adapter (`packages/ocp_tools_ruview`) connecting to RuView sensing server (`ws://host:3001/ws/sensing`). Adds through-wall human presence, breathing, and heart-rate blips. Requires RuView Docker simulator or ESP32-S3/C6 CSI node.
3. **RTL-SDR peaks** — later, via `rtl_tcp` + FFT peak detection.
4. **Baofeng scan hits** — later, when scanning is implemented.

### Proposed signal layers on the sonar
- **Meshtastic layer** — green blips for known mesh nodes.
- **RuView presence layer** — red/orange heatmap blobs for through-wall human presence, with vitals tooltip.
- **SDR peak layer** — cyan blips for strong signals across the spectrum.
- **Baofeng layer** — magenta blips for analog radio hits.
- **Mock layer** — grey blips for offline demo.

Each layer can be toggled from the legend.

### Audio
- Soft sonar "ping" each time the sweep completes a full rotation (configurable).
- Subtle blip tone when a strong contact is refreshed.
- UI clicks for toggles and switches.

## Signal sources panel

A collapsible right panel in the Sonar workspace:
- Meshtastic connection card.
- RuView control: host/port, Docker simulator button, start/stop.
- RTL-SDR source: host/port/gain (placeholder).
- Baofeng scanner: placeholder.

## Component inventory

### Custom
- `SonarPPI` — main canvas component.
- `SweepControl` — RPM, range, audio toggles.
- `SignalLegend` — source filters.
- `TargetList` — table of detected contacts.
- `AnalogToggle` — big glowing toggle switch.
- `RotaryKnob` — optional rotary dial (CSS/Canvas).
- `StatusLamp` — LED-style indicator.

### Radix + Tailwind
- `Dialog` — modals for firmware flash, manual TCP entry.
- `DropdownMenu` — menus.
- `Tabs` — workspace sub-pages.
- `Slider` — gain/volume/sweep speed.
- `Tooltip` — hints.

## Theming

CSS variables in a new `apps/desktop/src/styles/theme.css`:

```css
:root {
  --ocp-bg: #050a0e;
  --ocp-panel: #0d161d;
  --ocp-panel-2: #14222d;
  --ocp-border: #1e3342;
  --ocp-text: #b8d4e3;
  --ocp-text-dim: #5a7a8a;
  --ocp-accent: #00f0a0;       /* sonar green */
  --ocp-amber: #ffaa00;        /* warning/amber */
  --ocp-red: #ff3333;          /* disconnected */
  --ocp-grid: #123040;
  --ocp-sweep: rgba(0, 240, 160, 0.35);
  --ocp-blip: rgba(0, 240, 160, 0.9);
}
```

Optional scanline overlay and subtle vignette for CRT feel.

## Data binding

```
Electron main
  ├─ serialport / native tools
  ├─ howmanypeoplearearound subprocess
  ├─ Node packages: offline-core, ocp_bridge_meshtastic, ocp_network
  └─ IPC API exposed to renderer
React renderer
  ├─ OcpServiceProvider
  ├─ SonarPPI (Canvas)
  ├─ Messaging / Network / Devices / Settings pages
  └─ AudioEngine
```

## First build scope

Small, visible, testable:
1. **Electron + React + Tailwind shell** with dark submarine theme.
2. **Sidebar** with 7 workspace icons; Sonar selected by default.
3. **SonarPPI canvas** — rotating sweep, range rings, bearing ticks, mock blips, afterglow.
4. **Sweep controls** — RPM slider, range selector, audio toggle.
5. **Mock data toggle** — show/hide fake blips so the UI looks alive without hardware.
6. **Devices workspace stub** — just a connect button placeholder.
7. **Tests** — canvas render tests via Playwright or component tests for controls.

## RuView Wi-Fi CSI integration

- Replaced the `howmanypeoplearearound` probe-sniffing approach with **RuView Wi-Fi CSI sensing**.
- Create `packages/ocp_tools_ruview/` with:
  - `ruviewClient.js` — WebSocket client for RuView sensing server (`ws://host:3001/ws/sensing`), emits `{nodeId, x, y, z, rssi, timestamp, source}` events.
  - `ruviewClient.test.js` — unit tests using a mock WebSocket server.
- SonarPPI consumes RuView `sensing_update` events as a signal source.
- Run the simulator locally with `bash scripts/run-ruview-simulator.sh` (Docker required).

## Files to create

- `apps/desktop/package.json`
- `apps/desktop/vite.config.ts`
- `apps/desktop/index.html`
- `apps/desktop/src/main.ts` (Electron main)
- `apps/desktop/src/main/services/ocpService.ts`
- `apps/desktop/src/preload.ts`
- `apps/desktop/src/renderer/main.tsx`
- `apps/desktop/src/renderer/App.tsx`
- `apps/desktop/src/renderer/components/Sidebar.tsx`
- `apps/desktop/src/renderer/components/SonarPPI.tsx`
- `apps/desktop/src/renderer/components/SweepControls.tsx`
- `apps/desktop/src/renderer/components/SignalLegend.tsx`
- `apps/desktop/src/renderer/components/AnalogToggle.tsx`
- `apps/desktop/src/renderer/contexts/OcpServiceContext.tsx`
- `apps/desktop/src/renderer/pages/SonarPage.tsx`
- `apps/desktop/src/renderer/pages/MessagingPage.tsx`
- `apps/desktop/src/renderer/pages/DevicesPage.tsx`
- `apps/desktop/src/renderer/styles/theme.css`
- `apps/desktop/src/renderer/hooks/useAudioEngine.ts`
- `packages/ocp_tools_ruview/package.json`
- `packages/ocp_tools_ruview/src/ruviewClient.js`
- `packages/ocp_tools_ruview/test/ruviewClient.test.js`
- `scripts/run-ruview-simulator.sh`

## Open questions

1. Do we bundle RuView or document its Docker/ESP32 deployment? (Document for now.)
2. Should the sonar distance use RuView 3D position (xy plane) or RSSI-only fallback? (Use position if present, fall back to RSSI distance estimate.)
3. How many targets before we start pruning? (Keep last 50 unique RuView node IDs, fade after timeout.)
4. Preferred distance units? (Meters/km/miles configurable; default meters.)
