#!/usr/bin/env node

/**
 * Example usage of the Meshtastic bridge
 * This demonstrates how to use the bridge components
 */

import { MeshtasticCodec } from "./packages/ocp_bridge_meshtastic/src/meshtasticCodec.js";
import { MeshtasticTransport } from "./packages/ocp_bridge_meshtastic/src/meshtasticTransport.js";

console.log("=== OCP-V1 Meshtastic Bridge Example ===");

// Create codec instance
console.log("\n1. Creating Meshtastic Codec...");
const codec = new MeshtasticCodec();
console.log("✅ Codec created successfully");

// Create transport instance
console.log("\n2. Creating Meshtastic Transport...");
const transport = new MeshtasticTransport({
  type: "tcp",
  host: "localhost",
  port: 4403
});
console.log("✅ Transport created successfully");

// Show that we can encode/decode (even without real protobufs loaded)
console.log("\n3. Testing message encoding...");
const testMessage = {
  wantConfigId: "example-config"
};

try {
  const encoded = codec.encodeToRadio(testMessage);
  console.log(`✅ Message encoded successfully (${encoded.length} bytes)`);
  
  // Show that we can decode (will return error message if protobufs not loaded)
  const decoded = codec.decodeFromRadio(encoded);
  console.log("✅ Message decode attempt completed");
  
  if (decoded.error) {
    console.log(`   Note: ${decoded.error} (expected without hardware)`);
  }
} catch (error) {
  console.log(`⚠️  Encoding/decoding test: ${error.message}`);
}

console.log("\n4. Bridge components ready for integration!");
console.log("   - Codec handles protocol translation");
console.log("   - Transport handles hardware connection");
console.log("   - Ready for TCP, Serial, or BLE connections");

console.log("\n=== End Example ===");