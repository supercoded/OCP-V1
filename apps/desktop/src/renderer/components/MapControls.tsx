import { ZoomIn, ZoomOut, Crosshair, Layers, FolderOpen, Radio, Eye } from "lucide-react";
import { AnalogButton } from "./AnalogButton";
import { AnalogToggle } from "./AnalogToggle";

export interface LayerVisibility {
  nodes: boolean;
  sensing: boolean;
  offlineTiles: boolean;
}

export interface MapControlsProps {
  /** Layer visibility toggles */
  layers: LayerVisibility;
  /** Called when a layer toggle changes */
  onLayerChange: (layers: LayerVisibility) => void;
  /** Called when user wants to load an MBTiles/PMTiles file */
  onLoadFile: () => void;
  /** Called when user wants to center on self (own node position) */
  onCenterSelf: () => void;
  /** Called when user wants to zoom in */
  onZoomIn: () => void;
  /** Called when user wants to zoom out */
  onZoomOut: () => void;
  /** Whether offline tile server is active */
  tileServerActive: boolean;
  /** Number of nodes currently on map */
  nodeCount: number;
  /** Number of sensing targets on map */
  sensingCount: number;
  /** Status text to display */
  status?: string;
}

export function MapControls({
  layers,
  onLayerChange,
  onLoadFile,
  onCenterSelf,
  onZoomIn,
  onZoomOut,
  tileServerActive,
  nodeCount,
  sensingCount,
  status,
}: MapControlsProps) {
  return (
    <div className="flex flex-col gap-3 w-56 shrink-0">
      {/* Map Source */}
      <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
        <div className="text-xs uppercase tracking-wider text-ocp-dim flex items-center gap-2">
          <FolderOpen className="w-3.5 h-3.5" />
          Map Source
        </div>
        <AnalogButton onClick={onLoadFile} variant={tileServerActive ? "accent" : "default"}>
          {tileServerActive ? "Offline Active" : "Load Tiles"}
        </AnalogButton>
        {tileServerActive && (
          <div className="flex items-center gap-1.5 text-[10px] text-ocp-bright font-mono">
            <span className="w-1.5 h-1.5 rounded-full bg-ocp-green animate-pulse" />
            Offline tiles loaded
          </div>
        )}
        <div className="text-[10px] text-ocp-dim">
          Load a PMTiles or MBTiles file from disk for offline map data.
        </div>
      </div>

      {/* Layer Controls */}
      <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
        <div className="text-xs uppercase tracking-wider text-ocp-dim flex items-center gap-2">
          <Layers className="w-3.5 h-3.5" />
          Layers
        </div>

        <AnalogToggle
          label={`Nodes (${nodeCount})`}
          checked={layers.nodes}
          onChange={(v) => onLayerChange({ ...layers, nodes: v })}
        />

        <AnalogToggle
          label={`RuView (${sensingCount})`}
          checked={layers.sensing}
          onChange={(v) => onLayerChange({ ...layers, sensing: v })}
        />

        <AnalogToggle
          label="Offline Tiles"
          checked={layers.offlineTiles}
          onChange={(v) => onLayerChange({ ...layers, offlineTiles: v })}
        />
      </div>

      {/* Navigation */}
      <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
        <div className="text-xs uppercase tracking-wider text-ocp-dim flex items-center gap-2">
          <Crosshair className="w-3.5 h-3.5" />
          Navigation
        </div>
        <div className="grid grid-cols-2 gap-2">
          <AnalogButton onClick={onZoomIn}>
            <ZoomIn className="w-4 h-4" />
          </AnalogButton>
          <AnalogButton onClick={onZoomOut}>
            <ZoomOut className="w-4 h-4" />
          </AnalogButton>
        </div>
        <AnalogButton onClick={onCenterSelf} variant="accent">
          <Crosshair className="w-3.5 h-3.5 inline mr-1" />
          Center Self
        </AnalogButton>
      </div>

      {/* Status */}
      {status && (
        <div className="p-2 rounded border border-ocp-border bg-ocp-panel">
          <div className="text-[10px] font-mono text-ocp-dim uppercase tracking-wider">
            {status}
          </div>
        </div>
      )}

      {/* Legend */}
      <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-2">
        <div className="text-xs uppercase tracking-wider text-ocp-dim flex items-center gap-2">
          <Eye className="w-3.5 h-3.5" />
          Legend
        </div>
        <div className="flex items-center gap-2 text-[10px] font-mono">
          <div className="w-3 h-3 bg-ocp-green rotate-45 shrink-0" style={{  }} />
          <span className="text-ocp-text">Meshtastic Node</span>
        </div>
        <div className="flex items-center gap-2 text-[10px] font-mono">
          <div className="w-3 h-3 bg-ocp-amber rounded-full shrink-0" style={{ boxShadow: "0 0 6px rgba(255,170,0,0.6)" }} />
          <span className="text-ocp-text">RuView Target</span>
        </div>
      </div>
    </div>
  );
}