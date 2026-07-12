#!/usr/bin/env node
import { FirmwareUpdater } from "../packages/ocp_bridge_meshtastic/src/firmwareUpdater.js";

const usage = `
Usage:
  node scripts/update-meshtastic-firmware.js [command] [options]

Commands:
  list                  List latest Meshtastic firmware releases
  download --board <board> --tag <tag> [--asset <name>]
                        Download firmware for a board/tag
  flash --board <board> --tag <tag> --port <port> [--asset <name>]
                        Download and flash firmware

Examples:
  node scripts/update-meshtastic-firmware.js list
  node scripts/update-meshtastic-firmware.js download --board rak4631 --tag v2.3.13.1
  node scripts/update-meshtastic-firmware.js flash --board tbeam --tag v2.3.13.1 --port /dev/ttyUSB0
`;

function parseArgs(argv) {
  const args = {};
  for (let i = 2; i < argv.length; i++) {
    const arg = argv[i];
    if (arg.startsWith("--")) {
      args[arg.replace(/^--/, "")] = argv[i + 1] ?? true;
      if (argv[i + 1] && !argv[i + 1].startsWith("--")) i++;
    } else {
      args.command = arg;
    }
  }
  return args;
}

async function main() {
  const args = parseArgs(process.argv);
  const updater = new FirmwareUpdater();

  if (!args.command || args.command === "help") {
    console.log(usage);
    process.exit(0);
  }

  if (args.command === "list") {
    const releases = await updater.listReleases({ limit: Number(args.limit) || 10 });
    for (const r of releases) {
      console.log(`${r.tag} — ${r.name} (${r.published})`);
      for (const a of r.assets.slice(0, 5)) {
        console.log(`   - ${a.name} (${(a.size / 1024).toFixed(1)} KB)`);
      }
    }
    return;
  }

  if (args.command === "download" || args.command === "flash") {
    const { board, tag, port, asset } = args;
    if (!board || !tag) {
      console.error("Error: --board and --tag are required");
      console.log(usage);
      process.exit(1);
    }

    const assetName = asset || updater.resolveAssetName(board);
    if (!assetName) {
      console.error(
        `Error: unknown board "${board}". Known boards: ${Object.keys(updater.constructor.BOARD_ASSET_SUFFIXES || {}).join(", ")}. Use --asset to override.`
      );
      process.exit(1);
    }

    console.log(`Downloading ${assetName} for ${tag}...`);
    const firmwarePath = await updater.downloadReleaseAsset(tag, assetName);
    console.log(`Cached at: ${firmwarePath}`);

    if (args.command === "flash") {
      if (!port) {
        console.error("Error: --port is required for flash");
        process.exit(1);
      }
      const chipFamily = updater.detectChipFamily(board);
      console.log(`Flashing ${board} (${chipFamily}) on ${port}...`);
      await updater.flashFirmware({ portName: port, firmwarePath, chipFamily });
      console.log("Flash complete.");
    }
    return;
  }

  console.error("Unknown command:", args.command);
  console.log(usage);
  process.exit(1);
}

main().catch((err) => {
  console.error(err.message);
  process.exit(1);
});
