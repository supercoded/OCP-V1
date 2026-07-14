export { BaofengProtocol } from "./baofengProtocol.js";
export { BaofengTransport } from "./baofengTransport.js";
export {
  listSerialPorts,
  scoreProgrammingCable,
  pickBestProgrammingPort,
} from "./serialPorts.js";
export { shouldUseSerialBridge, createBridgeIo } from "./serialBridge.js";
export {
  validateFrequency,
  validateChannel,
  createDefaultChannel,
  createDefaultChannels,
  channelsToCSV,
  channelsFromCSV,
  ctcssToCode,
  codeToCtcss,
  dcsToCode,
  codeToDcs,
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
} from "./channelModel.js";
