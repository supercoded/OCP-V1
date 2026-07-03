import { LocalKeyCipher } from "../../../packages/offline-core/src/storage/localKeyCipher.js";

/**
 * Placeholder entry point for mobile integration.
 * In a React Native/Flutter wrapper, this module's core logic is reused.
 */
const cipher = new LocalKeyCipher(process.env.OCP_KEY_PASSPHRASE ?? "dev-only-passphrase");
const encrypted = cipher.encrypt("channel-secret");

console.log("Mobile core initialized.");
console.log("Encrypted sample secret length:", encrypted.length);
