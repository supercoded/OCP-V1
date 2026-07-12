# OCP-V1 Project Status

**Repo:** https://github.com/supercoded/OCP-V1  
**Last updated:** 2026-07-12  
**Process:** BMAD-style via workspace `_bmad/`

## Stack
- Flutter/Dart target monorepo (per specs)
- Current scaffold: Node.js/JS for desktop/mobile shells + offline-core + bridge
- **UI:** Electron + React + TypeScript + Tailwind CSS + Radix UI primitives, analog/submarine/sonar aesthetic
- Meshtastic protobufs via `protobufjs`
- JSON offline store with `LocalKeyCipher`
- npm workspaces

## Completed phases

### Phase 0 — Scaffolding ✅
- Monorepo layout in `apps/`, `packages/`, `specs/`, `scripts/`, `test/`
- README, package.json, build scripts

### Phase 1 — Core Services & Storage ✅
- `packages/offline-core/src/storage/jsonFileOfflineStore.js`
- `packages/offline-core/src/storage/localKeyCipher.js`
- `packages/offline-core/src/index.js`

### Phase 2 — ODP Protocol (mock-supported) ✅
- `packages/offline-core/src/protocol/models.js`
- `packages/offline-core/src/protocol/phoneApiClient.js`

### Phase 3 — Transport Layer ✅
- `packages/offline-core/src/transport/transportConnection.js`
- `packages/offline-core/src/transport/tcpTransportConnection.js`
- `packages/offline-core/src/transport/serialTransportConnection.js`
- `packages/offline-core/src/transport/bleTransportConnection.js`
- `packages/offline-core/src/transport/transportDiscovery.js` — auto-detect TCP → serial → BLE

### Phase 4 — Meshtastic Bridge ✅
- `packages/ocp_bridge_meshtastic/src/meshtasticCodec.js`
- `packages/ocp_bridge_meshtastic/src/meshtasticTransport.js`
- `packages/ocp_bridge_meshtastic/src/firmwareUpdater.js`
- `scripts/update-meshtastic-firmware.js`
- `test-rak-connection.js`
- `example-bridge.js`

### Phase 5 — ONP / Network Layer ✅ (first pass)
- `packages/ocp_network/` with NetworkState, RouteTable, onpCodec
- Wired into `meshtasticTransport.js`

### Phase 6 — UI — IN PROGRESS ✅ shell + sonar + devices + messaging + settings + packaging config built
- `apps/desktop/` Electron + React + Tailwind + Radix UI app shell.
- Submarine CIC theme with dark phosphor colors, CRT scanline overlay class, glow helpers.
- Left sidebar navigation with 7 workspaces: Sonar, Messaging, Network, Devices, Spectrum, Map, Settings.
- **SonarPPI** canvas component — rotating sweep arm, range rings, bearing grid, blips with afterglow, sweep-speed and range controls, optional audio ping per revolution.
- **Real data wiring:**
  - Electron main-process `OcpService` connects `NetworkState` + `RuViewClient` + `discoverTransport`.
  - IPC APIs: `ocp:connect`, `ocp:disconnect`, `ocp:ruview:start`, `ocp:ruview:stop`, `ocp:state`.
  - Renderer `OcpServiceContext` consumes IPC state + RuView sensing events.
  - SonarPPI renders real `NetworkState` nodes and RuView presence targets as blips.
  - Replaced the `howmanypeoplearearound` Wi-Fi probe tracker with RuView Wi-Fi CSI sensing.
- **Devices workspace** built with four tabs:
  - Connections: auto-detect/manual TCP/serial/BLE inputs, connect/disconnect, status lamp, node count.
  - RuView: host/port input, start/stop streaming, target count, simulator hint.
  - Firmware: CLI hints for `npm run firmware:list` / `npm run firmware:flash`.
  - Baofeng: placeholder for CHIRP-style memory editor.
- **Messaging workspace** built with:
  - Channel list with unread badges.
  - Message thread with sender bubbles, timestamps, delivery status.
  - Compose input + send button.
  - Mock data for now; ready for real ODP/Meshtastic integration.
- **Settings workspace** built with:
  - Live connection status summary.
  - External tool checklist (`esptool.py`, `nrfutil`, RTL-SDR, RuView Docker) with install commands.
- **Windows packaging** configured:
  - `electron-builder.yml` with NSIS installer + portable executable targets.
  - GitHub Actions workflow `.github/workflows/build-windows.yml` builds and releases `.exe` on tagged releases.
  - `apps/desktop/README.md` with download instructions.
- Stub pages for Network/Spectrum/Map.
- Desktop app builds successfully (`npm run desktop:build`) and local Linux unpack succeeded.

### Tools — RuView Wi-Fi CSI adapter ✅
- New package `packages/ocp_tools_ruview`.
- WebSocket client for RuView sensing server (`ws://host:3001/ws/sensing`).
- Parses `sensing_update` frames, emits presence events.
- Unit tests with mock WebSocket server.
- Simulator script: `scripts/run-ruview-simulator.sh`.

## Research completed

| Topic | Status | Source file |
|---|---|---|
| Meshtastic / RAK serial-protobuf API | ✅ | `RESEARCH_LOG.md` |
| Baofeng UV-5RM programming protocol | ✅ | `RESEARCH_LOG.md` |
| RTL-SDR spectrum options | ✅ | `RESEARCH_LOG.md` |
| Offline maps (MapLibre / MBTiles) | ✅ | `RESEARCH_LOG.md` |
| iOS USB/BLE bridge limitations | ✅ | `RESEARCH_LOG.md` |
| Windows desktop packaging | ✅ | `RESEARCH_LOG.md` |
| UI / workspace design | ✅ | `docs/ui/WORKSPACE_DESIGN.md` |
| RuView Wi-Fi CSI sensing | ✅ | `RESEARCH_LOG.md` |

## Architecture decisions

1. **Desktop UI:** Electron + React + Tailwind + Radix UI for Windows. Flutter remains iOS/cross-platform target later.
2. **UI aesthetic:** Analog, tactile, submarine CIC/sonar room. Dark slate background, green/amber phosphor accents, optional sound, CRT scanline overlay.
3. **Centerpiece:** Sonar PPI signal mapper — rotating sweep, range rings, bearings, blips for Meshtastic nodes / RuView presence / RTL-SDR peaks / Baofeng hits.
4. **RuView presence/vitals:** `packages/ocp_tools_ruview` connects to RuView sensing server WebSocket (`ws://host:3001/ws/sensing`) and feeds the Sonar mapper.
5. **Offline maps:** MapLibre Native + MBTiles.
6. **RTL-SDR:** `rtl_tcp` helper / gateway pattern.
7. **iOS support:** Requires a BLE or Wi-Fi gateway.
8. **Baofeng programming:** Serial abstraction mirroring CHIRP `0xA5` command format.
9. **Meshtastic serial mode:** Lock to PROTO.
10. **MBTiles storage:** Host app-documents storage via `path_provider` / `app.getPath('userData')`.
11. **Firmware flashing:** Fetch from `meshtastic/firmware` releases; flash with external `esptool.py`/`nrfutil`.

## Test status

```
# tests 24
# pass 24
# fail 0
```

Includes all original tests plus new transport auto-discovery, firmware updater, ONP network, and RuView client tests.

## Known issues / limitations
- `test-rak-connection.js` still tries a hardcoded IP and takes ~11s to fail gracefully.
- `serialTransportConnection.js` and `bleTransportConnection.js` are stubs.
- Firmware updater requires external `esptool.py` or `nrfutil`.
- ONP codec is JSON-based in the JS scaffold.
- Desktop app builds but cannot be visually verified on the arm64 Pi headless environment; requires Windows display to run.
- RuView integration requires the RuView Docker simulator or an ESP32-S3/C6 CSI node; the OCP-V1 app only provides the WebSocket client.
- Windows icon (`build/icon.ico`) is not yet generated; installer will use the default Electron icon until an `.ico` is added.

## Pending phases / features

### Phase 6 — UI (continued)
- Add CRT overlay toggle and sound engine polish.
- MapLibre offline map view.
- Spectrum FFT/waterfall canvas.
- Baofeng channel editor.

### RTL-SDR spectrum
- `rtl_tcp` source + FFT/waterfall canvas.

### Baofeng programming
- Channel editor + serial read/write.

### Flutter migration
- Long-term cross-platform/iOS target.

## Blockers
- None.

## Next priorities
1. Spectrum FFT/waterfall canvas.
2. Baofeng channel editor.
3. MapLibre offline map view.
4. Add proper Windows `.ico` and test the installer on a Windows machine.
5. Wire Messaging workspace to real Meshtastic/ODP send/receive.
