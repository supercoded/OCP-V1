// Type shims for local workspace packages that ship plain JS without declarations.
declare module "@ocp/network" {
  export class NetworkState extends NodeJS.EventEmitter {
    constructor(opts?: { nodeTimeoutMs?: number; replayWindowSize?: number });
    on(event: "packetRelayed" | "packetReplay" | "nodeAdded" | "nodeUpdated" | "nodeLost" | string, listener: (...args: any[]) => void): this;
    onPacket(packet: any): boolean | void;
    onNodeInfo(nodeInfo: any): void;
    getNodes(): any[];
    getRoutes(): any[];
    getSeenPacketCount(): number;
  }
}

declare module "@ocp/offline-core" {
  export function discoverTransport(options: any): Promise<any>;
  export class LocalKeyCipher {
    constructor(passphrase: string, salt?: string | Buffer);
    static fromKey(key: Buffer): LocalKeyCipher;
    static deriveKey(passphrase: string, salt: string | Buffer): Buffer;
    encrypt(plaintext: string): string;
    decrypt(payload: string): string;
  }
  export class PinVault {
    constructor(vaultPath: string);
    cipher: LocalKeyCipher | null;
    readonly isUnlocked: boolean;
    isConfigured(): Promise<boolean>;
    setPin(pin: string): Promise<{ ok: boolean }>;
    unlock(pin: string): Promise<LocalKeyCipher>;
    lock(): void;
    changePin(currentPin: string, newPin: string): Promise<{ ok: boolean }>;
    clearPin(): Promise<{ ok: boolean }>;
  }
  export class JsonFileOfflineStore {
    constructor(opts: { dbPath: string; keyCipher?: LocalKeyCipher | null; encryptAtRest?: boolean });
    encryptAtRest: boolean;
    setKeyCipher(keyCipher: LocalKeyCipher | null): void;
    init(): Promise<void>;
  }
  export function crc32(data: Buffer | Uint8Array | string): number;
  export function appendCrc32(data: Buffer | Uint8Array): Buffer;
  export function verifyCrc32(data: Buffer | Uint8Array): boolean;
}

declare module "@ocp/bridge-meshtastic" {
  export class MeshtasticTransport extends NodeJS.EventEmitter {
    constructor(endpoint: { host: string; port: number }, options?: any);
    kind: string;
    endpoint: any;
    connected: boolean;
    options: any;
    connect(): Promise<void>;
    disconnect(): Promise<void>;
    sendFrame(frame: any): Promise<void>;
    on(event: "frame" | "connected" | "disconnected" | "error" | "sent" | "received" | string, listener: (...args: any[]) => void): this;
  }
}

declare module "@ocp/tools-ruview" {
  export class RuViewClient extends NodeJS.EventEmitter {
    constructor(cfg?: { host?: string; wsPort?: number; reconnect?: boolean });
    on(event: "sensing" | "error" | "open" | "close" | string, listener: (...args: any[]) => void): this;
    start(): void;
    stop(): void;
  }
}

declare module "@ocp/tools-rtlsdr" {
  export class RtlTcpClient extends NodeJS.EventEmitter {
    constructor(cfg?: { host?: string; port?: number; autoReconnect?: boolean });
    on(event: "dongleInfo" | "iq" | "error" | "close" | "recording:started" | "recording:stopped" | "recording:error" | string, listener: (...args: any[]) => void): this;
    connect(): Promise<void>;
    disconnect(): void;
    destroy(): void;
    setCenterFreq(hz: number): void;
    setGainMode(manual: boolean): void;
    setGain(gain: number): void;
    startRecording(filename?: string): any;
    stopRecording(): any;
  }
  export class SpectrumProcessor extends NodeJS.EventEmitter {
    constructor(cfg?: { fftSize?: number; sampleRate?: number; centerFreq?: number });
    on(event: "spectrum" | string, listener: (...args: any[]) => void): this;
    feedInterleavedUint8(samples: Uint8Array): void;
    configure(cfg: Partial<{ centerFreq: number; sampleRate: number; fftSize: number }>): void;
    destroy(): void;
    centerFreq?: number;
    sampleRate?: number;
  }
  export class MockRtlSource extends NodeJS.EventEmitter {
    constructor(cfg?: { sampleRate?: number; centerFreq?: number; carriers?: { freqOffset: number; amplitude: number }[] });
    on(event: "iq" | string, listener: (...args: any[]) => void): this;
    start(): void;
    stop(): void;
  }
}

declare module "@ocp/maps" {
  export class PmtilesServer {
    constructor(filePath: string);
    start(): Promise<number>;
    stop(): Promise<void>;
  }
}

declare module "@ocp/bridge-baofeng" {
  export class BaofengTransport extends NodeJS.EventEmitter {
    constructor(cfg?: { portName?: string; baudRate?: number });
    connect(): Promise<void>;
    disconnect(): Promise<void>;
    readAllChannels(): Promise<any[]>;
    writeAllChannels(channels: any[]): Promise<void>;
    onProgress?: (info: { current: number; total: number; phase: string }) => void;
  }
}

declare module "@ocp/plugin-api" {
  export const PERMISSIONS: {
    STATE_READ: string;
    NETWORK_READ: string;
    MESSAGING_SEND: string;
    DEVICE_CONNECT: string;
  };
  export const CAPABILITIES: {
    STATUS_PROVIDER: string;
    DEVICE_ADAPTER: string;
    UI_CONTRIBUTION: string;
  };
  export function validateManifest(manifest: any): { ok: boolean; error?: string };
  export class PluginHost extends NodeJS.EventEmitter {
    constructor(opts?: { allowedPermissions?: string[]; getAppState?: () => any });
    install(plugin: any): Promise<{ ok: boolean; id: string }>;
    uninstall(id: string): Promise<{ ok: boolean }>;
    activate(id: string): Promise<{ ok: boolean; already?: boolean }>;
    deactivate(id: string): Promise<{ ok: boolean; already?: boolean }>;
    list(): any[];
    getCapabilities(name: string): Array<{ pluginId: string; impl: any }>;
    getCapability(name: string): any;
  }
}

declare module "@ocp/plugin-example" {
  export function createDiagnosticsPlugin(): any;
}
