/**
 * Baofeng channel data model and validation.
 *
 * UV-5RM supports 128 channels across VHF (136-174 MHz) and UHF (400-520 MHz).
 */

/** VHF band limits */
export const VHF_MIN = 136;
export const VHF_MAX = 174;

/** UHF band limits */
export const UHF_MIN = 400;
export const UHF_MAX = 520;

/** Duplex modes */
export const DUPLEX_MODES = ["none", "+", "-", "split"];

/** Tone modes */
export const TONE_MODES = ["None", "CTCSS", "DCS"];

/** Power levels */
export const POWER_LEVELS = ["High", "Low"];

/** Bandwidth options */
export const BANDWIDTH_OPTIONS = ["Wide", "Narrow"];

/**
 * Standard CTCSS tone frequencies (in Hz) used by Baofeng/CHIRP.
 */
export const CTCSS_TONES = [
  67.0, 69.3, 71.9, 74.4, 77.0, 79.7, 82.5, 85.4,
  88.5, 91.5, 94.8, 97.4, 100.0, 103.5, 107.2, 110.9,
  114.8, 118.8, 123.0, 127.3, 131.8, 136.5, 141.3, 146.2,
  151.4, 156.7, 159.8, 162.2, 165.5, 167.9, 171.3, 173.8,
  177.3, 179.9, 183.5, 186.2, 189.9, 192.8, 196.6, 199.5,
  203.5, 206.5, 210.7, 218.1, 225.7, 229.1, 233.6, 241.8,
  250.3, 254.1,
];

/**
 * Standard DCS codes used by Baofeng/CHIRP.
 */
export const DCS_CODES = [
  23,  25,  26,  31,  32,  36,  43,  47,
  51,  53,  54,  65,  71,  72,  73,  74,
  114, 115, 116, 122, 125, 131, 132, 134,
  143, 144, 145, 152, 155, 156, 162, 165,
  172, 174, 205, 212, 223, 225, 226, 243,
  244, 245, 246, 251, 252, 255, 261, 263,
  265, 266, 271, 274, 306, 311, 315, 325,
  331, 332, 343, 346, 351, 356, 364, 365,
  371, 411, 412, 413, 423, 431, 432, 445,
  446, 452, 454, 455, 462, 464, 465, 466,
  503, 506, 516, 523, 526, 532, 546, 565,
  606, 612, 624, 627, 631, 632, 654, 662,
  664, 703, 712, 723, 731, 732, 734, 743,
  754,
];

/**
 * Validate a frequency (in MHz) against UV-5RM band limits.
 * @param {number} freqMhz
 * @returns {{ valid: boolean, warning?: string }}
 */
export function validateFrequency(freqMhz) {
  if (freqMhz === 0) return { valid: true };
  if (freqMhz >= VHF_MIN && freqMhz <= VHF_MAX) return { valid: true };
  if (freqMhz >= UHF_MIN && freqMhz <= UHF_MAX) return { valid: true };
  return {
    valid: false,
    warning: `Frequency ${freqMhz.toFixed(3)} MHz is outside UV-5RM bands (VHF: ${VHF_MIN}-${VHF_MAX}, UHF: ${UHF_MIN}-${UHF_MAX})`,
  };
}

/**
 * Validate a complete channel entry.
 * @param {object} channel
 * @returns {string[]} Array of warning strings
 */
export function validateChannel(channel) {
  const warnings = [];

  if (channel.rxFreq > 0) {
    const rxVal = validateFrequency(channel.rxFreq);
    if (!rxVal.valid) warnings.push(rxVal.warning);
  }

  if (channel.duplex === "+" || channel.duplex === "-") {
    const offset = channel.rxFreq + (channel.duplex === "+" ? (channel.txFreq || 0) : -(channel.txFreq || 0));
    const txVal = validateFrequency(offset);
    if (!txVal.valid) warnings.push(`TX freq ${offset.toFixed(3)} MHz out of band`);
  }

  if (channel.duplex === "split" && channel.txFreq > 0) {
    const txVal = validateFrequency(channel.txFreq);
    if (!txVal.valid) warnings.push(txVal.warning);
  }

  if (channel.name && channel.name.length > 7) {
    warnings.push(`Name "${channel.name}" exceeds 7 characters`);
  }

  return warnings;
}

/**
 * Find CTCSS tone code index.
 */
export function ctcssToCode(freqHz) {
  const idx = CTCSS_TONES.indexOf(freqHz);
  return idx >= 0 ? idx : 0;
}

/**
 * Find CTCSS frequency for a code index.
 */
export function codeToCtcss(code) {
  return code < CTCSS_TONES.length ? CTCSS_TONES[code] : 0;
}

/**
 * Find DCS code index.
 */
export function dcsToCode(dcsCode) {
  const idx = DCS_CODES.indexOf(dcsCode);
  return idx >= 0 ? idx : 0;
}

/**
 * Find DCS number for an index.
 */
export function codeToDcs(index) {
  return index < DCS_CODES.length ? DCS_CODES[index] : 0;
}

/**
 * Create a default empty channel.
 * @param {number} index
 * @returns {object}
 */
export function createDefaultChannel(index) {
  return {
    index,
    rxFreq: 0,
    txFreq: 0,
    duplex: "none",
    toneMode: "None",
    rxToneCode: 0,
    txToneCode: 0,
    power: "High",
    bandwidth: "Wide",
    name: "",
  };
}

/**
 * Create an array of 128 default channels.
 */
export function createDefaultChannels() {
  return Array.from({ length: 128 }, (_, i) => createDefaultChannel(i));
}

/**
 * Serialize channels to CSV.
 * @param {object[]} channels
 * @returns {string}
 */
export function channelsToCSV(channels) {
  const header = "Channel,RX Freq,TX Freq,Duplex,Tone Mode,RX Tone,TX Tone,Name,Power,Bandwidth";
  const rows = channels.map((ch) => {
    const rxFreq = ch.rxFreq > 0 ? ch.rxFreq.toFixed(5) : "";
    const txFreq = ch.txFreq > 0 ? ch.txFreq.toFixed(5) : "";
    const rxTone = ch.toneMode === "CTCSS" ? CTCSS_TONES[ch.rxToneCode] : ch.toneMode === "DCS" ? DCS_CODES[ch.rxToneCode] : "";
    const txTone = ch.toneMode === "CTCSS" ? CTCSS_TONES[ch.txToneCode] : ch.toneMode === "DCS" ? DCS_CODES[ch.txToneCode] : "";
    return `${ch.index + 1},${rxFreq},${txFreq},${ch.duplex},${ch.toneMode},${rxTone},${txTone},${ch.name},${ch.power},${ch.bandwidth}`;
  });
  return [header, ...rows].join("\n");
}

/**
 * Parse CSV string into channel data.
 * @param {string} csv
 * @returns {object[]}
 */
export function channelsFromCSV(csv) {
  const lines = csv.trim().split("\n");
  if (lines.length < 2) return [];

  const channels = [];
  for (let i = 1; i < lines.length; i++) {
    const cols = lines[i].split(",");
    if (cols.length < 10) continue;

    const idx = parseInt(cols[0], 10) - 1;
    if (isNaN(idx) || idx < 0 || idx > 127) continue;

    const rxFreq = cols[1] ? parseFloat(cols[1]) : 0;
    const txFreq = cols[2] ? parseFloat(cols[2]) : 0;
    const duplex = DUPLEX_MODES.includes(cols[3]) ? cols[3] : "none";
    const toneMode = TONE_MODES.includes(cols[4]) ? cols[4] : "None";

    let rxToneCode = 0;
    let txToneCode = 0;
    const rxToneVal = parseFloat(cols[5]);
    const txToneVal = parseFloat(cols[6]);
    if (toneMode === "CTCSS") {
      rxToneCode = ctcssToCode(rxToneVal);
      txToneCode = ctcssToCode(txToneVal);
    } else if (toneMode === "DCS") {
      rxToneCode = dcsToCode(rxToneVal);
      txToneCode = dcsToCode(txToneVal);
    }

    const name = (cols[7] || "").substring(0, 7);
    const power = POWER_LEVELS.includes(cols[8]) ? cols[8] : "High";
    const bandwidth = BANDWIDTH_OPTIONS.includes(cols[9]) ? cols[9] : "Wide";

    channels.push({
      index: idx, rxFreq, txFreq, duplex, toneMode,
      rxToneCode, txToneCode, power, bandwidth, name,
    });
  }
  return channels;
}