import http from 'http';
import fs from 'fs';
import { PMTiles } from 'pmtiles';

class FileSource {
  constructor(path) {
    this.path = path;
  }
  async getKey() {
    return this.path;
  }
  async getBytes(offset, length) {
    const fd = await fs.promises.open(this.path, 'r');
    const { buffer } = await fd.read(Buffer.alloc(length), 0, length, offset);
    await fd.close();
    return { data: buffer.buffer };
  }
}

export class PmtilesServer {
  constructor(pmtPath, port = 0) {
    this.pmtPath = pmtPath;
    this.port = port;
    this.server = null;
    this.pmtiles = null;
    this.actualPort = null;
  }
  async start() {
    const source = new FileSource(this.pmtPath);
    this.pmtiles = new PMTiles(source);
    this.server = http.createServer(async (req, res) => {
      const url = new URL(req.url, `http://${req.headers.host}`);
      if (url.pathname === '/style.json') {
        const style = createOperatorStyle(`http://localhost:${this.actualPort}/tiles/{z}/{x}/{y}.mvt`);
        res.setHeader('Content-Type', 'application/json');
        res.end(JSON.stringify(style));
        return;
      }
      const m = url.pathname.match(/^\/tiles\/(\d+)\/(\d+)\/(\d+)\.mvt$/);
      if (m) {
        const [, z, x, y] = m;
        try {
          const tile = await this.pmtiles.getZxy(parseInt(z), parseInt(x), parseInt(y));
          if (tile?.data) {
            res.writeHead(200, { 'Content-Type': 'application/vnd.mapbox-vector-tile' });
            res.end(Buffer.from(tile.data));
          } else {
            res.writeHead(204);
            res.end();
          }
        } catch (e) {
          res.writeHead(500);
          res.end('Error');
        }
        return;
      }
      res.writeHead(404);
      res.end('Not found');
    });
    await new Promise((resolve) => this.server.listen(this.port || 0, () => resolve()));
    this.actualPort = this.server.address().port;
    return this.actualPort;
  }
  async stop() {
    if (this.server) {
      await new Promise((resolve) => this.server.close(() => resolve()));
      this.server = null;
    }
  }
}

/** INDI/ATA gray-black operator console map style (offline vector tiles). */
export function createOperatorStyle(tileUrl) {
  return {
    version: 8,
    sources: {
      protomaps: { type: 'vector', tiles: [tileUrl], maxzoom: 14 },
    },
    layers: [
      { id: 'background', type: 'background', paint: { 'background-color': '#111111' } },
      { id: 'water', type: 'fill', source: 'protomaps', 'source-layer': 'water', paint: { 'fill-color': '#1a1a1a' } },
      { id: 'landuse', type: 'fill', source: 'protomaps', 'source-layer': 'landuse', paint: { 'fill-color': '#161616' } },
      { id: 'roads', type: 'line', source: 'protomaps', 'source-layer': 'roads', paint: { 'line-color': '#333333', 'line-width': 1 } },
      { id: 'boundaries', type: 'line', source: 'protomaps', 'source-layer': 'boundaries', paint: { 'line-color': '#4fc3f7', 'line-width': 1 } },
    ],
  };
}

/** @deprecated Use createOperatorStyle — kept for older call sites */
export const createPhosphorStyle = createOperatorStyle;

export { FileSource };
