import { useState, useEffect, useRef, useCallback, useMemo } from "react";
import { useOcpService } from "../contexts/OcpServiceContext";
import { MapCanvas, type NodeMarker, type SensingTarget } from "../components/MapCanvas";
import { MapControls, type LayerVisibility } from "../components/MapControls";
import type maplibregl from "maplibre-gl";

export function MapPage() {
  const service = useOcpService();
  const mapRef = useRef<maplibregl.Map | null>(null);
  const [status, setStatus] = useState<string>("Ready");
  const [tileServerUrl, setTileServerUrl] = useState<string | undefined>(undefined);
  const [layers, setLayers] = useState<LayerVisibility>({
    nodes: true,
    sensing: true,
    offlineTiles: false,
  });

  // Convert nodes to map markers
  const nodeMarkers: NodeMarker[] = useMemo(() => {
    return service.state.nodes
      .filter((n: any) => typeof n.lat === "number" && typeof n.lon === "number" && !(n.lat === 0 && n.lon === 0))
      .map((n: any) => ({
        id: n.id,
        name: n.name,
        lat: n.lat,
        lon: n.lon,
        rssi: n.avgRssi,
        snr: n.avgSnr,
      }));
  }, [service.state.nodes]);

  // Convert RuView sensing targets to map markers
  // Note: RuView sensing provides x/y/z coordinates, not lat/lon.
  // For now we treat x=lon, y=lat as a simple projection if available,
  // or skip targets without position data.
  const sensingTargets: SensingTarget[] = useMemo(() => {
    return service.ruViewSensing
      .filter((s) => {
        // Only include targets that have meaningful position data
        // x/y are in local meters; for map display we'd need to convert.
        // For now, skip unless we can derive lat/lon.
        return typeof s.x === "number" && typeof s.y === "number";
      })
      .map((s, i) => {
        // Convert local x/y (meters from reference point) to approximate lat/lon
        // This is a simple equirectangular projection centered on own position
        // For a more accurate version, we'd need the reference point's GPS coords.
        const ownNode = service.state.nodes.find((n: any) => n.id === 0);
        const refLat = ownNode?.lat ?? 39.5;
        const refLon = ownNode?.lon ?? -98.5;
        // Approximate conversion: 1 degree ≈ 111,320 meters at equator
        const lat = refLat + (s.y / 111320);
        const lon = refLon + (s.x / (111320 * Math.cos((refLat * Math.PI) / 180)));
        return {
          id: `rv-${s.nodeId}-${i}`,
          nodeId: s.nodeId,
          lat,
          lon,
          rssi: s.rssi,
          timestamp: s.timestamp,
          source: s.source,
        };
      });
  }, [service.ruViewSensing, service.state.nodes]);

  // Handle file dialog for loading tiles
  const handleLoadFile = useCallback(async () => {
    try {
      setStatus("Opening file dialog...");
      const result = await service.openFileDialog({
        title: "Select Map Tiles File",
        filters: [
          { name: "Map Tiles", extensions: ["pmtiles", "mbtiles", "mvt"] },
          { name: "All Files", extensions: ["*"] },
        ],
        properties: ["openFile"],
      });

      if (!result.ok) {
        if (result.canceled) {
          setStatus("File selection canceled");
        } else {
          setStatus(`Error: ${result.error || "Unknown error"}`);
        }
        return;
      }

      const filePath = result.filePath!;
      setStatus(`Loading ${filePath.split("/").pop()}...`);

      const mapResult = await service.startMap(filePath);
      if (mapResult.ok && mapResult.port) {
        const url = `http://localhost:${mapResult.port}/style.json`;
        setTileServerUrl(url);
        setLayers((prev) => ({ ...prev, offlineTiles: true }));
        setStatus(`Offline tiles active on port ${mapResult.port}`);
      } else {
        setStatus(`Error: ${mapResult.error || "Failed to start tile server"}`);
      }
    } catch (e: any) {
      setStatus(`Exception: ${e.message}`);
    }
  }, [service]);

  // Handle stop tiles
  const handleStopTiles = useCallback(async () => {
    await service.stopMap();
    setTileServerUrl(undefined);
    setLayers((prev) => ({ ...prev, offlineTiles: false }));
    setStatus("Offline tiles stopped");
  }, [service]);

  // Determine tile server URL based on layer toggle
  const activeTileUrl = layers.offlineTiles ? tileServerUrl : undefined;

  // Handle center on self (own node)
  const handleCenterSelf = useCallback(() => {
    const map = mapRef.current;
    if (!map) return;

    // Find own node (typically node 0 or the first node with position)
    const ownNode = service.state.nodes.find((n: any) => typeof n.lat === "number" && typeof n.lon === "number");
    if (ownNode) {
      map.flyTo({
        center: [ownNode.lon, ownNode.lat],
        zoom: 14,
        duration: 1500,
      });
      setStatus(`Centered on ${ownNode.name || `Node ${ownNode.id}`}`);
    } else {
      // No node with position — center on US
      map.flyTo({
        center: [-98.5, 39.5],
        zoom: 4,
        duration: 1500,
      });
      setStatus("No node position — centered on default");
    }
  }, [service.state.nodes]);

  // Handle zoom
  const handleZoomIn = useCallback(() => {
    mapRef.current?.zoomIn({ duration: 300 });
  }, []);

  const handleZoomOut = useCallback(() => {
    mapRef.current?.zoomOut({ duration: 300 });
  }, []);

  // Handle map ready
  const handleMapReady = useCallback((map: maplibregl.Map) => {
    mapRef.current = map;
  }, []);

  // Update status from service state
  useEffect(() => {
    if (tileServerUrl) {
      setStatus(`Offline tiles active · ${service.state.nodeCount} nodes · ${service.ruViewSensing.length} targets`);
    } else if (service.state.connected) {
      setStatus(`Online · ${service.state.nodeCount} nodes · ${service.ruViewSensing.length} targets`);
    } else {
      setStatus("Ready — load tiles or connect for live data");
    }
  }, [tileServerUrl, service.state.connected, service.state.nodeCount, service.ruViewSensing.length]);

  return (
    <div className="absolute inset-0 flex flex-col">
      {/* Header bar */}
      <div className="flex items-center justify-between px-4 py-2 bg-ocp-panel border-b border-ocp-border shrink-0">
        <h2 className="text-lg font-semibold tracking-widest uppercase text-ocp-bright ">
          Map
        </h2>
        <div className="flex items-center gap-3 text-xs font-mono text-ocp-dim">
          <span className="inline-flex items-center gap-1.5">
            <span
              className={[
                "w-1.5 h-1.5 rounded-full",
                service.state.connected ? "bg-ocp-green animate-pulse" : "bg-ocp-text-dim",
              ].join(" ")}
            />
            {service.state.connected ? "Mesh linked" : "Mesh standby"}
          </span>
          <span>|</span>
          <span>
            {nodeMarkers.length} nodes · {sensingTargets.length} targets
          </span>
        </div>
      </div>

      {/* Main content: map + controls */}
      <div className="flex flex-1 min-h-0">
        {/* Map area */}
        <div className="flex-1 relative">
          <MapCanvas
            tileServerUrl={activeTileUrl}
            nodes={layers.nodes ? nodeMarkers : []}
            sensingTargets={layers.sensing ? sensingTargets : []}
            showNodes={layers.nodes}
            showSensing={layers.sensing}
            showOfflineTiles={layers.offlineTiles}
            onMapReady={handleMapReady}
            className="w-full h-full"
          />
          {/* Map overlay info */}
          <div className="absolute bottom-3 left-3 text-[10px] font-mono text-ocp-dim bg-ocp-bg/80 px-2 py-1 rounded">
            {status}
          </div>
        </div>

        {/* Controls sidebar */}
        <MapControls
          layers={layers}
          onLayerChange={setLayers}
          onLoadFile={tileServerUrl ? handleStopTiles : handleLoadFile}
          onCenterSelf={handleCenterSelf}
          onZoomIn={handleZoomIn}
          onZoomOut={handleZoomOut}
          tileServerActive={!!tileServerUrl}
          nodeCount={nodeMarkers.length}
          sensingCount={sensingTargets.length}
          status={undefined}
        />
      </div>
    </div>
  );
}