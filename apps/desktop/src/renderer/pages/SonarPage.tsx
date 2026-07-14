import { useEffect, useMemo, useState, useCallback } from "react";

import { SonarPPI, type Blip } from "../components/SonarPPI";

import { SweepControls } from "../components/SweepControls";

import { SignalLegend } from "../components/SignalLegend";

import { useAudioEngine } from "../hooks/useAudioEngine";

import { useOcpService } from "../contexts/OcpServiceContext";



function rssiToDistanceRatio(rssi: number): number {

  const clamped = Math.max(-90, Math.min(-30, rssi));

  return 0.1 + (0.9 * (-30 - clamped)) / 60;

}



function snrToDistanceRatio(snr: number): number {

  const clamped = Math.max(0, Math.min(15, snr));

  return 0.1 + (0.9 * (15 - clamped)) / 15;

}



/** Great-circle distance in meters between two WGS84 points. */

function haversineMeters(lat1: number, lon1: number, lat2: number, lon2: number): number {

  const R = 6371000;

  const toRad = (d: number) => (d * Math.PI) / 180;

  const dLat = toRad(lat2 - lat1);

  const dLon = toRad(lon2 - lon1);

  const a =

    Math.sin(dLat / 2) ** 2 +

    Math.cos(toRad(lat1)) * Math.cos(toRad(lat2)) * Math.sin(dLon / 2) ** 2;

  return 2 * R * Math.asin(Math.min(1, Math.sqrt(a)));

}



/** Initial bearing from point 1 to point 2, degrees clockwise from north [0, 360). */

function bearingDeg(lat1: number, lon1: number, lat2: number, lon2: number): number {

  const toRad = (d: number) => (d * Math.PI) / 180;

  const φ1 = toRad(lat1);

  const φ2 = toRad(lat2);

  const Δλ = toRad(lon2 - lon1);

  const y = Math.sin(Δλ) * Math.cos(φ2);

  const x = Math.cos(φ1) * Math.sin(φ2) - Math.sin(φ1) * Math.cos(φ2) * Math.cos(Δλ);

  return ((Math.atan2(y, x) * 180) / Math.PI + 360) % 360;

}



export function SonarPage() {

  const service = useOcpService();

  const [sweepRpm, setSweepRpm] = useState(12);

  const [maxRangeMeters, setMaxRangeMeters] = useState(100);

  const [audioEnabled, setAudioEnabled] = useState(false);

  const [mockBlips, setMockBlips] = useState(true);

  const [filters, setFilters] = useState<Record<Blip["type"], boolean>>({

    meshtastic: true,

    ruview: true,

    sdr: true,

    baofeng: true,

    wifi: true,

    mock: true,

  });



  const { ping } = useAudioEngine(audioEnabled);



  const ownPosition = useMemo(() => {

    const localId = service.state.localNodeId;

    if (localId == null) return null;

    const self = service.state.nodes.find((n: any) => n.id === localId);

    if (self && typeof self.lat === "number" && typeof self.lon === "number") {

      return { lat: self.lat as number, lon: self.lon as number };

    }

    return null;

  }, [service.state.localNodeId, service.state.nodes]);



  // Real Meshtastic blips — GPS bearing/range when own + peer positions exist

  const meshtasticBlips: Blip[] = useMemo(() => {

    return service.state.nodes

      .filter((n: any) => service.state.localNodeId == null || n.id !== service.state.localNodeId)

      .map((n: any) => {

        const hasPeerGps = typeof n.lat === "number" && typeof n.lon === "number";

        let angle: number;

        let distRatio: number;



        if (ownPosition && hasPeerGps) {

          angle = bearingDeg(ownPosition.lat, ownPosition.lon, n.lat, n.lon);

          const meters = haversineMeters(ownPosition.lat, ownPosition.lon, n.lat, n.lon);

          distRatio = Math.min(1, Math.max(0.05, meters / maxRangeMeters));

        } else {

          angle = (n.id * 137) % 360;

          distRatio =

            n.avgRssi != null

              ? Math.min(1, Math.max(0.05, rssiToDistanceRatio(n.avgRssi)))

              : n.avgSnr != null

                ? Math.min(1, Math.max(0.05, snrToDistanceRatio(n.avgSnr)))

                : 0.5;

        }



        return {

          id: `mesh-${n.id}`,

          angleDeg: angle,

          distanceRatio: distRatio,

          strength: n.avgSnr != null ? Math.min(1, Math.max(0.2, n.avgSnr / 15)) : 0.5,

          label: n.name || `Node ${n.id}`,

          type: "meshtastic" as const,

          lastHitAt: performance.now(),

        };

      });

  }, [service.state.nodes, service.state.localNodeId, ownPosition, maxRangeMeters]);



  // Real RuView presence blips from CSI sensing events

  const ruviewBlips: Blip[] = useMemo(() => {

    return service.ruViewSensing.map((s) => {

      const angle = ((Math.atan2(s.y, s.x) * 180) / Math.PI + 360) % 360;

      const distMeters = Math.sqrt(s.x * s.x + s.y * s.y);

      return {

        id: `ruview-${s.nodeId}`,

        angleDeg: angle,

        distanceRatio: Math.min(1, Math.max(0.05, distMeters / maxRangeMeters)),

        strength: s.rssi != null ? Math.min(1, Math.max(0.2, (s.rssi + 90) / 60)) : 0.6,

        label: `RuView ${s.nodeId}`,

        type: "ruview" as const,

        lastHitAt: performance.now(),

      };

    });

  }, [service.ruViewSensing, maxRangeMeters]);



  // Mock blips for demo

  const [mockBlipState, setMockBlipState] = useState<Blip[]>([

    { id: "m1", angleDeg: 45, distanceRatio: 0.35, strength: 0.8, label: "RAK-4631", type: "mock", lastHitAt: performance.now() },

    { id: "m2", angleDeg: 210, distanceRatio: 0.62, strength: 0.6, label: "T-Beam", type: "mock", lastHitAt: performance.now() },

    { id: "m3", angleDeg: 120, distanceRatio: 0.48, strength: 0.7, label: "Presence", type: "mock", lastHitAt: performance.now() },

  ]);



  useEffect(() => {

    if (!mockBlips) return;

    const id = setInterval(() => {

      setMockBlipState((prev) =>

        prev.map((b) =>

          Math.random() > 0.7

            ? { ...b, lastHitAt: performance.now(), strength: 0.5 + Math.random() * 0.5 }

            : b

        )

      );

    }, 800);

    return () => clearInterval(id);

  }, [mockBlips]);



  const allBlips = useMemo(() => {

    const list: Blip[] = [];

    if (mockBlips) list.push(...mockBlipState);

    list.push(...meshtasticBlips);

    list.push(...ruviewBlips);

    return list;

  }, [mockBlips, mockBlipState, meshtasticBlips, ruviewBlips]);



  const visibleBlips = useMemo(

    () => allBlips.filter((b) => filters[b.type]),

    [allBlips, filters]

  );



  const onToggleFilter = useCallback((key: string) => {

    setFilters((f) => ({ ...f, [key as Blip["type"]]: !f[key as Blip["type"]] }));

  }, []);



  return (

    <div className="absolute inset-0 flex flex-col bg-ocp-bg">

      <div className="flex flex-1 min-h-0">

        <div className="flex-1 flex items-center justify-center bg-ocp-bg relative overflow-hidden">

          <SonarPPI

            blips={visibleBlips}

            sweepRpm={sweepRpm}

            audioEnabled={audioEnabled}

            maxRangeMeters={maxRangeMeters}

            onSweepCycle={() => ping()}

          />

          <div className="absolute top-4 left-4 text-[10px] font-mono text-ocp-dim uppercase tracking-widest pointer-events-none">

            Plan Position Indicator

          </div>

          <div className="absolute bottom-4 left-4 text-[10px] font-mono text-ocp-dim pointer-events-none">

            Nodes: {service.state.nodeCount} · RuView: {service.ruViewSensing.length}

            {ownPosition ? " · GPS fix" : ""}

          </div>

        </div>

        <SweepControls

          sweepRpm={sweepRpm}

          onSweepRpmChange={setSweepRpm}

          maxRangeMeters={maxRangeMeters}

          onMaxRangeChange={setMaxRangeMeters}

          audioEnabled={audioEnabled}

          onAudioEnabledChange={setAudioEnabled}

          mockBlips={mockBlips}

          onMockBlipsChange={setMockBlips}

        />

      </div>

      <SignalLegend filters={filters} onToggle={onToggleFilter} />

    </div>

  );

}


