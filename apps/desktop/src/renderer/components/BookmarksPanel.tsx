import { useState, useEffect, useCallback } from "react";
import { AnalogButton } from "./AnalogButton";
import { TextField } from "./TextField";

export interface Bookmark {
  id: string;
  label: string;
  frequency: number; // Hz
  bandwidth: number; // Hz
  modulation: string;
}

const STORAGE_KEY = "ocp:sdr:bookmarks";

function loadBookmarks(): Bookmark[] {
  try {
    const raw = localStorage.getItem(STORAGE_KEY);
    if (!raw) return [];
    return JSON.parse(raw);
  } catch {
    return [];
  }
}

function saveBookmarks(bookmarks: Bookmark[]) {
  localStorage.setItem(STORAGE_KEY, JSON.stringify(bookmarks));
}

function formatFreq(hz: number) {
  if (hz >= 1e9) return `${(hz / 1e9).toFixed(3)} GHz`;
  if (hz >= 1e6) return `${(hz / 1e6).toFixed(3)} MHz`;
  if (hz >= 1e3) return `${(hz / 1e3).toFixed(3)} kHz`;
  return `${hz} Hz`;
}

function generateId() {
  return Date.now().toString(36) + Math.random().toString(36).slice(2, 6);
}

export function BookmarksPanel({
  onTune,
  centerFreq,
}: {
  onTune: (freqHz: number) => void;
  centerFreq?: number;
}) {
  const [bookmarks, setBookmarks] = useState<Bookmark[]>(loadBookmarks);
  const [adding, setAdding] = useState(false);
  const [editingId, setEditingId] = useState<string | null>(null);
  const [label, setLabel] = useState("");
  const [freq, setFreq] = useState("");
  const [bw, setBw] = useState("15000");
  const [mod, setMod] = useState("FM");

  useEffect(() => {
    saveBookmarks(bookmarks);
  }, [bookmarks]);

  const startAdd = useCallback(() => {
    setLabel("");
    setFreq(centerFreq ? (centerFreq / 1e6).toFixed(3) : "100.000");
    setBw("15000");
    setMod("FM");
    setAdding(true);
    setEditingId(null);
  }, [centerFreq]);

  const startEdit = useCallback((bm: Bookmark) => {
    setLabel(bm.label);
    setFreq((bm.frequency / 1e6).toFixed(3));
    setBw(String(bm.bandwidth));
    setMod(bm.modulation);
    setEditingId(bm.id);
    setAdding(false);
  }, []);

  const saveNew = useCallback(() => {
    const freqHz = parseFloat(freq) * 1e6;
    if (isNaN(freqHz) || freqHz <= 0) return;
    const bm: Bookmark = {
      id: generateId(),
      label: label || formatFreq(freqHz),
      frequency: freqHz,
      bandwidth: parseInt(bw, 10) || 15000,
      modulation: mod,
    };
    setBookmarks((prev) => [...prev, bm]);
    setAdding(false);
  }, [label, freq, bw, mod]);

  const saveEdit = useCallback(() => {
    const freqHz = parseFloat(freq) * 1e6;
    if (isNaN(freqHz) || freqHz <= 0) return;
    setBookmarks((prev) =>
      prev.map((bm) =>
        bm.id === editingId
          ? {
              ...bm,
              label: label || formatFreq(freqHz),
              frequency: freqHz,
              bandwidth: parseInt(bw, 10) || 15000,
              modulation: mod,
            }
          : bm,
      ),
    );
    setEditingId(null);
  }, [editingId, label, freq, bw, mod]);

  const removeBookmark = useCallback((id: string) => {
    setBookmarks((prev) => prev.filter((bm) => bm.id !== id));
  }, []);

  return (
    <div className="p-3 rounded border border-ocp-border bg-ocp-panel space-y-2">
      <div className="text-xs uppercase tracking-wider text-ocp-dim">Bookmarks</div>

      {/* Bookmark list */}
      <div className="space-y-1 max-h-40 overflow-y-auto">
        {bookmarks.length === 0 && (
          <div className="text-[10px] text-ocp-dim italic">No bookmarks saved</div>
        )}
        {bookmarks.map((bm) => (
          <div
            key={bm.id}
            className="flex items-center gap-2 px-2 py-1 rounded hover:bg-ocp-panel-2 cursor-pointer group transition-colors"
            onClick={() => onTune(bm.frequency)}
          >
            <div className="flex-1 min-w-0">
              <div className="text-xs text-ocp-bright font-mono truncate">{bm.label}</div>
              <div className="text-[10px] text-ocp-dim font-mono">
                {formatFreq(bm.frequency)} · {bm.modulation} · {(bm.bandwidth / 1e3).toFixed(0)}k
              </div>
            </div>
            <button
              className="opacity-0 group-hover:opacity-100 text-ocp-dim hover:text-ocp-bright text-xs transition-opacity"
              onClick={(e) => { e.stopPropagation(); startEdit(bm); }}
              title="Edit"
            >
              ✎
            </button>
            <button
              className="opacity-0 group-hover:opacity-100 text-ocp-dim hover:text-red-400 text-xs transition-opacity"
              onClick={(e) => { e.stopPropagation(); removeBookmark(bm.id); }}
              title="Remove"
            >
              ✕
            </button>
          </div>
        ))}
      </div>

      {/* Add / Edit form */}
      {(adding || editingId) && (
        <div className="space-y-2 pt-2 border-t border-ocp-border">
          <TextField label="Label" value={label} onChange={setLabel} placeholder="e.g. NOAA Weather" />
          <TextField label="Freq (MHz)" value={freq} onChange={setFreq} placeholder="100.000" />
          <div className="flex gap-2">
            <div className="flex-1">
              <TextField label="BW (Hz)" value={bw} onChange={setBw} placeholder="15000" />
            </div>
            <div className="flex-1">
              <label className="text-[10px] uppercase tracking-wider text-ocp-dim">Mod</label>
              <select
                value={mod}
                onChange={(e) => setMod(e.target.value)}
                className="w-full px-2 py-1 rounded border border-ocp-border bg-ocp-bg text-ocp-text text-xs"
              >
                <option value="AM">AM</option>
                <option value="FM">FM</option>
                <option value="NFM">NFM</option>
                <option value="WFM">WFM</option>
                <option value="USB">USB</option>
                <option value="LSB">LSB</option>
                <option value="CW">CW</option>
              </select>
            </div>
          </div>
          <div className="grid grid-cols-2 gap-2">
            {editingId ? (
              <>
                <AnalogButton onClick={saveEdit}>Save</AnalogButton>
                <AnalogButton onClick={() => setEditingId(null)}>Cancel</AnalogButton>
              </>
            ) : (
              <>
                <AnalogButton onClick={saveNew}>Add</AnalogButton>
                <AnalogButton onClick={() => setAdding(false)}>Cancel</AnalogButton>
              </>
            )}
          </div>
        </div>
      )}

      {!adding && !editingId && (
        <AnalogButton onClick={startAdd}>+ Add Bookmark</AnalogButton>
      )}
    </div>
  );
}