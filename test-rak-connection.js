#!/usr/bin/env node

/**
 * Test script to connect to RAK wireless chip
 * Usage: node test-rak-connection.js [host] [port]
 */

import { MeshtasticTransport } from "./packages/ocp_bridge_meshtastic/src/meshtasticTransport.js";

// Default connection parameters for Meshtastic devices
const host = process.argv[2] || "10.0.0.100"; // Default IP for Meshtastic devices
const port = parseInt(process.argv[3]) || 4403; // Default Meshtastic TCP port

console.log("=== OCP-V1 RAK Wireless Chip Test ===");
console.log(`Attempting to connect to: ${host}:${port}`);

// Create transport instance
const transport = new MeshtasticTransport({
  type: "tcp",
  host: host,
  port: port
});

// Handle connection events
transport.on("connected", (event) => {
  console.log("✅ Successfully connected to RAK wireless chip!");
  console.log(`   Device: ${event.endpoint.host}:${event.endpoint.port}`);
  
  // Send a simple config request
  console.log("📤 Requesting device configuration...");
});

transport.on("frame", (frame) => {
  console.log("📥 Received message from device:");
  console.log(JSON.stringify(frame, null, 2));
  
  // If we get config info, we know it's working
  if (frame.myInfo || frame.nodeInfo) {
    console.log("🎉 Device communication verified!");
    console.log("   You can now send/receive messages through your RAK chip");
  }
});

transport.on("error", (error) => {
  console.error("❌ Connection error:", error.error);
});

transport.on("disconnected", (event) => {
  console.log("🔌 Disconnected from device");
});

// Attempt connection
transport.connect().catch((error) => {
  console.error("Failed to connect:", error.message);
  console.log("\nTroubleshooting tips:");
  console.log("1. Make sure your RAK wireless chip is powered on");
  console.log("2. Ensure it's connected to the same WiFi network");
  console.log("3. Check that the IP address is correct");
  console.log("4. Verify no firewall is blocking port 4403");
  console.log("\nTo find your device's IP:");
  console.log("- Check your router's DHCP client list");
  console.log("- Use a network scanner like 'nmap' or 'Advanced IP Scanner'");
  console.log("- Look for a device with hostname 'meshtastic-xxxx'");
});