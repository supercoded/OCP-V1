// Type shims for local workspace packages that ship plain JS without declarations.
declare module "@ocp/network" {
  export class NetworkState extends NodeJS.EventEmitter {
    constructor(opts?: { nodeTimeoutMs?: number });
    on(event: "packetRelayed" | "nodeAdded" | "nodeUpdated" | "nodeLost" | string, listener: (...args: any[]) => void): this;
    onPacket(packet: any): void;
    onNodeInfo(nodeInfo: any): void;
    getNodes(): any[];
  }
}

declare module "@ocp/offline-core" {
  export function discoverTransport(options: any): Promise<any>;
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
