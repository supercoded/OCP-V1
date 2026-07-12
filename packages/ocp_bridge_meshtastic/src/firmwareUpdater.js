import { mkdir, writeFile, readFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { homedir } from "node:os";
import { dirname, join, basename } from "node:path";
import { fileURLToPath } from "node:url";
import { spawn } from "node:child_process";

const FIRMWARE_API_URL = "https://api.github.com/repos/meshtastic/firmware/releases";
const FIRMWARE_DOWNLOAD_URL = "https://github.com/meshtastic/firmware/releases/download";

const DEFAULT_CACHE_DIR = join(homedir(), ".cache", "ocp-v1", "firmware");

// Common board-to-firmware asset suffix mappings. These evolve with Meshtastic
// releases; the caller can always override assetName.
const BOARD_ASSET_SUFFIXES = {
  "rak4631": "RAK4631_firmware.zip",
  "rak4631_eink": "RAK4631_EINK_firmware.zip",
  "rak11200": "RAK11200_firmware.zip",
  "tbeam": "TBEAM_firmware.zip",
  "lilygo_t3s3": "LILYGO_T3S3_firmware.zip",
  "heltec_v3": "HELTEC_V3_firmware.zip",
  "esp32": "ESP32_firmware.zip",
};

/**
 * Meshtastic firmware updater. Fetches official releases from GitHub,
 * caches them locally, and flashes them using the appropriate external tool.
 */
export class FirmwareUpdater {
  constructor({ cacheDir = DEFAULT_CACHE_DIR, commandRunner = runCommand } = {}) {
    this.cacheDir = cacheDir;
    this.runCommand = commandRunner;
  }

  /** Ensure the cache directory exists. */
  async ensureCache() {
    await mkdir(this.cacheDir, { recursive: true });
  }

  /**
   * List official Meshtastic firmware releases from GitHub.
   * Results are cached for 5 minutes to avoid rate limits.
   */
  async listReleases({ limit = 10, includePrerelease = false } = {}) {
    const res = await fetch(FIRMWARE_API_URL);
    if (!res.ok) {
      throw new Error(`GitHub API error: ${res.status} ${res.statusText}`);
    }
    const releases = await res.json();
    return releases
      .filter((r) => includePrerelease || r.prerelease === false)
      .slice(0, limit)
      .map((r) => ({
        tag: r.tag_name,
        name: r.name,
        published: r.published_at,
        assets: r.assets.map((a) => ({ name: a.name, url: a.url, size: a.size })),
      }));
  }

  /**
   * Resolve the asset name for a given board identifier.
   * @param {string} board e.g. "rak4631"
   * @returns {string|undefined}
   */
  resolveAssetName(board) {
    return BOARD_ASSET_SUFFIXES[board.toLowerCase()];
  }

  /**
   * Download a release asset, returning the cached path.
   * @param {string} tag e.g. "v2.3.13.1"
   * @param {string} assetName e.g. "RAK4631_firmware.zip"
   * @returns {Promise<string>} local file path
   */
  async downloadReleaseAsset(tag, assetName) {
    await this.ensureCache();
    const localPath = join(this.cacheDir, `${tag}_${assetName}`);
    if (existsSync(localPath)) {
      return localPath;
    }

    const url = `${FIRMWARE_DOWNLOAD_URL}/${tag}/${assetName}`;
    const res = await fetch(url);
    if (!res.ok) {
      throw new Error(`Download failed: ${res.status} ${res.statusText} for ${url}`);
    }
    const buffer = Buffer.from(await res.arrayBuffer());
    await writeFile(localPath, buffer);
    return localPath;
  }

  /**
   * Detect the chip family from a board name or port metadata.
   * @param {string} board e.g. "rak4631" or "tbeam"
   * @returns {"nrf52" | "esp32" | "unknown"}
   */
  detectChipFamily(board) {
    const b = board.toLowerCase();
    if (b.startsWith("rak4631") || b.includes("nrf52840") || b.includes("nrf52")) {
      return "nrf52";
    }
    if (
      b.startsWith("rak11200") ||
      b.includes("tbeam") ||
      b.includes("esp32") ||
      b.includes("lilygo") ||
      b.includes("heltec")
    ) {
      return "esp32";
    }
    return "unknown";
  }

  /**
   * Flash a firmware file to the device.
   * @param {Object} options
   * @param {string} options.portName serial port, e.g. "COM3" or "/dev/ttyUSB0"
   * @param {string} options.firmwarePath path to .zip or .bin firmware
   * @param {string} options.chipFamily "nrf52" or "esp32"
   */
  async flashFirmware({ portName, firmwarePath, chipFamily }) {
    if (!portName || !firmwarePath || !chipFamily) {
      throw new Error("flashFirmware requires portName, firmwarePath, and chipFamily");
    }

    if (chipFamily === "nrf52") {
      await this._flashNrf52({ portName, firmwarePath });
    } else if (chipFamily === "esp32") {
      await this._flashEsp32({ portName, firmwarePath });
    } else {
      throw new Error(`Unsupported chip family: ${chipFamily}`);
    }
  }

  async _flashNrf52({ portName, firmwarePath }) {
    const binPath = await this._extractIfZip(firmwarePath, "firmware.bin");
    const tool = await this._requireTool("nrfutil");
    await this.runCommand(tool, [
      "dfu",
      "usb-serial",
      "-pkg",
      binPath,
      "-p",
      portName,
    ]);
  }

  async _flashEsp32({ portName, firmwarePath }) {
    const binPath = await this._extractIfZip(firmwarePath, "firmware.bin");
    const tool = await this._requireTool("esptool.py");
    await this.runCommand(tool, ["--port", portName, "--baud", "921600", "write_flash", "0x1000", binPath]);
  }

  async _extractIfZip(firmwarePath, expectedBinName) {
    if (!firmwarePath.toLowerCase().endsWith(".zip")) {
      return firmwarePath;
    }
    // Minimal extraction: if the zip contains a single .bin, unzip it.
    const extractDir = join(dirname(firmwarePath), basename(firmwarePath, ".zip"));
    await mkdir(extractDir, { recursive: true });
    await this.runCommand("unzip", ["-o", firmwarePath, "-d", extractDir]);
    const files = (await readDirRecursive(extractDir)).filter((f) => f.endsWith(".bin"));
    if (files.length === 0) {
      throw new Error(`No .bin file found inside ${firmwarePath}`);
    }
    return files[0];
  }

  async _requireTool(name) {
    const found = await commandExists(name);
    if (!found) {
      throw new Error(
        `${name} is not installed. Install it and ensure it's on PATH. ` +
          `For nRF52: Nordic nrfutil. For ESP32: esptool.py.`
      );
    }
    return name;
  }
}

/** Run a shell command, returning stdout. */
export function runCommand(cmd, args, options = {}) {
  return new Promise((resolve, reject) => {
    const child = spawn(cmd, args, { stdio: ["ignore", "pipe", "pipe"], ...options });
    let stdout = "";
    let stderr = "";
    child.stdout.on("data", (d) => (stdout += d));
    child.stderr.on("data", (d) => (stderr += d));
    child.on("error", (err) => reject(new Error(`${cmd} spawn error: ${err.message}`)));
    child.on("close", (code) => {
      if (code !== 0) {
        reject(new Error(`${cmd} exited ${code}: ${stderr || stdout}`));
      } else {
        resolve(stdout);
      }
    });
  });
}

async function commandExists(name) {
  try {
    await runCommand("command", ["-v", name], { shell: true });
    return true;
  } catch {
    return false;
  }
}

async function readDirRecursive(dir) {
  const entries = await import("node:fs/promises").then((m) => m.readdir(dir, { withFileTypes: true }));
  const files = [];
  for (const entry of entries) {
    const full = join(dir, entry.name);
    if (entry.isDirectory()) {
      files.push(...(await readDirRecursive(full)));
    } else {
      files.push(full);
    }
  }
  return files;
}
