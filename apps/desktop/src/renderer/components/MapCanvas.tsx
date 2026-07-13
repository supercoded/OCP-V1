import { useEffect, useRef, useCallback } from "react";
import maplibregl from "maplibre-gl";
import "maplibre-gl/dist/maplibre-gl.css";

export interface NodeMarker {
  id: number;
  name?: string;
  lat: number;
  lon: number;
  rssi?: number | null;
  snr?: number | null;
}

export interface SensingTarget {
  id: string;
  nodeId: number;
  lat: number;
  lon: number;
  rssi?: number | null;
  timestamp: number;
  source: string;
}

export interface MapCanvasProps {
  /** Offline tile server URL (from PmtilesServer), e.g. http://localhost:PORT/style.json */
  tileServerUrl?: string;
  /** Meshtastic nodes with lat/lon to show on map */
  nodes: NodeMarker[];
  /** RuView sensing targets to show on map */
  sensingTargets: SensingTarget[];
  /** Layer visibility */
  showNodes: boolean;
  showSensing: boolean;
  showOfflineTiles: boolean;
  /** Map style URL when not using offline tiles */
  onlineStyleUrl?: string;
  /** Callback when map is ready */
  onMapReady?: (map: maplibregl.Map) => void;
  /** className for the container */
  className?: string;
}

// Dark submarine style as fallback when no offline tiles
const DEFAULT_DARK_STYLE: maplibregl.StyleSpecification = {
  version: 8,
  name: "OCP Dark",
  sources: {
    carto_dark: {
      type: "raster",
      tiles: [
        "https://a.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png",
        "https://b.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png",
        "https://c.basemaps.cartocdn.com/dark_all/{z}/{x}/{y}@2x.png",
      ],
      tileSize: 256,
      attribution: "&copy; OpenStreetMap &copy; CARTO",
      maxzoom: 19,
    },
  },
  layers: [
    {
      id: "carto-dark-bg",
      type: "raster",
      source: "carto_dark",
      minzoom: 0,
      maxzoom: 19,
    },
  ],
};

function createNodeMarkerElement(node: NodeMarker): HTMLDivElement {
  const el = document.createElement("div");
  el.className = "ocp-node-marker";
  el.style.cssText = `
    display: flex;
    flex-direction: column;
    align-items: center;
    pointer-events: auto;
    cursor: pointer;
  `;

  // Diamond shape marker
  const marker = document.createElement("div");
  marker.style.cssText = `
    width: 14px;
    height: 14px;
    background: #4caf50;
    border: 2px solid #0a1f1c;
    transform: rotate(45deg);
    box-shadow: 0 0 10px rgba(0, 240, 160, 0.6), 0 0 20px rgba(0, 240, 160, 0.3);
  `;
  el.appendChild(marker);

  // Label
  const label = document.createElement("div");
  label.style.cssText = `
    margin-top: 2px;
    padding: 1px 4px;
    background: rgba(13, 22, 29, 0.85);
    border: 1px solid #333333;
    border-radius: 2px;
    color: #4caf50;
    font-size: 10px;
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    white-space: nowrap;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    pointer-events: none;
  `;
  label.textContent = node.name || `Node ${node.id}`;
  el.appendChild(label);

  return el;
}

function createSensingMarkerElement(target: SensingTarget): HTMLDivElement {
  const el = document.createElement("div");
  el.className = "ocp-sensing-marker";
  el.style.cssText = `
    display: flex;
    flex-direction: column;
    align-items: center;
    pointer-events: auto;
    cursor: pointer;
  `;

  // Pulsing circle marker
  const marker = document.createElement("div");
  marker.style.cssText = `
    width: 12px;
    height: 12px;
    background: #ffaa00;
    border: 2px solid rgba(255, 170, 0, 0.4);
    border-radius: 50%;
    box-shadow: 0 0 10px rgba(255, 170, 0, 0.6), 0 0 20px rgba(255, 170, 0, 0.3);
    animation: ocp-sensing-pulse 1.5s ease-in-out infinite;
  `;
  el.appendChild(marker);

  // Label
  const label = document.createElement("div");
  label.style.cssText = `
    margin-top: 2px;
    padding: 1px 4px;
    background: rgba(13, 22, 29, 0.85);
    border: 1px solid #333333;
    border-radius: 2px;
    color: #ffaa00;
    font-size: 10px;
    font-family: ui-monospace, SFMono-Regular, Menlo, monospace;
    white-space: nowrap;
    text-transform: uppercase;
    letter-spacing: 0.5px;
    pointer-events: none;
  `;
  label.textContent = `RV-${target.nodeId}`;
  el.appendChild(label);

  return el;
}

export function MapCanvas({
  tileServerUrl,
  nodes,
  sensingTargets,
  showNodes,
  showSensing,
  showOfflineTiles,
  onlineStyleUrl,
  onMapReady,
  className = "",
}: MapCanvasProps) {
  const containerRef = useRef<HTMLDivElement>(null);
  const mapRef = useRef<maplibregl.Map | null>(null);
  const nodeMarkersRef = useRef<maplibregl.Marker[]>([]);
  const sensingMarkersRef = useRef<maplibregl.Marker[]>([]);

  // Determine which style to use
  const getMapStyle = useCallback((): maplibregl.StyleSpecification | string => {
    if (showOfflineTiles && tileServerUrl) {
      return tileServerUrl;
    }
    if (onlineStyleUrl) {
      return onlineStyleUrl;
    }
    return DEFAULT_DARK_STYLE;
  }, [showOfflineTiles, tileServerUrl, onlineStyleUrl]);

  // Initialize map
  useEffect(() => {
    if (!containerRef.current) return;

    const map = new maplibregl.Map({
      container: containerRef.current,
      style: getMapStyle(),
      center: [-98.5, 39.5], // Center of US as default
      zoom: 4,
      attributionControl: false,
      maxZoom: 18,
      minZoom: 1,
    });

    map.addControl(new maplibregl.NavigationControl({ showCompass: true }), "top-right");
    map.addControl(new maplibregl.ScaleControl({ maxWidth: 120 }), "bottom-left");

    map.on("load", () => {
      onMapReady?.(map);
    });

    mapRef.current = map;

    return () => {
      // Clean up markers
      nodeMarkersRef.current.forEach((m) => m.remove());
      sensingMarkersRef.current.forEach((m) => m.remove());
      nodeMarkersRef.current = [];
      sensingMarkersRef.current = [];
      map.remove();
      mapRef.current = null;
    };
    // Only re-create map when style source changes
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [showOfflineTiles && tileServerUrl, onlineStyleUrl]);

  // Update node markers
  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;

    // Remove existing markers
    nodeMarkersRef.current.forEach((m) => m.remove());
    nodeMarkersRef.current = [];

    if (!showNodes) return;

    // Add new markers
    for (const node of nodes) {
      if (typeof node.lat !== "number" || typeof node.lon !== "number") continue;
      if (node.lat === 0 && node.lon === 0) continue; // Skip null island

      const el = createNodeMarkerElement(node);
      const marker = new maplibregl.Marker({ element: el })
        .setLngLat([node.lon, node.lat])
        .addTo(map);

      const popup = new maplibregl.Popup({
        offset: 12,
        className: "ocp-popup",
        closeButton: false,
      }).setHTML(`
        <div style="font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 11px; color: #c8c8c8; background: #1a1a1a; padding: 4px 8px;">
          <div style="color: #4caf50; font-weight: bold; text-transform: uppercase; letter-spacing: 1px;">${node.name || `Node ${node.id}`}</div>
          <div style="margin-top: 4px; color: #888888;">ID: ${node.id}</div>
          ${node.rssi != null ? `<div>RSSI: ${node.rssi.toFixed(1)} dBm</div>` : ""}
          ${node.snr != null ? `<div>SNR: ${node.snr.toFixed(1)} dB</div>` : ""}
          <div>${node.lat.toFixed(4)}, ${node.lon.toFixed(4)}</div>
        </div>
      `);
      marker.setPopup(popup);

      nodeMarkersRef.current.push(marker);
    }
  }, [nodes, showNodes]);

  // Update sensing markers
  useEffect(() => {
    const map = mapRef.current;
    if (!map) return;

    // Remove existing markers
    sensingMarkersRef.current.forEach((m) => m.remove());
    sensingMarkersRef.current = [];

    if (!showSensing) return;

    // Add new markers
    for (const target of sensingTargets) {
      if (typeof target.lat !== "number" || typeof target.lon !== "number") continue;
      if (target.lat === 0 && target.lon === 0) continue;

      const el = createSensingMarkerElement(target);
      const marker = new maplibregl.Marker({ element: el })
        .setLngLat([target.lon, target.lat])
        .addTo(map);

      const popup = new maplibregl.Popup({
        offset: 12,
        className: "ocp-popup",
        closeButton: false,
      }).setHTML(`
        <div style="font-family: ui-monospace, SFMono-Regular, Menlo, monospace; font-size: 11px; color: #c8c8c8; background: #1a1a1a; padding: 4px 8px;">
          <div style="color: #ffaa00; font-weight: bold; text-transform: uppercase; letter-spacing: 1px;">RuView ${target.nodeId}</div>
          <div style="margin-top: 4px; color: #888888;">Source: ${target.source}</div>
          ${target.rssi != null ? `<div>RSSI: ${target.rssi.toFixed(1)} dBm</div>` : ""}
          <div>${target.lat.toFixed(4)}, ${target.lon.toFixed(4)}</div>
        </div>
      `);
      marker.setPopup(popup);

      sensingMarkersRef.current.push(marker);
    }
  }, [sensingTargets, showSensing]);

  // Expose map ref for imperative controls
  useEffect(() => {
    // Store ref for parent access via callback
    if (mapRef.current) {
      onMapReady?.(mapRef.current);
    }
  }, [onMapReady]);

  return (
    <div className={`relative ${className}`}>
      <div ref={containerRef} className="absolute inset-0" />
      {/* Inject pulse animation keyframes */}
      <style>{`
        @keyframes ocp-sensing-pulse {
          0%, 100% { opacity: 1; transform: scale(1); }
          50% { opacity: 0.7; transform: scale(1.3); }
        }
        .maplibregl-popup-content {
          background: #1a1a1a !important;
          border: 1px solid #333333 !important;
          border-radius: 4px !important;
          box-shadow: 0 0 20px rgba(0, 240, 160, 0.15) !important;
          padding: 0 !important;
        }
        .maplibregl-popup-tip {
          border-top-color: #333333 !important;
        }
        .maplibregl-popup-close-button {
          color: #c8c8c8 !important;
        }
        .maplibregl-ctrl-group {
          background: #1a1a1a !important;
          border: 1px solid #333333 !important;
        }
        .maplibregl-ctrl-group button {
          border-color: #333333 !important;
        }
        .maplibregl-ctrl-group button span {
          filter: invert(0.85) sepia(0.2) hue-rotate(120deg) !important;
        }
        .maplibregl-ctrl-group button:hover {
          background: #222222 !important;
        }
        .maplibregl-ctrl-scale {
          background: rgba(13, 22, 29, 0.85) !important;
          border-color: #333333 !important;
          color: #888888 !important;
          font-family: ui-monospace, SFMono-Regular, Menlo, monospace !important;
          font-size: 10px !important;
        }
      `}</style>
    </div>
  );
}

/**
 * Get the MapLibre GL Map instance from a MapCanvas ref.
 * Usage: const map = getMapFromRef(mapCanvasRef);
 */
export function getMapFromRef(mapRef: React.RefObject<{ getMap(): maplibregl.Map } | null>): maplibregl.Map | null {
  if (mapRef.current && typeof mapRef.current.getMap === "function") {
    return mapRef.current.getMap();
  }
  return null;
}