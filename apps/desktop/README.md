# OCP-V1 Desktop

Windows desktop app for OCP-V1. Built with **Electron + React + TypeScript + Tailwind CSS**.

## Download

Releases are published to the [GitHub Releases](https://github.com/supercoded/OCP-V1/releases) page.

1. Go to **Releases**.
2. Download the latest `OCP-V1-Setup-x.x.x.exe` (or the portable `.exe`).
3. Run the installer.
4. Launch **OCP-V1** from the Start Menu or desktop shortcut.

The installer includes the Electron app. Optional radio tool dependencies (`esptool.py`, `nrfutil`, RTL-SDR drivers, RuView Docker) are documented below and can be installed afterward.

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
```

## Optional external tools

| Tool | Purpose | How to install on Windows |
|---|---|---|
| `esptool.py` | Flash Meshtastic firmware to ESP32 boards | `pip install esptool` (requires Python) |
| `nrfutil` | Flash Meshtastic firmware to nRF52/RAK4631 boards | `pip install nrfutil` (requires Python) |
| RTL-SDR drivers | Use RTL-SDR for spectrum view | [rtl-sdr Quick Start](https://rtl-sdr.com/) |
| `rtl_tcp` | Stream SDR samples to OCP-V1 | Included in rtl-sdr package or [SDR++](https://github.com/AlexandreRouma/SDRPlusPlus) |
| RuView Docker | Through-wall presence/vitals sensing | Install Docker Desktop, then run `bash scripts/run-ruview-simulator.sh` |

## Packaging

The Windows installer is built automatically by the `.github/workflows/build-windows.yml` GitHub Actions workflow on every tagged release. It produces:

- `OCP-V1 Setup x.x.x.exe` — full NSIS installer
- `OCP-V1 x.x.x.exe` — portable version

## License

See `build/LICENSE.txt`.
