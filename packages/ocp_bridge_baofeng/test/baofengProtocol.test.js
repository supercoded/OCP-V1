import { describe, it } from "node:test";
import assert from "node:assert/strict";
import {
  BAOFENG_MAGIC,
  BAOFENG_CHANNEL_COUNT,
  BAOFENG_CHANNEL_BLOCK_SIZE,
  BAOFENG_READ_BLOCK_SIZE,
  buildCommandHeader,
  buildIdentString,
  parseResponse,
  channelAddress,
  channelNameAddress,
  encodeFrequency,
  decodeFrequency,
  encodeChannelBlock,
  decodeChannelBlock,
  encodeChannelName,
  decodeChannelName,
  BaofengProtocol,
} from "../src/baofengProtocol.js";
import {
  validateFrequency,
  validateChannel,
  ctcssToCode,
  codeToCtcss,
  channelsToCSV,
  channelsFromCSV,
  createDefaultChannel,
  createDefaultChannels,
  VHF_MIN,
  VHF_MAX,
  UHF_MIN,
  UHF_MAX,
  CTCSS_TONES,
  DCS_CODES,
  DUPLEX_MODES,
  TONE_MODES,
  POWER_LEVELS,
  BANDWIDTH_OPTIONS,
} from "../src/channelModel.js";

describe("BaofengProtocol", () => {
  describe("buildCommandHeader", () => {
    it("should build a 5-byte command header with magic byte", () => {
      const header = buildCommandHeader(0x0010, 64);
      assert.equal(header.length, 5);
      assert.equal(header[0], BAOFENG_MAGIC);
      assert.equal(header[1], 0x10); // addr low
      assert.equal(header[2], 0x00); // addr high
      assert.equal(header[3], 64);   // size low
      assert.equal(header[4], 0x00); // size high
    });

    it("should handle 16-bit addresses and sizes", () => {
      const header = buildCommandHeader(0x1234, 0x0200);
      assert.equal(header[1], 0x34);
      assert.equal(header[2], 0x12);
      assert.equal(header[3], 0x00);
      assert.equal(header[4], 0x02);
    });
  });

  describe("buildIdentString", () => {
    it("should return 8 bytes with model name", () => {
      const ident = buildIdentString("UV-5RM");
      assert.equal(ident.length, 8);
      // Should start with 'U', 'V', '-', '5', 'R', 'M'
      assert.equal(String.fromCharCode(ident[0]), "U");
      assert.equal(String.fromCharCode(ident[1]), "V");
    });

    it("should pad to 8 bytes and null-terminate", () => {
      const ident = buildIdentString("UV5R");
      assert.equal(ident.length, 8);
      assert.equal(ident[4], 0); // null terminator
    });
  });

  describe("parseResponse", () => {
    it("should parse a valid response", () => {
      const data = new Uint8Array([
        0xa5,       // magic
        0x10, 0x00, // address = 0x0010
        0x04, 0x00, // size = 4
        0x01, 0x02, 0x03, 0x04, // payload
      ]);
      const result = parseResponse(data);
      assert.ok(result);
      assert.equal(result.address, 0x0010);
      assert.deepEqual(Array.from(result.payload), [1, 2, 3, 4]);
    });

    it("should return null for data shorter than 5 bytes", () => {
      assert.equal(parseResponse(new Uint8Array([0xa5, 0x00])), null);
    });

    it("should return null for wrong magic byte", () => {
      const data = new Uint8Array([0x00, 0x00, 0x00, 0x04, 0x00, 1, 2, 3, 4]);
      assert.equal(parseResponse(data), null);
    });
  });

  describe("encodeFrequency / decodeFrequency", () => {
    it("should round-trip a VHF frequency", () => {
      const freq = 146.520;
      const encoded = encodeFrequency(freq);
      const decoded = decodeFrequency(encoded);
      assert.ok(Math.abs(decoded - freq) < 0.001, `Expected ${freq}, got ${decoded}`);
    });

    it("should round-trip a UHF frequency", () => {
      const freq = 446.000;
      const encoded = encodeFrequency(freq);
      const decoded = decodeFrequency(encoded);
      assert.ok(Math.abs(decoded - freq) < 0.001, `Expected ${freq}, got ${decoded}`);
    });

    it("should handle zero frequency", () => {
      const encoded = encodeFrequency(0);
      assert.equal(decodeFrequency(encoded), 0);
    });

    it("should handle edge case frequencies", () => {
      const freq = 136.0;
      const encoded = encodeFrequency(freq);
      const decoded = decodeFrequency(encoded);
      assert.ok(Math.abs(decoded - freq) < 0.001);
    });
  });

  describe("encodeChannelBlock / decodeChannelBlock", () => {
    it("should round-trip a channel with simplex frequency", () => {
      const ch = {
        index: 0,
        rxFreq: 146.520,
        txFreq: 146.520,
        duplex: "none",
        toneMode: "CTCSS",
        rxToneCode: ctcssToCode(103.5),
        txToneCode: ctcssToCode(103.5),
        power: "High",
        bandwidth: "Wide",
        name: "VCALL",
      };
      const block = encodeChannelBlock(ch);
      assert.equal(block.length, BAOFENG_CHANNEL_BLOCK_SIZE);

      const decoded = decodeChannelBlock(block, 0);
      assert.ok(Math.abs(decoded.rxFreq - 146.520) < 0.001, `RX: ${decoded.rxFreq}`);
      assert.equal(decoded.duplex, "none");
      assert.equal(decoded.toneMode, "CTCSS");
      assert.equal(decoded.power, "High");
      assert.equal(decoded.bandwidth, "Wide");
    });

    it("should encode duplex + offset correctly", () => {
      const ch = {
        index: 1,
        rxFreq: 146.520,
        txFreq: 146.520,
        duplex: "+",
        toneMode: "None",
        rxToneCode: 0,
        txToneCode: 0,
        power: "Low",
        bandwidth: "Narrow",
        name: "",
      };
      const block = encodeChannelBlock(ch);
      assert.equal(block[8] & 0x20, 0x20); // duplex enabled
      assert.equal(block[8] & 0x40, 0x40); // positive offset

      const decoded = decodeChannelBlock(block, 1);
      assert.equal(decoded.duplex, "+");
      assert.equal(decoded.power, "Low");
      assert.equal(decoded.bandwidth, "Narrow");
    });

    it("should encode duplex - offset correctly", () => {
      const ch = {
        index: 2,
        rxFreq: 446.000,
        txFreq: 446.000,
        duplex: "-",
        toneMode: "None",
        rxToneCode: 0,
        txToneCode: 0,
        power: "High",
        bandwidth: "Wide",
        name: "",
      };
      const block = encodeChannelBlock(ch);
      assert.equal(block[8] & 0x20, 0x20); // duplex enabled
      assert.equal(block[8] & 0x40, 0); // negative offset

      const decoded = decodeChannelBlock(block, 2);
      assert.equal(decoded.duplex, "-");
    });

    it("should encode DCS tone mode", () => {
      const ch = {
        index: 3,
        rxFreq: 441.000,
        txFreq: 441.000,
        duplex: "none",
        toneMode: "DCS",
        rxToneCode: 10,
        txToneCode: 10,
        power: "High",
        bandwidth: "Wide",
        name: "",
      };
      const block = encodeChannelBlock(ch);
      assert.equal(block[9], 2); // DCS = 2
      assert.equal(block[10], 10);
      assert.equal(block[11], 10);
    });

    it("should handle empty channel (all zeros)", () => {
      const block = new Uint8Array(BAOFENG_CHANNEL_BLOCK_SIZE);
      // Fill with 0xFF (empty/unused in EEPROM)
      block.fill(0xff);
      const decoded = decodeChannelBlock(block, 0);
      // Should parse without error
      assert.equal(typeof decoded.rxFreq, "number");
    });
  });

  describe("encodeChannelName / decodeChannelName", () => {
    it("should round-trip a channel name", () => {
      const name = "VCALL";
      const encoded = encodeChannelName(name);
      assert.equal(encoded.length, 7);
      const decoded = decodeChannelName(encoded);
      assert.equal(decoded, "VCALL");
    });

    it("should handle empty name", () => {
      const encoded = encodeChannelName("");
      assert.equal(encoded[0], 0xff);
      assert.equal(decodeChannelName(encoded), "");
    });

    it("should truncate names longer than 7 chars", () => {
      const name = "LONGNAME!";
      const encoded = encodeChannelName(name);
      const decoded = decodeChannelName(encoded);
      assert.equal(decoded.length, 7);
      assert.equal(decoded, "LONGNAM");
    });
  });

  describe("channelAddress / channelNameAddress", () => {
    it("should compute correct channel data addresses", () => {
      assert.equal(channelAddress(0), 0x0000);
      assert.equal(channelAddress(1), 0x0010);
      assert.equal(channelAddress(127), 127 * 16);
    });

    it("should compute correct name addresses", () => {
      assert.equal(channelNameAddress(0), 0x1000);
      assert.equal(channelNameAddress(1), 0x1007);
      assert.equal(channelNameAddress(127), 0x1000 + 127 * 7);
    });
  });

  describe("BaofengProtocol static methods", () => {
    it("readCommand should produce a valid header", () => {
      const cmd = BaofengProtocol.readCommand(0x1000, 64);
      assert.equal(cmd.length, 5);
      assert.equal(cmd[0], 0xa5);
    });

    it("writeCommand should produce header + payload", () => {
      const data = new Uint8Array(16).fill(0xab);
      const cmd = BaofengProtocol.writeCommand(0x0010, data);
      assert.equal(cmd.length, 5 + 16);
      assert.equal(cmd[0], 0xa5);
    });

    it("isAck should validate response", () => {
      assert.ok(BaofengProtocol.isAck(new Uint8Array([0xa5])));
      assert.ok(!BaofengProtocol.isAck(new Uint8Array([0x00])));
      assert.ok(!BaofengProtocol.isAck(null));
      assert.ok(!BaofengProtocol.isAck(new Uint8Array([])));
    });

    it("calculateReadOps should produce valid operations", () => {
      const { readOps } = BaofengProtocol.calculateReadOps();
      assert.ok(readOps.length > 0);
      // Channel data: 128 * 16 = 2048 bytes at 64 bytes per read = 32 ops
      // Name data: 128 * 7 = 896 bytes at 64 bytes per read = 14 ops
      assert.equal(readOps.length, 32 + 14);
    });

    it("calculateWriteOps should produce valid operations", () => {
      const { writeOps } = BaofengProtocol.calculateWriteOps();
      assert.ok(writeOps.length > 0);
      assert.equal(writeOps.length, 32 + 14);
    });
  });
});

describe("ChannelModel", () => {
  describe("validateFrequency", () => {
    it("should accept VHF frequencies", () => {
      assert.ok(validateFrequency(146.520).valid);
      assert.ok(validateFrequency(136.0).valid);
      assert.ok(validateFrequency(174.0).valid);
    });

    it("should accept UHF frequencies", () => {
      assert.ok(validateFrequency(446.000).valid);
      assert.ok(validateFrequency(400.0).valid);
      assert.ok(validateFrequency(520.0).valid);
    });

    it("should reject out-of-band frequencies", () => {
      const result = validateFrequency(100.0);
      assert.ok(!result.valid);
      assert.ok(result.warning.includes("100.000"));
    });

    it("should accept zero (empty channel)", () => {
      assert.ok(validateFrequency(0).valid);
    });

    it("should reject mid-gap frequencies", () => {
      const result = validateFrequency(300.0);
      assert.ok(!result.valid);
    });
  });

  describe("validateChannel", () => {
    it("should return empty warnings for valid channel", () => {
      const ch = createDefaultChannel(0);
      ch.rxFreq = 146.520;
      ch.duplex = "none";
      assert.deepEqual(validateChannel(ch), []);
    });

    it("should warn on out-of-band RX frequency", () => {
      const ch = createDefaultChannel(0);
      ch.rxFreq = 100.0;
      const warnings = validateChannel(ch);
      assert.ok(warnings.length > 0);
      assert.ok(warnings[0].includes("100.000"));
    });

    it("should warn on name too long", () => {
      const ch = createDefaultChannel(0);
      ch.name = "VERYLONGNAME";
      const warnings = validateChannel(ch);
      assert.ok(warnings.some((w) => w.includes("7 characters")));
    });
  });

  describe("CTCSS tone lookups", () => {
    it("should round-trip CTCSS tone code", () => {
      const tone = 103.5;
      const code = ctcssToCode(tone);
      assert.equal(codeToCtcss(code), tone);
    });

    it("should return 0 for unknown CTCSS tone", () => {
      assert.equal(ctcssToCode(999.9), 0);
    });
  });

  describe("createDefaultChannels", () => {
    it("should create 128 channels", () => {
      const channels = createDefaultChannels();
      assert.equal(channels.length, 128);
      assert.equal(channels[0].index, 0);
      assert.equal(channels[127].index, 127);
      assert.equal(channels[0].rxFreq, 0);
    });
  });

  describe("CSV import/export", () => {
    it("should round-trip channels through CSV", () => {
      const channels = createDefaultChannels();
      channels[0] = {
        ...channels[0],
        rxFreq: 146.520,
        duplex: "+",
        toneMode: "CTCSS",
        rxToneCode: ctcssToCode(103.5),
        txToneCode: ctcssToCode(103.5),
        name: "VCALL",
        power: "High",
        bandwidth: "Wide",
      };
      channels[1] = {
        ...channels[1],
        rxFreq: 446.000,
        duplex: "none",
        toneMode: "None",
        name: "UHF",
        power: "Low",
        bandwidth: "Narrow",
      };

      const csv = channelsToCSV(channels);
      assert.ok(csv.includes("Channel,RX Freq"));
      assert.ok(csv.includes("146.52000"));

      const parsed = channelsFromCSV(csv);
      assert.ok(parsed.length >= 2);
      assert.ok(Math.abs(parsed[0].rxFreq - 146.52) < 0.001);
      assert.equal(parsed[0].name, "VCALL");
      assert.equal(parsed[1].name, "UHF");
    });

    it("should handle empty CSV gracefully", () => {
      const parsed = channelsFromCSV("");
      assert.equal(parsed.length, 0);
    });
  });

  describe("constants", () => {
    it("should have correct band limits", () => {
      assert.equal(VHF_MIN, 136);
      assert.equal(VHF_MAX, 174);
      assert.equal(UHF_MIN, 400);
      assert.equal(UHF_MAX, 520);
    });

    it("should have correct channel count", () => {
      assert.equal(BAOFENG_CHANNEL_COUNT, 128);
      assert.equal(BAOFENG_CHANNEL_BLOCK_SIZE, 16);
      assert.equal(BAOFENG_READ_BLOCK_SIZE, 64);
    });

    it("should have valid duplex and tone modes", () => {
      assert.ok(DUPLEX_MODES.includes("none"));
      assert.ok(DUPLEX_MODES.includes("+"));
      assert.ok(DUPLEX_MODES.includes("-"));
      assert.ok(DUPLEX_MODES.includes("split"));
      assert.ok(TONE_MODES.includes("None"));
      assert.ok(TONE_MODES.includes("CTCSS"));
      assert.ok(TONE_MODES.includes("DCS"));
    });

    it("should have CTCSS and DCS code tables", () => {
      assert.ok(CTCSS_TONES.length > 0);
      assert.ok(DCS_CODES.length > 0);
      assert.equal(CTCSS_TONES[0], 67.0);
    });
  });
});