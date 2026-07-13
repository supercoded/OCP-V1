#!/usr/bin/env node

const https = require('https');
const fs = require('fs');
const path = require('path');
const { execSync } = require('child_process');

// Determine date strings for today and yesterday in YYYYMMDD format
function ymd(date) {
  const yyyy = date.getFullYear();
  const mm = String(date.getMonth() + 1).padStart(2, '0');
  const dd = String(date.getDate()).padStart(2, '0');
  return `${yyyy}${mm}${dd}`;
}

async function fetchHead(url) {
  return new Promise((resolve, reject) => {
    https.request(url, { method: 'HEAD' }, (res) => {
      resolve(res);
    }).on('error', reject).end();
  });
}

async function downloadPmtiles(dateStr) {
  const url = `https://build.protomaps.com/${dateStr}.pmtiles`;
  const res = await fetchHead(url);
  if (res.statusCode !== 200) return false;
  const outDir = path.join(require('os').homedir(), '.cache', 'ocp-maps');
  fs.mkdirSync(outDir, { recursive: true });
  const outPath = path.join(outDir, `us-${dateStr}.pmtiles`);
  console.log(`Downloading ${url} -> ${outPath}`);
  const file = fs.createWriteStream(outPath);
  return new Promise((resolve, reject) => {
    https.get(url, (r) => {
      r.pipe(file);
      file.on('finish', () => {
        file.close(() => resolve(outPath));
      });
    }).on('error', (e) => {
      fs.unlinkSync(outPath);
      reject(e);
    });
  });
}

(async () => {
  const today = new Date();
  const yesterday = new Date(Date.now() - 86400000);
  const dates = [ymd(today), ymd(yesterday)];
  for (const d of dates) {
    try {
      const result = await downloadPmtiles(d);
      if (result) {
        console.log('Downloaded PMTiles file to', result);
        console.log('To extract a region, you can use the pmtiles CLI:');
        console.log(`pmtiles extract ${result} --bbox <minLon,minLat,maxLon,maxLat> -o region.pmtiles`);
        process.exit(0);
      }
    } catch (e) {
      // ignore and try next date
    }
  }
  console.error('Failed to download PMTiles for today or yesterday.');
  process.exit(1);
})();
