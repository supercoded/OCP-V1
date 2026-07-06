import { TransportConnection } from "../../../packages/offline-core/src/transport/transportConnection.js";
import { MeshtasticCodec } from "./meshtasticCodec.js";
import { createConnection, Socket } from "node:net";

/**
 * Transport adapter for Meshtastic devices
 * Bridges OCP transport interface with Meshtastic hardware
 */
export class MeshtasticTransport extends TransportConnection {
  constructor(endpoint, options = {}) {
    super("meshtastic", endpoint);
    this.codec = new MeshtasticCodec();
    this.options = {
      reconnectInterval: 5000,
      maxRetries: 3,
      ...options
    };
    this.socket = null;
    this.reconnectTimer = null;
    this.retryCount = 0;
    this.buffer = Buffer.alloc(0);
  }

  /**
   * Connect to Meshtastic device via TCP
   */
  async connect() {
    return new Promise((resolve, reject) => {
      try {
        // Validate endpoint
        if (!this.endpoint || !this.endpoint.host || !this.endpoint.port) {
          throw new Error("Invalid endpoint - must specify host and port");
        }

        console.log(`Connecting to Meshtastic device at ${this.endpoint.host}:${this.endpoint.port}`);
        
        // Create TCP socket
        this.socket = createConnection({
          host: this.endpoint.host,
          port: this.endpoint.port
        });

        // Handle connection success
        this.socket.on("connect", () => {
          console.log("✅ Connected to Meshtastic device");
          this.connected = true;
          this.retryCount = 0;
          
          // Clear any reconnect timers
          if (this.reconnectTimer) {
            clearTimeout(this.reconnectTimer);
            this.reconnectTimer = null;
          }
          
          this.emit("connected", { 
            kind: this.kind, 
            endpoint: this.endpoint,
            timestamp: new Date().toISOString()
          });
          
          // Request initial configuration
          this.#requestConfig();
          
          resolve();
        });

        // Handle incoming data
        this.socket.on("data", (data) => {
          this.#handleRawData(data);
        });

        // Handle connection errors
        this.socket.on("error", (error) => {
          console.error("❌ Socket error:", error.message);
          this.#handleConnectionError(error);
          reject(error);
        });

        // Handle connection close
        this.socket.on("close", () => {
          console.log("🔌 Connection to Meshtastic device closed");
          this.connected = false;
          this.emit("disconnected", { 
            kind: this.kind, 
            endpoint: this.endpoint,
            timestamp: new Date().toISOString()
          });
          
          // Attempt reconnection if enabled
          if (this.options.reconnectInterval && this.retryCount < this.options.maxRetries) {
            this.retryCount++;
            this.#scheduleReconnect();
          }
        });

        // Set socket timeout
        this.socket.setTimeout(30000);
        this.socket.on("timeout", () => {
          console.error("⏰ Socket timeout");
          this.socket.destroy();
        });

      } catch (error) {
        console.error("Failed to create socket connection:", error.message);
        this.#handleConnectionError(error);
        reject(error);
      }
    });
  }

  /**
   * Disconnect from Meshtastic device
   */
  async disconnect() {
    // Clear reconnect timers
    if (this.reconnectTimer) {
      clearTimeout(this.reconnectTimer);
      this.reconnectTimer = null;
    }
    
    // Close socket if open
    if (this.socket) {
      this.socket.destroy();
      this.socket = null;
    }
    
    this.connected = false;
    this.retryCount = 0;
    
    this.emit("disconnected", { 
      kind: this.kind, 
      endpoint: this.endpoint,
      timestamp: new Date().toISOString()
    });
  }

  /**
   * Send a frame to the Meshtastic device
   * @param {Object} frame - OCP frame to send
   */
  async sendFrame(frame) {
    if (!this.connected || !this.socket) {
      throw new Error("Meshtastic transport is not connected");
    }
    
    try {
      // Encode the frame using the codec
      const encoded = this.codec.encodeToRadio(frame);
      
      // Send via TCP socket
      this.socket.write(encoded);
      
      this.emit("sent", { 
        kind: this.kind, 
        bytes: encoded.length,
        frameId: frame.id,
        timestamp: new Date().toISOString()
      });
      
    } catch (error) {
      this.emit("error", { 
        kind: this.kind, 
        endpoint: this.endpoint,
        error: `Failed to send frame: ${error.message}`,
        frame,
        timestamp: new Date().toISOString()
      });
      
      throw error;
    }
  }

  /**
   * Handle incoming raw data from the device
   * @private
   */
  #handleRawData(data) {
    try {
      // Append new data to buffer
      this.buffer = Buffer.concat([this.buffer, data]);
      
      // Process complete messages (Meshtastic uses varint length prefix)
      while (this.buffer.length > 0) {
        // Try to read the length prefix (varint)
        const { length, bytesRead } = this.#readVarint(this.buffer);
        if (bytesRead === 0 || length === null) {
          // Not enough data to read length, wait for more
          break;
        }
        
        // Check if we have the complete message
        const totalLength = bytesRead + length;
        if (this.buffer.length < totalLength) {
          // Not enough data for complete message, wait for more
          break;
        }
        
        // Extract the complete message
        const messageBuffer = this.buffer.subarray(bytesRead, totalLength);
        
        // Remove processed data from buffer
        this.buffer = this.buffer.subarray(totalLength);
        
        // Decode the Meshtastic message
        const decoded = this.codec.decodeFromRadio(messageBuffer);
        
        // Emit as OCP frame
        this.emit("frame", decoded);
        
        this.emit("received", { 
          kind: this.kind, 
          bytes: messageBuffer.length,
          timestamp: new Date().toISOString()
        });
      }
      
    } catch (error) {
      this.emit("error", { 
        kind: this.kind, 
        endpoint: this.endpoint,
        error: `Failed to decode frame: ${error.message}`,
        timestamp: new Date().toISOString()
      });
    }
  }

  /**
   * Read varint length prefix from buffer
   * @private
   */
  #readVarint(buffer) {
    let value = 0;
    let shift = 0;
    let bytesRead = 0;
    
    for (let i = 0; i < buffer.length && i < 10; i++) {
      const byte = buffer[i];
      value |= (byte & 0x7F) << shift;
      bytesRead++;
      
      if ((byte & 0x80) === 0) {
        return { length: value, bytesRead };
      }
      
      shift += 7;
    }
    
    // Incomplete varint
    return { length: null, bytesRead: 0 };
  }

  /**
   * Request configuration from the device
   * @private
   */
  async #requestConfig() {
    const configRequest = {
      wantConfigId: this.endpoint.configId || "ocp-app"
    };
    
    try {
      await this.sendFrame(configRequest);
      console.log("📤 Sent config request to device");
    } catch (error) {
      console.error("Failed to send config request:", error.message);
    }
  }

  /**
   * Handle connection errors
   * @private
   */
  #handleConnectionError(error) {
    this.connected = false;
    this.emit("error", { 
      kind: this.kind, 
      endpoint: this.endpoint,
      error: error.message,
      timestamp: new Date().toISOString()
    });
    
    // Attempt reconnection if enabled
    if (this.options.reconnectInterval && this.retryCount < this.options.maxRetries) {
      this.retryCount++;
      this.#scheduleReconnect();
    }
  }

  /**
   * Schedule a reconnection attempt
   * @private
   */
  #scheduleReconnect() {
    if (this.reconnectTimer) return;
    
    console.log(`🔄 Scheduling reconnect in ${this.options.reconnectInterval}ms (attempt ${this.retryCount}/${this.options.maxRetries})`);
    
    this.reconnectTimer = setTimeout(async () => {
      try {
        await this.connect();
      } catch (error) {
        this.emit("reconnectFailed", {
          kind: this.kind,
          endpoint: this.endpoint,
          retryCount: this.retryCount,
          error: error.message,
          timestamp: new Date().toISOString()
        });
        
        // Schedule next retry if needed
        if (this.retryCount < this.options.maxRetries) {
          this.#scheduleReconnect();
        } else {
          this.emit("reconnectAborted", {
            kind: this.kind,
            endpoint: this.endpoint,
            maxRetries: this.options.maxRetries,
            timestamp: new Date().toISOString()
          });
        }
      }
    }, this.options.reconnectInterval);
  }
}