/**
 * Curated public online SDR receivers and directory links for OCP Spectrum (Online mode).
 */

/** @typedef {"websdr"|"kiwisdr"|"openwebrx"|"directory"} OnlineReceiverType */

/**
 * @typedef {Object} OnlineReceiver
 * @property {string} id
 * @property {string} name
 * @property {string} url
 * @property {string} [mobileUrl]
 * @property {OnlineReceiverType} type
 * @property {string} [location]
 * @property {string} [region]
 * @property {string[]} bands
 * @property {string[]} capabilities
 * @property {string} [notes]
 * @property {boolean} [embeddable]
 */

/** @type {OnlineReceiver[]} */
export const CURATED_ONLINE_RECEIVERS = [
  {
    id: "n8mdp-websdr",
    name: "N8MDP WebSDR",
    url: "http://n8mdp.ddns.net:8904/",
    mobileUrl: "http://n8mdp.ddns.net:8904/m.html",
    type: "websdr",
    location: "Auburn Township, Ohio, USA",
    region: "North America",
    bands: ["80m", "40m", "HF"],
    capabilities: ["USB", "LSB", "CW", "AM", "FM", "waterfall", "memories", "mobile", "s-meter"],
    notes: "RTL-SDR + Ham-It-Up on Raspberry Pi 4 — CHIRP-compatible Baofeng neighbor station.",
    embeddable: true,
  },
  {
    id: "twente-websdr",
    name: "University of Twente WebSDR",
    url: "http://websdr.ewi.utwente.nl:8901/",
    mobileUrl: "http://websdr.ewi.utwente.nl:8901/m.html",
    type: "websdr",
    location: "Enschede, Netherlands",
    region: "Europe",
    bands: ["LF", "MF", "HF", "6m", "2m"],
    capabilities: ["USB", "LSB", "CW", "AM", "FM", "waterfall", "memories", "mobile", "wideband"],
    notes: "Original wide-band WebSDR reference installation.",
    embeddable: true,
  },
  {
    id: "k3fef-websdr",
    name: "K3FEF Radio Ranch",
    url: "http://k3fef.com:8901/",
    type: "websdr",
    location: "Pennsylvania, USA",
    region: "North America",
    bands: ["HF"],
    capabilities: ["USB", "LSB", "CW", "AM", "FM", "waterfall", "memories"],
    notes: "HF WebSDR in eastern Pennsylvania.",
    embeddable: true,
  },
  {
    id: "hackgreen-websdr",
    name: "Hack Green Nuclear Bunker",
    url: "http://hackgreensdr.org:8901/",
    type: "websdr",
    location: "Nantwich, United Kingdom",
    region: "Europe",
    bands: ["HF"],
    capabilities: ["USB", "LSB", "CW", "AM", "FM", "waterfall", "memories"],
    embeddable: true,
  },
  {
    id: "kiwi-public-map",
    name: "KiwiSDR Public Map",
    url: "http://rx.linkfanel.net/",
    type: "directory",
    location: "Worldwide",
    region: "Global",
    bands: ["0-30 MHz", "HF"],
    capabilities: ["map", "multi-user", "extensions", "WSPR"],
    notes: "Interactive map of community KiwiSDR receivers — pick a pin to tune.",
    embeddable: false,
  },
  {
    id: "kiwi-public-list",
    name: "KiwiSDR Public List",
    url: "http://kiwisdr.com/public/",
    type: "directory",
    location: "Worldwide",
    region: "Global",
    bands: ["0-30 MHz", "HF"],
    capabilities: ["list", "multi-user"],
    embeddable: false,
  },
  {
    id: "receiverbook",
    name: "Receiverbook Directory",
    url: "https://www.receiverbook.de/",
    type: "directory",
    location: "Worldwide",
    region: "Global",
    bands: ["VLF", "LF", "MF", "HF", "VHF", "UHF"],
    capabilities: ["filter", "OpenWebRX", "WebSDR", "KiwiSDR", "ham", "broadcast"],
    notes: "Community directory for OpenWebRX, WebSDR, and KiwiSDR stations.",
    embeddable: false,
  },
  {
    id: "websdr-org",
    name: "WebSDR.org Directory",
    url: "http://www.websdr.org/",
    type: "directory",
    location: "Worldwide",
    region: "Global",
    bands: ["LF", "MF", "HF", "VHF", "UHF"],
    capabilities: ["filter", "WebSDR", "multi-user"],
    embeddable: false,
  },
];

/**
 * @param {OnlineReceiver[]} receivers
 * @param {string[]} favoriteIds
 * @returns {Array<OnlineReceiver & { favorite: boolean; status: string }>}
 */
export function mergeReceiverFavorites(receivers, favoriteIds = []) {
  const fav = new Set(favoriteIds);
  return receivers.map((r) => ({
    ...r,
    favorite: fav.has(r.id),
    status: "unknown",
  }));
}

/**
 * @param {Array<OnlineReceiver & { status?: string }>} receivers
 * @param {{ type?: string; region?: string; favoritesOnly?: boolean; query?: string }} filter
 */
export function filterReceivers(receivers, filter = {}) {
  const q = (filter.query || "").trim().toLowerCase();
  return receivers.filter((r) => {
    if (filter.favoritesOnly && !r.favorite) return false;
    if (filter.type && filter.type !== "all" && r.type !== filter.type) return false;
    if (filter.region && filter.region !== "all" && r.region !== filter.region) return false;
    if (!q) return true;
    const hay = [r.name, r.location, r.region, r.notes, ...(r.bands || []), ...(r.capabilities || [])]
      .filter(Boolean)
      .join(" ")
      .toLowerCase();
    return hay.includes(q);
  });
}

/**
 * Probe whether a receiver URL responds (best-effort; some block HEAD).
 * @param {string} url
 * @param {number} [timeoutMs]
 * @returns {Promise<"online"|"offline">}
 */
export async function probeReceiverUrl(url, timeoutMs = 6000) {
  if (!url) return "offline";
  const controller = new AbortController();
  const timer = setTimeout(() => controller.abort(), timeoutMs);
  try {
    let res = await fetch(url, { method: "HEAD", signal: controller.signal, redirect: "follow" });
    if (res.status >= 400 || res.status === 405) {
      res = await fetch(url, { method: "GET", signal: controller.signal, redirect: "follow", headers: { Range: "bytes=0-0" } });
    }
    return res.ok || (res.status >= 200 && res.status < 400) ? "online" : "offline";
  } catch {
    return "offline";
  } finally {
    clearTimeout(timer);
  }
}

/**
 * @param {Array<OnlineReceiver & { status?: string }>} receivers
 * @param {(id: string, status: string) => void} [onUpdate]
 */
export async function probeAllReceivers(receivers, onUpdate) {
  const out = [];
  for (const r of receivers) {
    if (r.type === "directory") {
      const entry = { ...r, status: "online" };
      out.push(entry);
      onUpdate?.(r.id, "online");
      continue;
    }
    const status = await probeReceiverUrl(r.url);
    const entry = { ...r, status };
    out.push(entry);
    onUpdate?.(r.id, status);
  }
  return out;
}

/**
 * Resolve listen URL for a receiver (mobile variant optional).
 * @param {OnlineReceiver} receiver
 * @param {{ mobile?: boolean }} [opts]
 */
export function resolveListenUrl(receiver, opts = {}) {
  if (opts.mobile && receiver.mobileUrl) return receiver.mobileUrl;
  return receiver.url;
}
