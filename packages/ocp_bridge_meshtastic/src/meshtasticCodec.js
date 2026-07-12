import protobufjs from "protobufjs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";

const { loadSync } = protobufjs;

// Resolve the path to the protobuf files. First try a package-installed location,
// then fall back to the repository's protobufs/ directory.
const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
import { existsSync } from "node:fs";

const PROTOBUF_PATH = (() => {
  const candidates = [
    resolve(__dirname, "../../node_modules/meshtastic-protobufs/proto/meshtastic"),
    resolve(__dirname, "../../../../protobufs/meshtastic"),
  ];
  for (const candidate of candidates) {
    if (existsSync(resolve(candidate, "mesh.proto"))) {
      return candidate;
    }
  }
  return candidates[candidates.length - 1];
})();

/**
 * Codec for translating between Meshtastic protobufs and OCP protocol
 */
export class MeshtasticCodec {
  constructor() {
    try {
      this.root = loadSync(
        [
          resolve(PROTOBUF_PATH, "mesh.proto"),
          resolve(PROTOBUF_PATH, "portnums.proto"),
          resolve(PROTOBUF_PATH, "channel.proto"),
          resolve(PROTOBUF_PATH, "config.proto"),
          resolve(PROTOBUF_PATH, "device_ui.proto"),
          resolve(PROTOBUF_PATH, "module_config.proto"),
          resolve(PROTOBUF_PATH, "telemetry.proto"),
          resolve(PROTOBUF_PATH, "xmodem.proto"),
          resolve(PROTOBUF_PATH, "serial_hal.proto"),
        ],
        { keepCase: true }
      );
      // Get the key message types
      this.MeshPacket = this.root.lookupType("meshtastic.MeshPacket");
      this.FromRadio = this.root.lookupType("meshtastic.FromRadio");
      this.ToRadio = this.root.lookupType("meshtastic.ToRadio");
      this.Data = this.root.lookupType("meshtastic.Data");
      this.Position = this.root.lookupType("meshtastic.Position");
      this.User = this.root.lookupType("meshtastic.User");
    } catch (error) {
      console.error("Failed to load protobuf definitions:", error.message);
      // Don't throw the error, just log it - we'll handle it gracefully
      this.MeshPacket = null;
      this.FromRadio = null;
      this.ToRadio = null;
      this.Data = null;
      this.Position = null;
      this.User = null;
    }
  }

  /**
   * Decode a Meshtastic FromRadio message to OCP format
   * @param {Buffer} buffer - Raw protobuf buffer
   * @returns {Object} OCP-compatible message
   */
  decodeFromRadio(buffer) {
    // If protobufs failed to load, return a basic structure
    if (!this.FromRadio) {
      return { error: "Protobuf definitions not loaded" };
    }
    
    try {
      const message = this.FromRadio.decode(buffer);
      return this.#convertFromRadioMessage(message);
    } catch (error) {
      throw new Error(`Failed to decode FromRadio: ${error.message}`);
    }
  }

  /**
   * Encode an OCP message to Meshtastic ToRadio format
   * @param {Object} ocpMessage - OCP message format
   * @returns {Buffer} Encoded protobuf buffer
   */
  encodeToRadio(ocpMessage) {
    // If protobufs failed to load, return empty buffer
    if (!this.ToRadio) {
      return Buffer.alloc(0);
    }
    
    try {
      const meshtasticMessage = this.#convertToRadioMessage(ocpMessage);
      return this.ToRadio.encode(meshtasticMessage).finish();
    } catch (error) {
      throw new Error(`Failed to encode ToRadio: ${error.message}`);
    }
  }

  /**
   * Convert Meshtastic FromRadio to OCP format
   * @private
   */
  #convertFromRadioMessage(fromRadio) {
    const result = {};

    if (fromRadio.hasOwnProperty("packet")) {
      result.packet = this.#convertMeshPacket(fromRadio.packet);
    }

    if (fromRadio.hasOwnProperty("myInfo")) {
      result.myInfo = {
        myNodeNum: fromRadio.myInfo.myNodeNum,
        firmwareVersion: fromRadio.myInfo.firmwareVersion,
        rebootCount: fromRadio.myInfo.rebootCount
      };
    }

    if (fromRadio.hasOwnProperty("nodeInfo")) {
      result.nodeInfo = this.#convertNodeInfo(fromRadio.nodeInfo);
    }

    if (fromRadio.hasOwnProperty("config")) {
      result.config = fromRadio.config;
    }

    if (fromRadio.hasOwnProperty("channel")) {
      result.channel = fromRadio.channel;
    }

    if (fromRadio.hasOwnProperty("ackId")) {
      result.ackId = fromRadio.ackId;
    }

    return result;
  }

  /**
   * Convert OCP message to Meshtastic ToRadio format
   * @private
   */
  #convertToRadioMessage(ocpMessage) {
    const toRadio = {};

    if (ocpMessage.packet) {
      toRadio.packet = this.#convertToMeshPacket(ocpMessage.packet);
    }

    if (ocpMessage.wantConfigId) {
      toRadio.wantConfigId = ocpMessage.wantConfigId;
    }

    if (ocpMessage.disconnect !== undefined) {
      toRadio.disconnect = ocpMessage.disconnect;
    }

    return toRadio;
  }

  /**
   * Convert Meshtastic MeshPacket to OCP format
   * @private
   */
  #convertMeshPacket(packet) {
    const result = {
      from: packet.from,
      to: packet.to,
      id: packet.id,
      rxTime: packet.rxTime,
      rxSnr: packet.rxSnr,
      hopLimit: packet.hopLimit
    };

    if (packet.decoded) {
      result.payload = this.#convertDataPayload(packet.decoded);
    }

    return result;
  }

  /**
   * Convert OCP packet to Meshtastic MeshPacket
   * @private
   */
  #convertToMeshPacket(ocpPacket) {
    const packet = {
      to: ocpPacket.to,
      id: ocpPacket.id,
      hopLimit: ocpPacket.hopLimit || 3
    };

    if (ocpPacket.payload) {
      packet.decoded = this.#convertToDataPayload(ocpPacket.payload);
    }

    return packet;
  }

  /**
   * Convert Meshtastic Data payload to OCP format
   * @private
   */
  #convertDataPayload(data) {
    const result = {
      portnum: data.portnum,
      payload: data.payload ? data.payload.toString("base64") : undefined,
      wantResponse: data.wantResponse,
      dest: data.dest,
      source: data.source,
      requestId: data.requestId
    };

    // Handle text messages specifically
    if (data.portnum === "TEXT_MESSAGE_APP") {
      result.text = data.payload ? data.payload.toString("utf8") : "";
    }

    return result;
  }

  /**
   * Convert OCP payload to Meshtastic Data format
   * @private
   */
  #convertToDataPayload(ocpPayload) {
    const data = {
      portnum: ocpPayload.portnum,
      wantResponse: ocpPayload.wantResponse,
      dest: ocpPayload.dest,
      source: ocpPayload.source,
      requestId: ocpPayload.requestId
    };

    if (ocpPayload.payload) {
      data.payload = Buffer.from(ocpPayload.payload, "base64");
    }

    // Handle text messages specifically
    if (ocpPayload.portnum === "TEXT_MESSAGE_APP" && ocpPayload.text) {
      data.payload = Buffer.from(ocpPayload.text, "utf8");
    }

    return data;
  }

  /**
   * Convert Meshtastic NodeInfo to OCP format
   * @private
   */
  #convertNodeInfo(nodeInfo) {
    return {
      num: nodeInfo.num,
      user: nodeInfo.user ? {
        id: nodeInfo.user.id,
        longName: nodeInfo.user.longName,
        shortName: nodeInfo.user.shortName,
        macaddr: nodeInfo.user.macaddr ? Array.from(nodeInfo.user.macaddr) : undefined,
        hwModel: nodeInfo.user.hwModel
      } : undefined,
      position: nodeInfo.position ? {
        latitudeI: nodeInfo.position.latitudeI,
        longitudeI: nodeInfo.position.longitudeI,
        altitude: nodeInfo.position.altitude,
        time: nodeInfo.position.time
      } : undefined,
      lastHeard: nodeInfo.lastHeard,
      snr: nodeInfo.snr
    };
  }
}