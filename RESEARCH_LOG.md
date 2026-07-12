# OCP-V1 Research Log

**Repo:** https://github.com/supercoded/OCP-V1  
**Process:** BMAD-style via workspace `_bmad/`

---

## 2026-07-12 — Initial repo inspection

### Sources
- `https://github.com/supercoded/OCP-V1` (cloned)
- `specs/build-plan.md`
- `specs/PROJECT_CHARTER.md`
- `specs/PRODUCT_REQUIREMENTS_SPECIFICATION_V2.md`
- `docs/offline-app/target-order.md`
- `docs/offline-app/mvp-scope.md`
- `IMPLEMENTATION-SUMMARY.md`
- `README.md`

### Findings
1. **Stack is Flutter/Dart by spec, but current scaffold is Node.js.** The Node scaffold is a functional prototype of core + bridge, not the final Flutter app.
2. **Build plan is already well-defined** in `specs/build-plan.md` with 10 phases (0–9).
3. **Phase 4 (Meshtastic bridge) is complete** in the Node scaffold, including TCP transport and protobuf codec.
4. **Platform order:** Android + desktop first, iOS/macOS later.
5. **MVP scope is constrained** to offline messaging loop; cloud, rich media, plugin marketplace, production signing excluded.
6. **Baofeng and RTL-SDR are not yet represented** in repo or specs.

### Decisions made
- None yet — awaiting Mike's priority pick.

### Open questions
1. Is the Node.js scaffold a throwaway prototype or a target runtime for desktop?
2. Should next work be Phase 5 (ONP), Phase 6 (UI), or Baofeng/SDR research?
3. Which physical Baofeng programming cable is available?

---

## 2026-07-12 — Meshtastic / RAK research

### Sources
- Meshtastic protobufs repo — https://github.com/meshtastic/protobufs
- Meshtastic Python CLI `stream_interface.py` — https://github.com/meshtastic/python/blob/master/meshtastic/stream_interface.py
- Meshtastic Apple client (BLE/TCP/serial) — https://github.com/meshtastic/Meshtastic-Apple
- RAK WisBlock product pages and docs (vendor site, known-good configurations)

### Key findings
1. **Protocol framing.** Meshtastic uses protobuf `ToRadio` / `FromRadio` messages wrapped in a simple length-delimited (varint) stream. The Python `stream_interface.py` implements `_sendToRadio` and `_readFromRadio` using this framing.
2. **Transport options.** RAK WisBlock modules can expose:
   - **USB serial** (CP210x or CH340 depending on base board) at **921600 baud** for the main debug/protobuf interface.
   - **BLE** GATT serial using a Meshtastic-specific service.
   - **TCP** when the module is on a Wi-Fi/Ethernet network (e.g., RAK13300 / Ethernet or a station with Wi-Fi).
3. **Protobuf source of truth.** The canonical protobuf files live in `meshtastic/protobufs`; generated packages exist for TypeScript, Rust, Kotlin Multiplatform, etc.
4. **Current OCP-V1 scaffold.** The repo already has `meshtasticCodec.js` using `protobufjs` and `meshtasticTransport.js` implementing TCP framing and reconnect. This is aligned with Meshtastic's stream model.

### Current-implementation gaps
- **Serial and BLE adapters are stubs.** `serialTransportConnection.js` and `bleTransportConnection.js` only contain `io.connect/io.write` injection hooks; they do not call any real serial/BLE library.
- **Protobuf root import path.** The Node test currently fails because `protobufjs` is not installed; the package dependency needs to be declared in the workspace.
- **No device auto-detection.** The TCP test script (`test-rak-connection.js`) requires a manual IP/port.

### Recommendation
1. Add `protobufjs` and a serial library (`serialport` for desktop, a Flutter plugin for mobile) to the workspace dependencies.
2. Implement real `connect()` in `serialTransportConnection.js` and `bleTransportConnection.js`.
3. Build a **transport auto-discovery** layer that tries TCP → serial → BLE in order, using the existing abstraction.
4. Consider generating TypeScript types from `meshtastic/protobufs` instead of hand-rolling them.

---

## 2026-07-12 — Baofeng UV-5RM research

### Sources
- CHIRP uv5r driver (GitHub kk7ds/chirp) – https://github.com/kk7ds/chirp/blob/master/chirp/drivers/uv5r.py
- BTECH PC03 FTDI USB‑A programming cable page – https://baofengtech.com/product/pc03/
- Baofeng official download area – https://www.baofengradio.com/pages/download
- Baofeng UV‑5R programming guide (CHIRP‑compatible) – https://www.baofengradio.com/blogs/news/how-to-program-baofeng-uv-5r-series-with-programming-software
- CHIRP issue “No ACK on protocol‑specific command” – https://chirpmyradio.com/issues/11997
- Miklor CHIRP notes – https://www.miklor.com/COM/UV_CHIRP.php

### Protocol summary (CHIRP driver)
- Serial communication at **9600 baud**, 8N1 (see `BAUD_RATE = 9600` in driver).
- Commands are sent as binary packets prefixed with a *magic* byte (`0xA5`) and length – see `_do_ident` and `_read_block` helpers.
- Typical flow:
  1. **Identify** – send 0xA5 0x00 0x00 0x00 0x00, wait for ACK (`0xA5` response) – `_ident_radio`.
  2. **Read block** – `_read_block(radio, start, size, first_command=True)` sends a 5-byte command `[0xA5, start_low, start_high, size_low, size_high]` and reads the returned bytes.
  3. **Write block** – `_send_block(radio, addr, data)` builds a packet `[0xA5, addr_low, addr_high, len_low, len_high] + data` and writes it.
  4. **Upload / Download** – driver loops over memory map ranges (`_ranges_main`, `_ranges_aux`) using the above commands.
- The driver expects the radio to respond with the same magic byte; if not, CHIRP reports *“no ACK on protocol-specific command”* (see CHIRP issue #11997).

### Cable / Serial chip
- The widely-sold **BTECH PC03** cable uses an **FTDI FT232RL** chipset (gold-standard USB-to-UART). It is plug-and-play on Windows 10/11, macOS 14+, and major Linux distros – drivers install automatically via WinUSB or FTDI VCP.
- No special driver is required for the FT232RL; the cable presents a virtual COM port (e.g., `COM3` on Windows, `/dev/ttyUSB0` on Linux).
- Alternate cheap “clone” cables often use a **CH340** or **Prolific PL2303** chip; these can cause flaky detection on newer OSes and may need manual driver installation (Zadig on Windows, `usb-serial` on Linux).
- The FT232RL works reliably with CHIRP’s serial layer (`serial.Serial(port, 9600, timeout=1)`).

### Command / address format
- Addresses are 16-bit offsets into the radio’s EEPROM.
- Commands are 5 bytes: **[MAGIC, ADDR_LOW, ADDR_HIGH, SIZE_LOW, SIZE_HIGH]**.
- Read returns raw EEPROM bytes; write sends the same header followed by payload.
- The driver defines `MEM_FORMAT` blocks that map to frequency entries, CTCSS/DCS tones, offsets, power levels, etc.
- No high-level “clone-mode only” restriction – the driver can both **read** and **write** arbitrary EEPROM blocks, provided the cable presents a true UART interface.

### Legal / frequency constraints
- Baofeng radios are **FCC Part 90** (GMRS/FRS) and **Part 97** (ham) capable; users must only program frequencies they are licensed for.
- The UV-5RM includes a **GPS-enabled version**; programming GPS channels also requires compliance with local regulations.
- CHIRP includes a *frequency-restriction* warning (see Miklor notes) that blocks non-licensed bands unless the user disables the check.
- The official Baofeng CPS software ships with a “locked-region” list – attempting to program restricted bands will be rejected.

### Repo gap
- OCP-V1 currently has no **radio-programming module** nor any **serial-port abstraction** for Baofeng.
- No **USB-cable detection** or driver-installation instructions are documented.
- UI is missing a **channel editor** (import/export of CHIRP code-plug format) and a **spectrum view** for validation.

### Recommendation
1. **Add a serial abstraction** (e.g., `serialport` npm package) that mirrors CHIRP’s command format (magic + addr + size).
2. Bundle the **FTDI driver notice** and a short *Zadig* guide for Windows users.
3. Implement a **basic read-write service** exposing:
   - `listPorts()` → available COM/tty devices.
   - `readMemory(start, length)`.
   - `writeMemory(start, Buffer)`.
4. Create a UI for channel list editing, re-using CHIRP’s CSV format.
5. Document the **legal constraints** clearly in the UI (license check dialog).
6. Write unit tests that mock the serial layer using the command packet format.

---

## 2026-07-12 — RTL-SDR research

### Sources
- osmocom rtl-sdr — https://github.com/osmocom/rtl-sdr
- rtl_433 — https://github.com/merbanan/rtl_433
- SoapySDR — https://github.com/pothosware/SoapySDR
- Meshtastic Apple client signal-meter / telemetry patterns (referenced for RSSI/SNR display)

### Key findings
1. **Hardware interface.** RTL-SDR dongles are Realtek RTL2832U-based DVB-T receivers. On Windows they need the **Zadig WinUSB/libusb driver** (not the default DVB driver) so user-mode code can open them.
2. **Two common integration patterns:**
   - **Local librtlsdr:** Link or bundle `librtlsdr` in a native plugin, open the dongle directly, stream IQ samples. Good for low latency but requires platform-specific binaries.
   - **rtl_tcp / SoapySDR remote:** Run a small helper (`rtl_tcp` or SoapyRemote) on the same machine or a Pi gateway, stream IQ/power data over TCP. Easier for cross-platform apps because the app only needs a socket.
3. **Spectrum data.** For visualization, the typical pipeline is: IQ samples → FFT → magnitude → waterfall/line plot. Sample rates commonly 0.25–2.4 MSPS. A 1024-bin FFT at 1 MSPS gives ~1 kHz resolution bins.
4. **Signal stats.** RSSI can be estimated from FFT magnitude or from the RTL-SDR AGC/gain reports. rtl_433 shows the standard approach: tune, gain, sample, FFT/demod.
5. **OCP-V1 relevance.** RTL-SDR is not yet in the repo. It can be added later as a separate plugin/package so the core app does not depend on native SDR libraries.

### Recommended stack for OCP-V1
1. **Phase 1:** `rtl_tcp` helper. App connects to `localhost:1234`, reads raw IQ, runs FFT in-process (or in a Web Worker / isolate). No platform driver bundling in the main app.
2. **Phase 2 (embedded):** Run `rtl_tcp` on the Raspberry Pi gateway and stream IQ to the phone/desktop over Wi-Fi/BLE.
3. **Windows packaging:** bundle `rtl_tcp.exe` and a Zadig guide in the installer.

### Open questions
- Is the immediate need wideband spectrum or narrowband power-meter for Meshtastic channels?
- Do we want to record/store spectrum snapshots offline?
- Is arm64 Pi performance sufficient for streaming FFT to the app?

---

## 2026-07-12 — Offline maps research

### Sources
- MapLibre Native — https://github.com/maplibre/maplibre-native
- MBTiles spec — https://github.com/mapbox/mbtiles-spec
- MapLibre Compose — https://github.com/maplibre/maplibre-compose
- Flutter desktop docs — https://docs.flutter.dev/platform-integration/desktop

### Key findings
1. **MapLibre is the de facto open offline map stack.** Forked from Mapbox GL Native, BSD-licensed, supports Android, iOS, macOS, Linux, Windows, Qt, and Node.
2. **MBTiles** is a SQLite container for vector or raster tiles in Spherical Mercator. One file = one tileset. Offline maps mean shipping/downloading MBTiles files to the device.
3. **Flutter integration options:**
   - **MapLibre Native iOS/Android** via platform views.
   - **MapLibre Compose** for Compose Multiplatform (Android + iOS + desktop partially supported as of 2025).
   - **Flutter map packages** (`flutter_map` with MBTiles plugin) are lighter but raster-only and less performant.
4. **Tile sources.** Generating MBTiles requires tooling like `tilemaker`, `tippecanoe`, or downloading from providers like OpenMapTiles / MapTiler. Vector tiles are smaller; a regional map can be tens to hundreds of MB.
5. **Offline limitations.** Geocoding and routing generally require separate offline datasets; the map view itself is the easiest part.

### Recommended stack for OCP-V1
- **Target:** MapLibre Native through a Flutter plugin or MapLibre Compose for cross-platform.
- **Tile storage:** MBTiles bundled in app assets or downloaded to app documents.
- **Data overlay:** GeoJSON layers for nodes, waypoints, signal circles, and triangulation lines.

### Open questions
- Which regions need pre-bundled maps?
- Do we need offline routing/geocoding, or just position + track display?
- How should large MBTiles be distributed (app bundle vs side-load vs download)?

---

## 2026-07-12 — iOS bridge research

### Sources
- Apple External Accessory docs — https://developer.apple.com/documentation/externalaccessory
- Apple Core Bluetooth docs — https://developer.apple.com/documentation/corebluetooth
- Meshtastic Apple client — https://github.com/meshtastic/Meshtastic-Apple

### Key findings
1. **USB serial on iOS is effectively closed.** The External Accessory framework requires MFi certification for most USB accessories. Generic USB-serial chips (FTDI, CH340, CP210x) are **not** directly usable by third-party apps on iOS unless wrapped in an MFi-compliant accessory.
2. **BLE is the realistic path.** iOS Core Bluetooth supports standard BLE GATT. Meshtastic uses a custom BLE GATT service; the official Meshtastic iOS app connects this way.
3. **USB SDR is not feasible on iPhone.** RTL-SDR dongles need libusb/WinUSB access, which iOS does not grant to App Store apps. The only route is an external gateway that streams SDR data to the phone.
4. **Bridge architecture.** A small ESP32 or Raspberry Pi gateway sits between the physical radios and the iPhone:
   - Gateway exposes a BLE GATT serial service or a local Wi-Fi API.
   - iPhone app uses Core Bluetooth or TCP to talk to the gateway.
   - Gateway handles the actual USB/serial/SDR hardware.

### Recommended bridge for OCP-V1 iOS
- **Short term:** Same ESP32 or Pi device that runs the Meshtastic firmware can also expose a BLE pass-through to the iPhone.
- **Long term:** Standardize on a small Raspberry Pi Zero 2 W or ESP32-S3 gateway with:
  - BLE GATT serial for Meshtastic packets.
  - USB host for Baofeng cable / RTL-SDR.
  - Local Wi-Fi API for bulk data (maps, code-plugs, spectrum IQ).

### Open questions
- Does Mike want to build/buy a gateway, or use an existing Meshtastic device as the bridge?
- Should the gateway protocol be the same protobuf `ToRadio/FromRadio` stream used on desktop?
- How is the gateway powered in the field?

---

## 2026-07-12 — Windows desktop packaging research

### Sources
- Flutter desktop docs — https://docs.flutter.dev/platform-integration/desktop
- MapLibre Native Windows build docs — https://github.com/maplibre/maplibre-native (platform/windows)
- Electron/Tauri general knowledge

### Key findings
| Option | USB serial | BLE | Native modules | Offline | Build complexity | Distribution |
|---|---|---|---|---|---|---|
| **Flutter Desktop** | Via platform plugins (`flutter_libserialport`) | Via `flutter_blue_plus` / platform views | C++ federated plugins | Yes | Medium | `flutter build windows` → MSI/MSIX installer |
| **Electron** | Via `serialport` npm | Via Web Bluetooth (limited) or Node native | Node native addons | Yes | Low | electron-builder → NSIS/MSI |
| **Tauri** | Rust sidecar + serial crate | Rust BLE crates / Web Bluetooth | Rust plugins | Yes | Medium | tauri-build → MSI/MSIX |
| **React Native Windows** | Native modules | Native modules | Possible | Yes | High | MSIX |

### Recommendation
- **Primary: Flutter Desktop.** Aligns with the existing OCP-V1 spec (Flutter/Dart monorepo), lets the same code target Android, iOS, and desktop, and has a clean federated-plugin model for USB serial and BLE.
- **Secondary: Tauri** if we ever need to reuse the existing Node.js `offline-core` packages as a sidecar.

### Open questions
- Does the team already have Flutter desktop toolchain installed on Windows?
- Which plugin will be used for USB serial (`flutter_libserialport`, custom FFI)?
- Installer format preference: MSIX, MSI, or portable ZIP?
- Code-signing certificate for Windows SmartScreen?

---

## 2026-07-12 — Wi-Fi person tracking tool research

### Sources
- `schollz/howmanypeoplearearound` — https://github.com/schollz/howmanypeoplearearound
- `schollz/find-lf` (related multi-node localization) — https://github.com/schollz/find-lf
- `kismetwireless/kismet` — https://github.com/kismetwireless/kismet

### Key findings
- **howmanypeoplearearound** counts nearby people by sniffing Wi-Fi probe requests with a monitor-mode capable adapter.
- CLI outputs JSON with `mac`, `rssi`, and `company` (OUI lookup).
- Supports `--loop`, `--jsonprint`, `--scantime`, `--adapter`, and `--out` options.
- Depends on `tshark` (Wireshark CLI) and a compatible USB Wi-Fi adapter (Atheros AR9271, Ralink RT3070/3572/5572, etc.).
- Includes a built-in `index.html` analyzer for visualizing counts over time.
- **find-lf** extends the same idea with multiple Raspberry Pi nodes for indoor localization.

### Recommendation
- Add `howmanypeoplearearound` as an external tool dependency.
- Create a Node wrapper package `packages/ocp_tools_wifi_tracker` that spawns the CLI, parses JSON, and emits events.
- Feed the detected probe targets into the Sonar signal mapper as blips, with distance estimated from RSSI.
- For multi-node triangulation later, evaluate `find-lf` or Kismet.

### Open questions
- What Wi-Fi adapter is available on the Windows test machine?
- Should we bundle/document `Npcap`/`WinPcap` for `tshark` on Windows?
- Is person-counting or per-MAC tracking the desired default?

---

## 2026-07-12 — RuView Wi-Fi CSI sensing research

### Source
- Main repo: https://github.com/ruvnet/RuView
- Search results: https://github.com/search?q=ruview&type=repositories
- Hugging Face model: https://huggingface.co/ruvnet/wifi-densepose-pretrained
- PyPI packages: `ruview`, `wifi-densepose`

### What RuView does
RuView turns commodity Wi-Fi signals into spatial intelligence using **Channel State Information (CSI)** — the fine-grained radio measurements that describe how Wi-Fi waves bounce around a room.

Capabilities:
- **Presence / occupancy detection** through walls and in the dark.
- **Vital signs:** breathing rate (6–30 BPM) and heart rate (40–120 BPM), contactless.
- **Activity / gesture / fall detection** from temporal CSI patterns.
- **Multi-person counting** with adaptive normalization.
- **17-keypoint human pose estimation** via Wi-Fi-DensePose.
- **Environment mapping / RF fingerprinting** to detect moved furniture or new objects.
- **Sleep monitoring** with stage classification and apnea screening.

### Hardware
- Primary: **ESP32-S3** (~$9) flashed with RuView CSI firmware.
- Research option: **ESP32-C6** for Wi-Fi 6 / 802.15.4.
- Fallback: any Wi-Fi laptop / USB adapter gives **RSSI-only** coarse presence (no CSI).

### Software architecture
- **Edge:** ESP32 firmware captures CSI and streams it.
- **Server:** Python/Rust sensing server (`wifi-densepose` crate, Docker image `ruvnet/wifi-densepose`).
- **Models:** Pretrained on Hugging Face; tiny quantized variants (4-bit = 8 KB, fits on ESP32-class edge).
- **Integrations:** Home Assistant via MQTT, Apple Home / Google Home / Alexa / SmartThings / Matter bridge.
- **APIs:** WebSocket + MQTT clients; PyPI package `ruview`.

### Relevance to OCP-V1
RuView is a **natural upgrade** for the sonar/presence layer:

| Current OCP-V1 tool | What it gives | RuView upgrade |
|---|---|---|
| `howmanypeoplearearound` (probe sniffing) | Detects smartphones when they broadcast Wi-Fi probe requests. Modern phones randomize MACs and suppress probes, so coverage is spotty. | Detects **any person** via Wi-Fi reflections, even without a phone, through walls, in the dark. |
| Meshtastic node RSSI | Coarse distance/direction of known radio nodes. | RuView adds **fine-grained indoor presence/vitals** as another signal source on the sonar. |
| RTL-SDR (planned) | Wideband spectrum peaks. | RuView is a **narrowband, indoor, human-optimized** sensor that complements SDR. |

### Integration options (ranked by difficulty)
1. **MQTT bridge (easiest):** If RuView is already running on the network (e.g., Home Assistant), OCP-V1 subscribes to the MQTT topics and plots presence/vitals on the sonar.
2. **Docker sidecar:** Run `ruvnet/wifi-densepose` locally; OCP-V1 connects to its HTTP/WebSocket API. Simulated data available without hardware.
3. **ESP32 + OCP-V1 bridge:** Flash ESP32-S3 with RuView firmware, stream CSI to OCP-V1 over UDP/WebSocket. Requires firmware build + CSI parser in OCP-V1.
4. **Embed Python `ruview` package:** Use the PyPI wheel for breathing/heart-rate extractors on a Pi/PC attached to an ESP32 node.

### Recommendation
- **Short term:** Keep `howmanypeoplearearound` as the immediate Wi-Fi person tracker in OCP-V1 — it works with cheap USB adapters and is easy to deploy.
- **Medium term:** Add a **RuView adapter module** (`packages/ocp_tools_ruview`) that consumes RuView MQTT/WebSocket output and converts it into sonar blips + a vitals panel. Start with the Docker simulator so development doesn't block on hardware.
- **Long term:** Integrate an ESP32-S3 RuView node as a fixed-position sensor in the OCP-V1 base station, feeding the submarine sonar with persistent indoor presence data.

### Risks
- RuView is a large, research-heavy project with many moving parts and some gaps (e.g., JSONL model loader issue noted in README).
- Real performance depends heavily on environment, antenna placement, and calibration.
- Legal/privacy implications of presence/vitals sensing should be documented for users.

### Open questions
- Do we want to add a RuView adapter package now, or keep it as a documented future path?
- Should the sonar show a separate "human presence" layer distinct from Wi-Fi probes?

---

## Next research passes (pending)

- Meshtastic protobuf code generation for TypeScript/Dart
- RAK module firmware flashing and Wi-Fi/Ethernet configuration
- Baofeng UV-5RM memory-map full decode
- RTL-SDR FFT libraries suitable for Flutter/Web/Node
- MBTiles generation workflow and storage limits on mobile
- Electron audio engine / Web Audio best practices for tactile UI sounds
- RuView MQTT/WebSocket API details and Docker simulator behavior

---

## 2026-07-12 — UI / workspace design research

### Sources
- Meshtastic Android repo — https://github.com/meshtastic/Meshtastic-Android
  - `feature/messaging`, `feature/connections`, `feature/map`, `feature/node`, `feature/settings`
- Meshtastic web/JS monorepo — https://github.com/meshtastic/web
  - `packages/sdk` feature slices: device, chat, nodes, channels, config, telemetry, position, traceroute
- CHIRP repo — https://github.com/kk7ds/chirp
- SDR++ repo — https://github.com/AlexandreRouma/SDRPlusPlus
- shadcn/ui repo and sidebar docs — https://github.com/shadcn-ui/ui, https://ui.shadcn.com/docs/components/sidebar
- OCP-V1 specs: `specs/build-plan.md`, `specs/PRODUCT_REQUIREMENTS_SPECIFICATION_V2.md`

### Key findings

#### 1. Popular Meshtastic-style workspace split
The Meshtastic Android client uses feature modules that map cleanly to bottom/tab or sidebar navigation:

| Feature | Purpose | Key screens / components |
|---|---|---|
| **Connections** | Transport discovery & selection | BLE scan, USB serial list, TCP manual entry, connect/disconnect, transport selector |
| **Messaging** | Chat | Channel list, DM list, message thread, reactions, delivery status |
| **Nodes** | Peer list & detail | Node list with SNR/RSSI/last-heard, node detail, telemetry charts, compass |
| **Map** | Offline map + overlays | Node markers, waypoints, GPS tracks, traceroute lines |
| **Settings** | Device config + app prefs | Radio config, channels, firmware update, security, notifications |

The Meshtastic web client uses a similar left-rail navigation and a domain-driven SDK split: `device`, `chat`, `nodes`, `channels`, `config`, `telemetry`, `position`, `traceroute`.

#### 2. CHIRP / radio programming UI patterns
CHIRP is a classic desktop grid editor:
- **Port selection** dropdown + clone/download/upload action buttons.
- **Memory editor** table: channel #, frequency, name, tone, mode, offset, tx power, etc.
- **Import/export** CSV/code-plug files.
- **Live status log** for serial commands and errors.

#### 3. SDR++ / spectrum UI patterns
SDR++ uses a dockable, modular layout:
- **Source selector** (rtl_tcp, rtl_sdr, etc.).
- **Frequency manager** with bookmarks.
- **Waterfall + FFT** spectrum view.
- **VFOs** for selecting channels.
- **Recorder / scanner** modules.
- **Module list** in config.json.

For OCP-V1 this suggests a **Spectrum workspace** with: source config, center frequency, gain, FFT/waterfall, VFOs for Meshtastic channels, signal strength log.

#### 4. shadcn/ui desktop patterns
- **Sidebar layout** is the canonical shadcn app shell: collapsible rail, groups, menu badges, footer for user/settings.
- **Theme tokens** via CSS variables in `:root`/`.dark`.
- **CLI workflow**: `npx shadcn add <component>` copies source into `components/ui/`, Tailwind v4 / React 19 in the v4 canary.
- Relevant components for OCP-V1: sidebar, table, card, tabs, dialog, dropdown-menu, badge, skeleton, toast/sonner, chart.

#### 5. Stack tension
- The OCP-V1 **specs** call for a Flutter/Dart monorepo (Phase 6 UI in `apps/ocp_app`).
- The **current scaffold** is Node.js + JS packages, and Mike explicitly wants shadcn / web-tooling.
- The **fastest path to a working Windows UI** is Electron + React + shadcn/ui wrapping the existing JS packages.
- A **Flutter UI** would require rewriting the packages in Dart or calling them through FFI/sidecar, delaying visible progress.

### Recommendation

**For Phase 6 on Windows:** build an **Electron + React + TypeScript + shadcn/ui** desktop app inside `apps/desktop/`. This:
- Uses the tools Mike asked for (shadcn CLI, Tailwind, React).
- Reuses the existing Node.js `offline-core`, `ocp_bridge_meshtastic`, `ocp_network` packages directly.
- Can access `serialport`, `protobufjs`, native flashing tools via Node/Electron main process.
- Supports offline operation and can be packaged with `electron-builder` into an MSI/EXE installer.

**For iPhone later:** keep the Flutter/Dart target as the cross-platform plan. The Electron UI and business logic can be migrated or wrapped as a sidecar once the Dart layers exist.

### Proposed OCP-V1 workspaces (top-level nav items)
1. **Dashboard** — connection status, node count, recent messages, spectrum preview, quick actions.
2. **Messaging** — channel list, conversation threads, compose, delivery status.
3. **Network** — node list, node detail, link-quality stats, route table, signal triangulation.
4. **Devices** — transport discovery (TCP/serial/BLE), connect/disconnect, firmware updater, Baofeng programming.
5. **Spectrum** — RTL-SDR/rtl_tcp source, FFT/waterfall, frequency bookmarks, VFOs.
6. **Map** — offline MapLibre map, node positions, waypoints, tracks, signal circles.
7. **Settings** — channels, radio config, security/PIN, storage, logs, about.

### Proposed component inventory (shadcn)
- Layout: sidebar, collapsible groups, resizable panels for spectrum/map.
- Data: table (channel editor, node list), card (dashboard widgets), tabs (workspace sub-pages).
- Feedback: badge (new messages, node count), toast/sonner (flash success/error), skeleton (loading states).
- Input: dialog (manual TCP entry), dropdown-menu, select, button, textarea (message compose).
- Visualization: chart (telemetry/SNR over time), custom canvas for spectrum/waterfall, map view (MapLibre/Leaflet).

### Open questions
- Should the desktop UI be Electron or Tauri? (Electron = simpler Node reuse; Tauri = smaller binaries but Rust sidecar needed.)
- Should we keep the React UI in `apps/desktop/` and add a separate `apps/web/` PWA, or merge both?
- Which color theme / branding does Mike want? Default shadcn slate/zinc, or a custom OCP-V1 palette?
- Does the map use MapLibre GL JS (web) for now, or wait for Flutter MapLibre?
- How important is RTL / accessibility from day one?

### Decisions needed from Mike
1. Confirm **Electron + React + shadcn/ui** for the Windows UI (vs pure Flutter).
2. Pick the first 2–3 workspaces to build (suggest: Dashboard, Messaging, Devices).
3. Confirm dark/light theme preference (default shadcn dark mode).
4. Decide whether to add a real spectrum canvas now or stub it with fake data.

