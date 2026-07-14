# OCP-V1 Project Status

**Repo:** https://github.com/supercoded/OCP-V1  
**Last updated:** 2026-07-14  
**Process:** BMAD-style via workspace `_bmad/`

## Stack
- Electron + React + TypeScript + Tailwind CSS desktop app (primary)
- Flutter/Dart cross-platform app (migrating)
- Meshtastic protobufs via `protobufjs`
- JSON offline store with `LocalKeyCipher`
- npm workspaces

## Completed phases

### Phase 0 — Scaffolding ✅
- Monorepo layout in `apps/`, `packages/`, `specs/`, `scripts/`, `test/`

### Phase 1 — Core Services & Storage ✅
- `packages/offline-core/` — JSON file store, local key cipher

### Phase 2 — ODP Protocol ✅
- `packages/offline-core/src/protocol/` — models, phone API client

### Phase 3 — Transport Layer ✅
- TCP, serial, BLE transports + auto-discovery

### Phase 4 — Meshtastic Bridge ✅
- Codec, transport, firmware updater

### Phase 5 — ONP / Network Layer ✅
- NetworkState, RouteTable, onpCodec

### Phase 6 — Desktop UI ✅
- Electron + React + Tailwind app shell with INDI/ATA gray-black aesthetic
- 7 workspaces: Sonar, Messaging, Network, Devices, Spectrum, Map, Settings
- SonarPPI canvas with real node/blip rendering, color accents, GPS bearing/range when fix available
- Messaging wired to real `MeshtasticTransport` (TCP) — not stub discovery alone
- Network node table with live state, selection panel, connection banner
- Devices workspace (Connections, RuView, Firmware, Baofeng tabs)
- RTL-SDR spectrum with FFT + waterfall + bookmarks + peak hold + VFO + recording
- MapLibre full-color basemap (CARTO Voyager online + colorful PMTiles offline style) with node/sensing markers
- GPS `latitudeI`/`longitudeI` → degrees for map and sonar
- Baofeng channel editor with serial read/write
- Settings with connection status and tool checklist
- Windows NSIS installer + Linux AppImage/deb packaging

### Phase 7 — Plugin System ✅
- `packages/ocp_plugin_api/` (`@ocp/plugin-api`) — manifest validation, permissions, capabilities, `PluginHost` (install/uninstall/activate/deactivate)
- `packages/ocp_plugin_example/` (`@ocp/plugin-example`) — Diagnostics `status.provider` example plugin
- Electron `OcpService` hosts plugins in-process; Settings UI lists activate/deactivate + status snapshot
- IPC: `ocp:plugins:list|activate|deactivate|status`

### Phase 8 — Security ✅
- `PinVault` + upgraded `LocalKeyCipher` (scrypt + random salt, AES-256-GCM) in `@ocp/offline-core`
- `JsonFileOfflineStore` full-file encryption (`OCPENC1` envelope) when PIN unlocked
- CRC-32 helpers (`crc32` / `appendCrc32` / `verifyCrc32`)
- `NetworkState` sliding-window replay protection (`packetReplay` event)
- Electron LockScreen + Settings PIN controls (set / change / lock / clear)

### Flutter Migration ✅ (4 phases; parallel to desktop Phase 6–7)

#### Flutter Phase 1 — Scaffold ✅
- `apps/ocp_app/` Flutter project structure
- `packages/ocp_flutter_core/` shared theme package (OcpColors, OcpTheme, OcpTextStyles)
- Submarine/CIC dark aesthetic ported to Flutter
- OcpScaffold with sidebar navigation
- StatusLamp, AnalogButton, SidebarNavigation widgets
- Android platform dirs
- SonarPPI CustomPainter with sweep, blips, afterglow

#### Flutter Phase 2 — Real Pages ✅
- All 6 placeholder pages replaced with real implementations
- MessagingPage: channels, send/receive, auto-scroll, error banners
- NetworkPage: node table (ID, name, role, SNR, last heard), tap-to-highlight
- DevicesPage: 4 tabs (Connections, RuView, Firmware, Baofeng)
- SpectrumPage: FFT + waterfall CustomPainters, peak hold, VFO, bookmarks, recording
- MapPage: dark grid, node markers, layer toggles, zoom controls
- SettingsPage: connection status, tool checklist, app info, dark mode toggle
- SpectrumProvider, Bookmark model, updated providers

#### Flutter Phase 3 — Platform Bridges ✅
- PlatformService abstract interface
- WebSocketPlatformService (desktop: talks to Node.js bridge at ws://localhost:18790)
- MethodChannelPlatformService (mobile: talks to native Kotlin/Swift)
- Bridge server (Node.js) connecting Flutter to existing OCP packages
- Android PlatformPlugin.kt with MethodChannel + EventChannel handlers
- Linux C++ runner that launches bridge_server.js on app start
- All 5 providers wired to real data via PlatformService

#### Flutter Phase 4 — State Persistence ✅
- StorageService with shared_preferences backend
- AppSettings model with all configuration fields
- SettingsProvider with auto-persist on change
- Bookmark persistence in SpectrumProvider
- Channel memory persistence in MessagingProvider
- Connection history model and persistence
- SettingsPage wired to live SettingsProvider
- Splash/loading state on app init

## Architecture decisions

1. **Desktop UI:** Electron + React + Tailwind + Radix UI. Flutter for cross-platform/iOS.
2. **UI aesthetic:** Gray/black INDI/ATA operator console. Status colors (green/amber/red/cyan) for indicators only — no CRT scanlines or phosphor glow.
3. **Centerpiece:** Sonar PPI signal mapper.
4. **Flutter bridges:** Desktop uses WebSocket to Node.js bridge; mobile uses MethodChannel to native.
5. **Offline maps:** MapLibre GL JS (desktop) + PMTiles server; flutter_map planned for mobile.
6. **RTL-SDR:** rtl_tcp TCP streaming + kissfft-js FFT.
7. **Baofeng:** CHIRP-compatible 0xA5 serial protocol.
8. **State persistence:** shared_preferences for Flutter; localStorage for Electron.
9. **Plugins:** In-process `PluginHost` (`@ocp/plugin-api`) with install/uninstall, capability registration, and permission gating; example diagnostics plugin proves third-party usability.
10. **Security:** PIN vault (scrypt + HMAC verifier), AES-GCM encrypted offline DB, CRC-32 frame helpers, inbound packet replay window.

## Test status

```
# tests 92
# pass 92
# fail 0
```

Meshtastic bridge pins `protobufjs@^7` (root override); codec loads protos via `Root.loadSync` with `meshtastic/*.proto` import root.
## UI Theme
- **Electron + Flutter both on gray/black INDI/ATA palette** (as of 2026-07-14)
- Palette: bg=#111111, panel=#1a1a1a, text=#c8c8c8, bright=#e8e8e8, dim=#888888, muted=#666666
- Status colors only: green=#4caf50, amber=#d4a017, red=#c62828, cyan=#4fc3f7, blue=#42a5f5
- No glow effects, no CRT scanlines — flat professional operator console

## Known issues / limitations
- Desktop app cannot be visually verified on headless Pi; needs display.
- RuView requires Docker simulator or real ESP32-S3/C6 hardware.
- RTL-SDR requires external `rtl_tcp` binary.
- Windows icon not yet converted to `.ico` (PNG generated via `npm run generate:icon`; electron-builder can use PNG on some targets).
- Flutter app not yet compiled/verified (install Flutter SDK on this machine).
- OS keychain/keystore wrap for PIN-derived keys not yet implemented.
- Flutter PIN/plugin parity with Electron not in this pass (bridge listens on 127.0.0.1; message text path fixed).
- Electron Meshtastic connect is TCP-only in this build (serial/BLE factories not wired).

## Pending / Next priorities
1. **Phase 9 — Performance & Cross-Platform QA** (instrumentation + PRS §15 metrics) per `specs/build-plan.md`
2. Flutter SDK install and build verification (`flutter build windows`, `flutter build apk`)
3. Windows .ico + installer test on actual Windows
4. Integration smoke with real Meshtastic TCP (Devices → connect → Network/Sonar/Map/Messaging)
5. OS keychain/keystore wrap for PIN-derived keys (Phase 8 hardening)
6. Flutter PIN/plugin parity with desktop security model
7. Flutter offline raster tile pack (PMTiles/MVT remains desktop MapLibre-only)

## Recent corrections (2026-07-14)
- **Code-review remediation:** Meshtastic `0x94C3` framing + numeric `wantConfigId`; protobufjs v7 + real proto encode/decode; PortNum text; IPC unlock gate + lockout; `setPin`/`changePin` rewrap; map HTML escape; sonar decay; history persist/cap; localhost binds; plugin `state.read` gate
- Phase 8 security: PinVault, encrypted offline DB, CRC-32, NetworkState replay window, Electron LockScreen + Settings PIN UI
- Phase 7 plugin system: `@ocp/plugin-api` PluginHost + `@ocp/plugin-example` diagnostics status provider; Settings plugins panel
- Closed Phase 6 functional gaps: Electron `ocp:connect` uses `MeshtasticTransport` for TCP; GPS I-fields; message channel; Network workspace live table
- SonarPPI color accents (cyan rings, green N/self, amber sweep tip); GPS bearing/range via haversine when local + peer fix
- Map: CARTO Voyager online; colorful Protomaps-style offline `createOperatorStyle`
- Finished INDI/ATA theme migration leftovers (spectrum canvas, map markers, offline map style)
- Desktop MapCanvas: removed sensing pulse animation; map control colors use INDI palette (#111111 scale bar, neutral invert on nav buttons)
- Flutter MapPage: `flutter_map` + CARTO dark tiles; RuView sensing markers wired via `ConnectionProvider.ruViewSensing` with desktop-matching x/y→lat/lon projection; offline toggle dims tiles + snackbar (no fake localhost PMTiles)
- Flutter Baofeng channel editor (offline CSV, tone RX/TX dropdowns) replaces "coming soon" stub
- Android: removed BLUETOOTH_ADVERTISE; added `usesCleartextTraffic`; BLE/location/USB host permissions
- Desktop `icon.png` generator: `npm run generate:icon` (`scripts/generate-desktop-icon.cjs`)

## Blockers
- None.