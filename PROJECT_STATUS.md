# OCP-V1 Project Status

**Repo:** https://github.com/supercoded/OCP-V1  
**Last updated:** 2026-07-12  
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
- Electron + React + Tailwind app shell with submarine/CIC dark aesthetic
- 7 workspaces: Sonar, Messaging, Network, Devices, Spectrum, Map, Settings
- SonarPPI canvas with real node/blip rendering
- Messaging wired to real Meshtastic transport
- Network node table with live state
- Devices workspace (Connections, RuView, Firmware, Baofeng tabs)
- RTL-SDR spectrum with FFT + waterfall + bookmarks + peak hold + VFO + recording
- MapLibre offline map with node markers and RuView sensing overlay + PMTiles server
- Baofeng channel editor with serial read/write
- Settings with connection status and tool checklist
- Windows NSIS installer + Linux AppImage/deb packaging

### Phase 7 — Flutter Migration ✅ (4 phases)

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
2. **UI aesthetic:** Submarine CIC/sonar room — dark slate, green/amber phosphor, CRT scanlines.
3. **Centerpiece:** Sonar PPI signal mapper.
4. **Flutter bridges:** Desktop uses WebSocket to Node.js bridge; mobile uses MethodChannel to native.
5. **Offline maps:** MapLibre GL JS (desktop) + PMTiles server; flutter_map planned for mobile.
6. **RTL-SDR:** rtl_tcp TCP streaming + kissfft-js FFT.
7. **Baofeng:** CHIRP-compatible 0xA5 serial protocol.
8. **State persistence:** shared_preferences for Flutter; localStorage for Electron.

## Test status

```
# tests 26
# pass 26
# fail 0
```

## Known issues / limitations
- Desktop app cannot be visually verified on headless Pi; needs display.
- RuView requires Docker simulator or real ESP32-S3/C6 hardware.
- RTL-SDR requires external `rtl_tcp` binary.
- Windows icon not yet generated (uses Electron default).
- Flutter app not yet compiled/verified (no Flutter SDK on Pi).

## Pending / Next priorities
1. Flutter build verification — get `flutter build linux` and `flutter build apk` compiling
2. Windows .ico + installer test on actual Windows
3. Flutter mobile platform configs (iOS/Android permissions, navigation)
4. Integration testing with real hardware

## Blockers
- None.