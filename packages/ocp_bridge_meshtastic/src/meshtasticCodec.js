import protobufjs from "protobufjs";
import { fileURLToPath } from "node:url";
import { dirname, resolve } from "node:path";
import { existsSync } from "node:fs";

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/** Parent of the `meshtastic/` folder — protos import as `meshtastic/*.proto`. */
const PROTOBUF_ROOT = (() => {
  const candidates = [
    resolve(__dirname, "../../../node_modules/meshtastic-protobufs/proto"),
    resolve(__dirname, "../../../protobufs"),
  ];
  for (const candidate of candidates) {
    if (existsSync(resolve(candidate, "meshtastic", "mesh.proto"))) {
      return candidate;
    }
  }
  return candidates[candidates.length - 1];
})();

const PROTO_FILES = [
  "meshtastic/mesh.proto",
  "meshtastic/portnums.proto",
  "meshtastic/channel.proto",
  "meshtastic/config.proto",
  "meshtastic/device_ui.proto",
  "meshtastic/module_config.proto",
  "meshtastic/telemetry.proto",
  "meshtastic/xmodem.proto",
  "meshtastic/serial_hal.proto",
];

function isTextPortnum(portnum) {
  return portnum === "TEXT_MESSAGE_APP" || portnum === 1;
}

/**
 * Codec for translating between Meshtastic protobufs and OCP protocol.
 * Requires protobufjs v7 (Root.loadSync). Fails hard if protos cannot load.
 */
export class MeshtasticCodec {
  constructor() {
    if (typeof protobufjs?.Root !== "function") {
      throw new Error(
        "protobufjs Root unavailable — pin protobufjs@7 for @ocp/bridge-meshtastic"
      );
    }

    try {
      // Module-level loadSync(filename, options) treats `options` as a Root — use Root#loadSync.
      const root = new protobufjs.Root();
      root.resolvePath = (_origin, target) => resolve(PROTOBUF_ROOT, target);
      this.root = root.loadSync(PROTO_FILES);
      this.MeshPacket = this.root.lookupType("meshtastic.MeshPacket");
      this.FromRadio = this.root.lookupType("meshtastic.FromRadio");
      this.ToRadio = this.root.lookupType("meshtastic.ToRadio");
      this.Data = this.root.lookupType("meshtastic.Data");
      this.Position = this.root.lookupType("meshtastic.Position");
      this.User = this.root.lookupType("meshtastic.User");
    } catch (error) {
      throw new Error(`Failed to load Meshtastic protobuf definitions: ${error.message}`);
    }
  }

  decodeFromRadio(buffer) {
    try {
      const message = this.FromRadio.decode(buffer);
      return this.#convertFromRadioMessage(message);
    } catch (error) {
      throw new Error(`Failed to decode FromRadio: ${error.message}`);
    }
  }

  encodeToRadio(ocpMessage) {
    try {
      const meshtasticMessage = this.#convertToRadioMessage(ocpMessage);
      const err = this.ToRadio.verify(meshtasticMessage);
      if (err) throw new Error(err);
      return Buffer.from(this.ToRadio.encode(this.ToRadio.create(meshtasticMessage)).finish());
    } catch (error) {
      throw new Error(`Failed to encode ToRadio: ${error.message}`);
    }
  }

  #convertFromRadioMessage(fromRadio) {
    const result = {};

    if (Object.prototype.hasOwnProperty.call(fromRadio, "packet") && fromRadio.packet) {
      result.packet = this.#convertMeshPacket(fromRadio.packet);
    }

    if (Object.prototype.hasOwnProperty.call(fromRadio, "myInfo") && fromRadio.myInfo) {
      result.myInfo = {
        myNodeNum: fromRadio.myInfo.myNodeNum,
        firmwareVersion: fromRadio.myInfo.firmwareVersion,
        rebootCount: fromRadio.myInfo.rebootCount,
      };
    }

    if (Object.prototype.hasOwnProperty.call(fromRadio, "nodeInfo") && fromRadio.nodeInfo) {
      result.nodeInfo = this.#convertNodeInfo(fromRadio.nodeInfo);
    }

    if (Object.prototype.hasOwnProperty.call(fromRadio, "config") && fromRadio.config) {
      result.config = fromRadio.config;
    }

    if (Object.prototype.hasOwnProperty.call(fromRadio, "channel") && fromRadio.channel) {
      result.channel = fromRadio.channel;
    }

    if (Object.prototype.hasOwnProperty.call(fromRadio, "ackId") && fromRadio.ackId != null) {
      result.ackId = fromRadio.ackId;
    }

    return result;
  }

  #convertToRadioMessage(ocpMessage) {
    const toRadio = {};

    if (ocpMessage.packet) {
      toRadio.packet = this.#convertToMeshPacket(ocpMessage.packet);
    }

    if (ocpMessage.wantConfigId != null) {
      toRadio.wantConfigId = Number(ocpMessage.wantConfigId) >>> 0;
    }

    if (ocpMessage.disconnect !== undefined) {
      toRadio.disconnect = ocpMessage.disconnect;
    }

    return toRadio;
  }

  #convertMeshPacket(packet) {
    const result = {
      from: packet.from,
      to: packet.to,
      id: packet.id,
      rxTime: packet.rxTime,
      rxSnr: packet.rxSnr,
      hopLimit: packet.hopLimit,
      channel: packet.channel,
    };

    if (packet.decoded) {
      const payload = this.#convertDataPayload(packet.decoded);
      result.payload = payload;
      result.decoded = payload;
    }

    return result;
  }

  #convertToMeshPacket(ocpPacket) {
    const packet = {
      to: ocpPacket.to,
      id: ocpPacket.id,
      hopLimit: ocpPacket.hopLimit || 3,
      channel: ocpPacket.channel ?? 0,
    };

    const payload = ocpPacket.payload ?? ocpPacket.decoded;
    if (payload) {
      packet.decoded = this.#convertToDataPayload(payload);
    }

    return packet;
  }

  #convertDataPayload(data) {
    const result = {
      portnum: data.portnum,
      payload: data.payload ? Buffer.from(data.payload).toString("base64") : undefined,
      wantResponse: data.wantResponse,
      dest: data.dest,
      source: data.source,
      requestId: data.requestId,
    };

    if (isTextPortnum(data.portnum)) {
      result.text = data.payload ? Buffer.from(data.payload).toString("utf8") : "";
    }

    return result;
  }

  #convertToDataPayload(ocpPayload) {
    const data = {
      portnum: ocpPayload.portnum,
      wantResponse: ocpPayload.wantResponse,
      dest: ocpPayload.dest,
      source: ocpPayload.source,
      requestId: ocpPayload.requestId,
    };

    if (ocpPayload.payload) {
      data.payload = Buffer.from(ocpPayload.payload, "base64");
    }

    if (isTextPortnum(ocpPayload.portnum) && ocpPayload.text) {
      data.payload = Buffer.from(ocpPayload.text, "utf8");
      // Prefer numeric enum for wire encode
      if (data.portnum === "TEXT_MESSAGE_APP") data.portnum = 1;
    }

    return data;
  }

  #convertNodeInfo(nodeInfo) {
    return {
      num: nodeInfo.num,
      user: nodeInfo.user
        ? {
            id: nodeInfo.user.id,
            longName: nodeInfo.user.longName,
            shortName: nodeInfo.user.shortName,
            macaddr: nodeInfo.user.macaddr ? Array.from(nodeInfo.user.macaddr) : undefined,
            hwModel: nodeInfo.user.hwModel,
          }
        : undefined,
      position: nodeInfo.position
        ? {
            latitudeI: nodeInfo.position.latitudeI,
            longitudeI: nodeInfo.position.longitudeI,
            altitude: nodeInfo.position.altitude,
            time: nodeInfo.position.time,
          }
        : undefined,
      lastHeard: nodeInfo.lastHeard,
      snr: nodeInfo.snr,
    };
  }
}
