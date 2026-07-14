import { readFile, writeFile, unlink } from "node:fs/promises";
import { existsSync } from "node:fs";
import { randomBytes } from "node:crypto";
import { LocalKeyCipher } from "../storage/localKeyCipher.js";

const VAULT_VERSION = 1;

/**
 * PIN vault: stores random salt + HMAC verifier (never the PIN).
 * Unlock derives a LocalKeyCipher for encrypted at-rest storage.
 */
export class PinVault {
  /**
   * @param {string} vaultPath
   */
  constructor(vaultPath) {
    this.vaultPath = vaultPath;
    /** @type {LocalKeyCipher|null} */
    this.cipher = null;
    /** @type {{ version: number, salt: string, verifier: string }|null} */
    this.#meta = null;
  }

  #meta;

  get isUnlocked() {
    return this.cipher != null;
  }

  async isConfigured() {
    return existsSync(this.vaultPath);
  }

  async #loadMeta() {
    if (!existsSync(this.vaultPath)) return null;
    const raw = await readFile(this.vaultPath, "utf8");
    this.#meta = JSON.parse(raw);
    return this.#meta;
  }

  async #saveMeta(meta) {
    this.#meta = meta;
    await writeFile(this.vaultPath, JSON.stringify(meta, null, 2), "utf8");
  }

  /**
   * Create PIN configuration. Leaves the vault unlocked.
   * @param {string} pin
   * @param {{ replace?: boolean }} [opts] - replace=true only for changePin after verifying current PIN
   */
  async setPin(pin, opts = {}) {
    if (typeof pin !== "string" || pin.length < 4) {
      throw new Error("PIN must be at least 4 characters");
    }
    if (!opts.replace && (await this.isConfigured())) {
      throw new Error("PIN already configured — use changePin");
    }
    const salt = randomBytes(16);
    const key = LocalKeyCipher.deriveKey(pin, salt);
    const verifier = LocalKeyCipher.makeVerifier(key);
    await this.#saveMeta({
      version: VAULT_VERSION,
      salt: salt.toString("base64"),
      verifier: verifier.toString("base64"),
    });
    this.cipher = LocalKeyCipher.fromKey(key);
    return { ok: true };
  }

  /**
   * @param {string} pin
   * @returns {Promise<LocalKeyCipher>}
   */
  async unlock(pin) {
    const meta = await this.#loadMeta();
    if (!meta) throw new Error("PIN is not configured");
    const salt = Buffer.from(meta.salt, "base64");
    const key = LocalKeyCipher.deriveKey(pin, salt);
    const verifier = Buffer.from(meta.verifier, "base64");
    if (!LocalKeyCipher.verifyKey(key, verifier)) {
      throw new Error("Incorrect PIN");
    }
    this.cipher = LocalKeyCipher.fromKey(key);
    return this.cipher;
  }

  lock() {
    this.cipher = null;
  }

  /**
   * Verify current PIN, then replace vault (caller must rewrap encrypted DB).
   * @param {string} currentPin
   * @param {string} newPin
   * @returns {Promise<{ ok: true, oldCipher: LocalKeyCipher, newCipher: LocalKeyCipher }>}
   */
  async changePin(currentPin, newPin) {
    const oldCipher = await this.unlock(currentPin);
    await this.setPin(newPin, { replace: true });
    return { ok: true, oldCipher, newCipher: this.cipher };
  }

  /** Remove vault file and clear session cipher. */
  async clearPin() {
    this.lock();
    this.#meta = null;
    if (existsSync(this.vaultPath)) {
      await unlink(this.vaultPath);
    }
    return { ok: true };
  }
}

export default PinVault;
