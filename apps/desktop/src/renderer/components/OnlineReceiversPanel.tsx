import { useCallback, useEffect, useMemo, useRef, useState } from "react";
import { useOcpService, type OnlineReceiver } from "../contexts/OcpServiceContext";
import { AnalogButton } from "./AnalogButton";
import { AnalogToggle } from "./AnalogToggle";
import { TextField } from "./TextField";
import { StatusLamp } from "./StatusLamp";

type ActiveSession = {
  receiverId: string;
  name: string;
  url: string;
};

function statusLamp(state: string): "active" | "off" | "on" | "error" {
  if (state === "online") return "active";
  if (state === "offline") return "off";
  return "on";
}

function typeLabel(type: string) {
  switch (type) {
    case "websdr": return "WebSDR";
    case "kiwisdr": return "KiwiSDR";
    case "openwebrx": return "OpenWebRX";
    case "directory": return "Directory";
    default: return type;
  }
}

export function OnlineReceiversPanel() {
  const service = useOcpService();
  const onlinePrefs = (service.preferences.pages.spectrum?.online ?? {}) as Record<string, any>;
  const [receivers, setReceivers] = useState<OnlineReceiver[]>([]);
  const [loading, setLoading] = useState(true);
  const [probing, setProbing] = useState(false);
  const [query, setQuery] = useState(onlinePrefs.query ?? "");
  const [typeFilter, setTypeFilter] = useState(onlinePrefs.typeFilter ?? "all");
  const [regionFilter, setRegionFilter] = useState(onlinePrefs.regionFilter ?? "all");
  const [favoritesOnly, setFavoritesOnly] = useState(!!onlinePrefs.favoritesOnly);
  const [error, setError] = useState<string | undefined>();
  const [activeSession, setActiveSession] = useState<ActiveSession | null>(null);
  const [restoredReceiverId, setRestoredReceiverId] = useState<string | undefined>(onlinePrefs.lastReceiverId);
  const [sessionError, setSessionError] = useState<string | undefined>();
  const embedRef = useRef<HTMLDivElement>(null);
  const viewVisibleRef = useRef(true);

  const saveOnlinePrefs = useCallback((patch: Record<string, any>) => {
    void service.updatePagePreferences("spectrum", {
      online: {
        ...((service.preferences.pages.spectrum?.online ?? {}) as Record<string, any>),
        ...patch,
      },
    });
  }, [service]);

  const loadReceivers = useCallback(async () => {
    setLoading(true);
    const result = await service.listOnlineReceivers();
    if (result.ok && result.receivers) {
      setReceivers(result.receivers);
      if (result.lastReceiverId) {
        setRestoredReceiverId(result.lastReceiverId);
        saveOnlinePrefs({ lastReceiverId: result.lastReceiverId });
      }
      setError(undefined);
    } else {
      setError(result.error ?? "Failed to load receivers");
    }
    setLoading(false);
  }, [service, saveOnlinePrefs]);

  useEffect(() => {
    void loadReceivers();
    // Load once on mount; preference updates should not re-open or reload sessions.
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  const regions = useMemo(() => {
    const set = new Set(receivers.map((r) => r.region).filter(Boolean));
    return ["all", ...Array.from(set).sort()];
  }, [receivers]);

  const filtered = useMemo(() => {
    const q = query.trim().toLowerCase();
    return receivers.filter((r) => {
      if (favoritesOnly && !r.favorite) return false;
      if (typeFilter !== "all" && r.type !== typeFilter) return false;
      if (regionFilter !== "all" && r.region !== regionFilter) return false;
      if (!q) return true;
      const hay = [r.name, r.location, r.region, r.notes, ...(r.bands || []), ...(r.capabilities || [])]
        .filter(Boolean)
        .join(" ")
        .toLowerCase();
      return hay.includes(q);
    });
  }, [receivers, query, typeFilter, regionFilter, favoritesOnly]);

  const reportBounds = useCallback(() => {
    const el = embedRef.current;
    if (!el || !activeSession) return;
    const locked = !!service.state.security?.pinConfigured && !service.state.security?.unlocked;
    if (locked || !viewVisibleRef.current) {
      void service.resizeOnlineSession({ x: 0, y: 0, width: 0, height: 0 });
      return;
    }
    const rect = el.getBoundingClientRect();
    void service.resizeOnlineSession({
      x: Math.round(rect.x),
      y: Math.round(rect.y),
      width: Math.round(rect.width),
      height: Math.round(rect.height),
    });
  }, [activeSession, service]);

  useEffect(() => {
    if (!activeSession) return;
    const el = embedRef.current;
    if (!el) return;
    const ro = new ResizeObserver(() => reportBounds());
    ro.observe(el);
    window.addEventListener("resize", reportBounds);
    const timer = setTimeout(reportBounds, 50);
    return () => {
      ro.disconnect();
      window.removeEventListener("resize", reportBounds);
      clearTimeout(timer);
    };
  }, [activeSession, reportBounds]);

  useEffect(() => {
    const restore = () => {
      viewVisibleRef.current = true;
      reportBounds();
    };
    const hide = () => {
      viewVisibleRef.current = false;
      void service.resizeOnlineSession({ x: 0, y: 0, width: 0, height: 0 });
    };
    window.addEventListener("ocp:online-sdr:restore-bounds", restore);
    window.addEventListener("ocp:online-sdr:hide-bounds", hide);
    return () => {
      window.removeEventListener("ocp:online-sdr:restore-bounds", restore);
      window.removeEventListener("ocp:online-sdr:hide-bounds", hide);
    };
  }, [reportBounds]);

  const probeAll = useCallback(async () => {
    setProbing(true);
    const result = await service.probeOnlineReceivers();
    if (result.ok && result.receivers) {
      setReceivers(result.receivers);
      setError(undefined);
    } else {
      setError(result.error ?? "Probe failed");
    }
    setProbing(false);
  }, [service]);

  const toggleFavorite = useCallback(async (id: string) => {
    const result = await service.toggleOnlineFavorite(id);
    if (result.ok && result.receivers) {
      setReceivers(result.receivers);
    }
  }, [service]);

  const openExternal = useCallback(async (url: string) => {
    await service.openOnlineExternal(url);
  }, [service]);

  const listen = useCallback(async (receiver: OnlineReceiver, mobile = false) => {
    setSessionError(undefined);
    if (receiver.type === "directory" || receiver.embeddable === false) {
      await openExternal(receiver.url);
      return;
    }
    const el = embedRef.current;
    if (!el) return;
    viewVisibleRef.current = true;
    const rect = el.getBoundingClientRect();
    const result = await service.openOnlineSession({
      receiverId: receiver.id,
      mobile,
      bounds: {
        x: Math.round(rect.x),
        y: Math.round(rect.y),
        width: Math.round(rect.width),
        height: Math.round(rect.height),
      },
    });
    if (result.ok && !result.external && result.url) {
      setActiveSession({
        receiverId: receiver.id,
        name: result.name ?? receiver.name,
        url: result.url,
      });
      setRestoredReceiverId(receiver.id);
      saveOnlinePrefs({ lastReceiverId: receiver.id });
    } else if (result.ok && result.external) {
      setActiveSession(null);
    } else {
      setSessionError(result.error ?? "Could not open session — try Open External");
      if (receiver.url) {
        await openExternal(receiver.url);
      }
    }
  }, [service, openExternal, saveOnlinePrefs]);

  const closeSession = useCallback(async () => {
    await service.closeOnlineSession();
    setActiveSession(null);
    setSessionError(undefined);
  }, [service]);

  const copyLink = useCallback(async () => {
    if (!activeSession?.url) return;
    try {
      await navigator.clipboard.writeText(activeSession.url);
    } catch {
      // ignore
    }
  }, [activeSession]);

  return (
    <div className="flex flex-col lg:flex-row gap-3 flex-1 min-h-0">
      <div className="w-full lg:w-96 flex flex-col gap-3 shrink-0 overflow-y-auto">
        <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-3">
          <div className="flex items-center justify-between">
            <div className="text-xs uppercase tracking-wider text-ocp-dim">Online Receivers</div>
            <AnalogButton onClick={probeAll} disabled={probing || loading}>
              {probing ? "Probing…" : "Refresh Status"}
            </AnalogButton>
          </div>
          <TextField label="Search" value={query} onChange={(value) => {
            setQuery(value);
            saveOnlinePrefs({ query: value });
          }} />
          <div className="grid grid-cols-2 gap-2">
            <select
              className="bg-ocp-bg border border-ocp-border rounded px-2 py-1 text-xs text-ocp-text"
              value={typeFilter}
              onChange={(e) => {
                setTypeFilter(e.target.value);
                saveOnlinePrefs({ typeFilter: e.target.value });
              }}
            >
              <option value="all">All types</option>
              <option value="websdr">WebSDR</option>
              <option value="kiwisdr">KiwiSDR</option>
              <option value="openwebrx">OpenWebRX</option>
              <option value="directory">Directories</option>
            </select>
            <select
              className="bg-ocp-bg border border-ocp-border rounded px-2 py-1 text-xs text-ocp-text"
              value={regionFilter}
              onChange={(e) => {
                setRegionFilter(e.target.value);
                saveOnlinePrefs({ regionFilter: e.target.value });
              }}
            >
              {regions.map((r) => (
                <option key={r} value={r}>{r === "all" ? "All regions" : r}</option>
              ))}
            </select>
          </div>
          <AnalogToggle label="Favorites only" checked={favoritesOnly} onChange={(value) => {
            setFavoritesOnly(value);
            saveOnlinePrefs({ favoritesOnly: value });
          }} />
          <div className="text-[10px] text-ocp-dim">
            Curated public SDR sites. Directories open in your browser; receivers embed in OCP when possible.
          </div>
        </div>

        {error && (
          <div className="p-2 rounded border border-red-900/50 bg-red-900/20 text-xs text-red-300 font-mono">
            {error}
          </div>
        )}

        <div className="flex flex-col gap-2">
          {loading && (
            <div className="text-xs text-ocp-dim p-3">Loading catalog…</div>
          )}
          {!loading && filtered.length === 0 && (
            <div className="text-xs text-ocp-dim p-3">No receivers match your filters.</div>
          )}
          {filtered.map((r) => (
            <div key={r.id} className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-2">
              <div className="flex items-start justify-between gap-2">
                <div className="min-w-0">
                  <div className="text-sm font-semibold text-ocp-bright truncate">{r.name}</div>
                  <div className="text-[10px] text-ocp-dim">{r.location}</div>
                </div>
                <div className="flex items-center gap-2 shrink-0">
                  <StatusLamp state={statusLamp(r.status ?? "unknown")} label={r.status ?? "unknown"} />
                  <button
                    type="button"
                    className={`text-lg leading-none ${r.favorite ? "text-yellow-400" : "text-ocp-dim hover:text-yellow-400"}`}
                    title={r.favorite ? "Remove favorite" : "Add favorite"}
                    onClick={() => toggleFavorite(r.id)}
                  >
                    {r.favorite ? "★" : "☆"}
                  </button>
                </div>
              </div>

              <div className="flex flex-wrap gap-1">
                <span className="px-1.5 py-0.5 rounded text-[10px] border border-ocp-border text-ocp-dim">
                  {typeLabel(r.type)}
                </span>
                {r.bands?.slice(0, 4).map((b) => (
                  <span key={b} className="px-1.5 py-0.5 rounded text-[10px] bg-ocp-bg border border-ocp-border text-ocp-dim">
                    {b}
                  </span>
                ))}
              </div>

              {r.notes && (
                <div className="text-[10px] text-ocp-dim line-clamp-2">{r.notes}</div>
              )}

              <div className="flex flex-wrap gap-2 pt-1">
                {r.type !== "directory" && r.embeddable !== false ? (
                  <>
                    <AnalogButton onClick={() => listen(r)} disabled={r.status === "offline"}>
                      Listen in OCP
                    </AnalogButton>
                    {r.mobileUrl && (
                      <AnalogButton onClick={() => listen(r, true)} disabled={r.status === "offline"}>
                        Mobile UI
                      </AnalogButton>
                    )}
                  </>
                ) : null}
                <AnalogButton onClick={() => openExternal(r.url)}>Open External</AnalogButton>
              </div>
            </div>
          ))}
        </div>
      </div>

      <div className="flex-1 flex flex-col gap-2 min-h-0 min-w-0">
        <div className="flex items-center justify-between gap-2 shrink-0">
          <div className="text-xs uppercase tracking-wider text-ocp-dim">
            {activeSession ? `Listening — ${activeSession.name}` : "Embedded Session"}
          </div>
          {activeSession && (
            <div className="flex flex-wrap gap-2">
              <AnalogButton onClick={() => toggleFavorite(activeSession.receiverId)}>
                Favorite
              </AnalogButton>
              <AnalogButton onClick={copyLink}>Copy Link</AnalogButton>
              <AnalogButton onClick={() => openExternal(activeSession.url)}>Open External</AnalogButton>
              <AnalogButton onClick={closeSession} variant="danger">Close</AnalogButton>
            </div>
          )}
        </div>

        {sessionError && (
          <div className="p-2 rounded border border-amber-900/50 bg-amber-900/20 text-xs text-amber-200 font-mono shrink-0">
            {sessionError}
          </div>
        )}

        <div
          ref={embedRef}
          className="flex-1 relative rounded border border-ocp-border bg-ocp-panel overflow-hidden min-h-[320px]"
        >
          {!activeSession && (
            <div className="absolute inset-0 flex items-center justify-center p-6 text-center">
              <div className="max-w-md space-y-2">
                <div className="text-sm text-ocp-bright">
                  {restoredReceiverId ? "Resume last receiver" : "Select a receiver to listen"}
                </div>
                <div className="text-xs text-ocp-dim">
                  {restoredReceiverId
                    ? "OCP remembers your last online receiver, but will not start audio until you resume."
                    : "WebSDR and Kiwi stations load here with OCP chrome. Use Refresh Status to check reachability before tuning in."}
                </div>
                {restoredReceiverId && (() => {
                  const receiver = receivers.find((r) => r.id === restoredReceiverId);
                  if (!receiver) return null;
                  return (
                    <div className="flex justify-center gap-2 pt-2">
                      <AnalogButton onClick={() => listen(receiver)}>
                        Resume {receiver.name}
                      </AnalogButton>
                      <AnalogButton onClick={() => openExternal(receiver.url)}>
                        Open External
                      </AnalogButton>
                    </div>
                  );
                })()}
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}
