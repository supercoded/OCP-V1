# OCP-V1 Desktop

Cross-platform desktop app for OCP-V1. Built with **Electron + React + TypeScript + Tailwind CSS**.

Supports **Windows** (NSIS installer + portable) and **Linux** (AppImage + `.deb`).

## Download

Releases are published to the [GitHub Releases](https://github.com/supercoded/OCP-V1/releases) page.

### Windows

1. Go to **Releases**.
2. Download the latest `OCP-V1-Setup-x.x.x.exe` (or the portable `.exe`).
3. Run the installer.
4. Launch **OCP-V1** from the Start Menu or desktop shortcut.

### Linux

1. Go to **Releases**.
2. Download the latest package for your system:
   - **AppImage** (`OCP-V1-x.x.x.AppImage`) — works on all distros, no install needed:
     ```bash
     chmod +x OCP-V1-x.x.x.AppImage
     ./OCP-V1-x.x.x.AppImage
     ```
   - **.deb** (`ocp-v1_x.x.x_arm64.deb` or `_amd64.deb`) — for Debian/Ubuntu:
     ```bash
     sudo dpkg -i ocp-v1_x.x.x_arm64.deb
     ```
3. After install, launch **OCP-V1** from your application menu or terminal.

The packages include the Electron app. Optional radio tool dependencies (`esptool.py`, `nrfutil`, RTL-SDR drivers, RuView Docker) are documented below and can be installed afterward.

## Development

```bash
# From the repo root
npm install
npm run desktop:dev
```

## Build

```bash
# Build the renderer + main process bundles
npm run desktop:build

# Build a Windows installer (run on Windows or via GitHub Actions)
npm run desktop:dist:win

# Build Linux packages (AppImage + deb) on the current platform
npm run desktop:build:linux

# Build Linux packages only (assumes bundles already built)
npm run desktop:dist:linux
```

### Linux build requirements

On Debian/Ubuntu, install these before building:

```bash
sudo apt install -y dpkg fakeroot rpm
```

## Optional external tools

| Tool | Purpose | Windows | Linux (Debian/Ubuntu) |
|---|---|---|---|
| `esptool.py` | Flash Meshtastic firmware to ESP32 boards | `pip install esptool` | `pip install esptool` |
| `nrfutil` | Flash Meshtastic firmware to nRF52/RAK4631 boards | `pip install nrfutil` | `pip install nrfutil` |
| RTL-SDR drivers | Use RTL-SDR for spectrum view | [rtl-sdr Quick Start](https://rtl-sdr.com/) | `sudo apt install rtl-sdr` |
| `rtl_tcp` | Stream SDR samples to OCP-V1 | Included in rtl-sdr package | `sudo apt install rtl-sdr` |
| RuView Docker | Through-wall presence/vitals sensing | Docker Desktop + `scripts/run-ruview-simulator.sh` | Docker + `scripts/run-ruview-simulator.sh` |

## Packaging

### Windows

The Windows installer is built automatically by the `.github/workflows/build-windows.yml` GitHub Actions workflow on every tagged release. It produces:

- `OCP-V1 Setup x.x.x.exe` — full NSIS installer
- `OCP-V1 x.x.x.exe` — portable version

### Linux

The Linux packages are built by `npm run desktop:build:linux` (or `npm run desktop:dist:linux` for packaging only). They produce:

- `OCP-V1-x.x.x.AppImage` — portable AppImage (no install required)
- `ocp-v1_x.x.x_arch.deb` — Debian/Ubuntu package

Linux builds can be run on the Pi or via GitHub Actions with an ARM64 runner.

## License

See `build/LICENSE.txt`.
