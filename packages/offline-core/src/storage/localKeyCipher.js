import {
  createCipheriv,
  createDecipheriv,
  createHmac,
  randomBytes,
  scryptSync,
  timingSafeEqual,
} from "node:crypto";

const DEFAULT_SALT = "ocp-offline-salt";
const SCRYPT_OPTS = { N: 16384, r: 8, p: 1 };
const KEY_LEN = 32;

/**
 * AES-256-GCM helper for secrets and full-file DB encryption at rest.
 * Prefer a random salt from PinVault in production; fixed string salt is
 * kept for backward compatibility with older callers/tests.
 */
export class LocalKeyCipher {
  /**
   * @param {string} passphrase
   * @param {string|Buffer} [salt]
   */
  constructor(passphrase, salt = DEFAULT_SALT) {
    const saltBuf = Buffer.isBuffer(salt) ? salt : Buffer.from(String(salt), "utf8");
    this.salt = saltBuf;
    this.key = scryptSync(passphrase, saltBuf, KEY_LEN, SCRYPT_OPTS);
  }

  /** Build a cipher from an already-derived 32-byte key. */
  static fromKey(key) {
    const cipher = Object.create(LocalKeyCipher.prototype);
    cipher.key = Buffer.from(key);
    cipher.salt = null;
    return cipher;
  }

  /** Derive a 32-byte key (same KDF as constructor). */
  static deriveKey(passphrase, salt) {
    const saltBuf = Buffer.isBuffer(salt) ? salt : Buffer.from(String(salt), "utf8");
    return scryptSync(passphrase, saltBuf, KEY_LEN, SCRYPT_OPTS);
  }

  /** HMAC verifier bytes for a derived key (PIN check without storing the PIN). */
  static makeVerifier(key) {
    return createHmac("sha256", key).update("ocp-v1-pin-verifier").digest();
  }

  static verifyKey(key, verifier) {
    const expected = LocalKeyCipher.makeVerifier(key);
    const actual = Buffer.isBuffer(verifier) ? verifier : Buffer.from(verifier);
    if (expected.length !== actual.length) return false;
    return timingSafeEqual(expected, actual);
  }

  encrypt(plaintext) {
    const iv = randomBytes(12);
    const cipher = createCipheriv("aes-256-gcm", this.key, iv);
    const encrypted = Buffer.concat([cipher.update(plaintext, "utf8"), cipher.final()]);
    const tag = cipher.getAuthTag();
    return Buffer.concat([iv, tag, encrypted]).toString("base64");
  }

  decrypt(payload) {
    const raw = Buffer.from(payload, "base64");
    const iv = raw.subarray(0, 12);
    const tag = raw.subarray(12, 28);
    const encrypted = raw.subarray(28);
    const decipher = createDecipheriv("aes-256-gcm", this.key, iv);
    decipher.setAuthTag(tag);
    return Buffer.concat([decipher.update(encrypted), decipher.final()]).toString("utf8");
  }
}
