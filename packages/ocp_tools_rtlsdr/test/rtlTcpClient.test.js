import { describe, it, before, after } from "node:test";
import assert from "node:assert";
import { createServer } from "net";
import { RtlTcpClient, RTL_TCP_COMMANDS } from "../src/rtlTcpClient.js";

describe("RtlTcpClient", () => {
  let server;
  let port;

  before(async () => {
    server = createServer();
    await new Promise((resolve) => {
      server.listen(0, "127.0.0.1", () => {
        port = server.address().port;
        resolve();
      });
    });
  });

  after(() => {
    server.close();
  });

  it("connects and receives dongle info", async () => {
    let socket;
    server.once("connection", (s) => {
      socket = s;
      const info = Buffer.alloc(12);
      info.write("RTL0", 0, 4, "ascii");
      info.writeUInt32LE(1, 4); // tuner type
      info.writeUInt32LE(29, 8); // gain count
      s.write(info);
    });

    const client = new RtlTcpClient({ host: "127.0.0.1", port, autoReconnect: false });
    const donglePromise = new Promise((resolve) => client.once("dongleInfo", resolve));
    const result = await client.connect();
    assert.strictEqual(result.connected, true);

    const dongleInfo = await donglePromise;
    assert.strictEqual(dongleInfo.magic, "RTL0");
    assert.strictEqual(dongleInfo.tunerType, 1);
    assert.strictEqual(dongleInfo.tunerGainCount, 29);

    await client.disconnect();
    socket?.destroy();
  });

  it("parses interleaved IQ samples", async () => {
    let socket;
    server.once("connection", (s) => {
      socket = s;
      const info = Buffer.alloc(12);
      info.write("RTL0", 0, 4, "ascii");
      info.writeUInt32LE(1, 4);
      info.writeUInt32LE(29, 8);
      s.write(info);
      // 4 samples
      s.write(Buffer.from([127, 128, 127, 128, 127, 128, 127, 128]));
    });

    const client = new RtlTcpClient({ host: "127.0.0.1", port, autoReconnect: false });
    const iqPromise = new Promise((resolve) => client.once("iq", (buf, count) => resolve({ buf, count })));
    await client.connect();
    const { buf, count } = await iqPromise;
    assert.strictEqual(count, 4);
    assert.strictEqual(buf.length, 8);
    await client.disconnect();
    socket?.destroy();
  });

  it("sends commands in 5-byte BE format", async () => {
    let socket;
    const received = [];
    server.once("connection", (s) => {
      socket = s;
      const info = Buffer.alloc(12);
      info.write("RTL0", 0, 4, "ascii");
      info.writeUInt32LE(1, 4);
      info.writeUInt32LE(29, 8);
      s.write(info);
      s.on("data", (d) => received.push(d));
    });

    const client = new RtlTcpClient({ host: "127.0.0.1", port, autoReconnect: false });
    await client.connect();
    client.setCenterFreq(145000000);
    client.setSampleRate(2048000);

    await new Promise((r) => setTimeout(r, 50));

    assert.strictEqual(received.length, 2);
    assert.strictEqual(received[0].readUInt8(0), RTL_TCP_COMMANDS.SET_FREQ);
    assert.strictEqual(received[0].readUInt32BE(1), 145000000);
    assert.strictEqual(received[1].readUInt8(0), RTL_TCP_COMMANDS.SET_SAMPLE_RATE);
    assert.strictEqual(received[1].readUInt32BE(1), 2048000);

    await client.disconnect();
    socket?.destroy();
  });
});
