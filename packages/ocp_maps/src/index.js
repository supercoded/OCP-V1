import http from 'http';
import fs from 'fs';
import pmtilesPkg from 'pmtiles';
const { PMTiles } = pmtilesPkg;

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
    await new Promise((resolve) => this.server.listen(this.port || 0, "127.0.0.1", () => resolve()));
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

/** Full-color Protomaps-like operator map style (offline vector tiles). */
export function createOperatorStyle(tileUrl) {
  return {
    version: 8,
    sources: {
      protomaps: { type: 'vector', tiles: [tileUrl], maxzoom: 14 },
    },
    layers: [
      { id: 'background', type: 'background', paint: { 'background-color': '#f2efe9' } },
      {
        id: 'earth',
        type: 'fill',
        source: 'protomaps',
        'source-layer': 'earth',
        paint: { 'fill-color': '#ebe6dc' },
      },
      {
        id: 'landuse',
        type: 'fill',
        source: 'protomaps',
        'source-layer': 'landuse',
        paint: {
          'fill-color': [
            'match',
            ['get', 'kind'],
            'park', '#c8e6c9',
            'forest', '#a5d6a7',
            'cemetery', '#c5e1a5',
            'hospital', '#ffcdd2',
            'school', '#fff9c4',
            'industrial', '#d7ccc8',
            '#dcedc8',
          ],
          'fill-opacity': 0.85,
        },
      },
      {
        id: 'water',
        type: 'fill',
        source: 'protomaps',
        'source-layer': 'water',
        paint: { 'fill-color': '#90caf9' },
      },
      {
        id: 'boundaries',
        type: 'line',
        source: 'protomaps',
        'source-layer': 'boundaries',
        paint: {
          'line-color': '#7986cb',
          'line-width': 1,
          'line-dasharray': [2, 2],
        },
      },
      {
        id: 'roads-minor',
        type: 'line',
        source: 'protomaps',
        'source-layer': 'roads',
        filter: ['in', 'kind', 'minor_road', 'other', 'path'],
        paint: { 'line-color': '#ffffff', 'line-width': 1 },
      },
      {
        id: 'roads-major',
        type: 'line',
        source: 'protomaps',
        'source-layer': 'roads',
        filter: ['in', 'kind', 'major_road', 'medium_road'],
        paint: { 'line-color': '#ffcc80', 'line-width': 1.5 },
      },
      {
        id: 'roads-highway',
        type: 'line',
        source: 'protomaps',
        'source-layer': 'roads',
        filter: ['==', 'kind', 'highway'],
        paint: { 'line-color': '#ff8a65', 'line-width': 2.5 },
      },
      {
        id: 'buildings',
        type: 'fill',
        source: 'protomaps',
        'source-layer': 'buildings',
        paint: { 'fill-color': '#cfd8dc', 'fill-opacity': 0.7 },
      },
      {
        id: 'places',
        type: 'symbol',
        source: 'protomaps',
        'source-layer': 'places',
        layout: {
          'text-field': ['get', 'name'],
          'text-size': 11,
          'text-font': ['Open Sans Regular', 'Arial Unicode MS Regular'],
        },
        paint: {
          'text-color': '#37474f',
          'text-halo-color': '#ffffff',
          'text-halo-width': 1,
        },
      },
    ],
  };
}

/** @deprecated Use createOperatorStyle — kept for older call sites */
export const createPhosphorStyle = createOperatorStyle;

export { FileSource };
