import { useCallback, useEffect, useState } from "react";
import { SpectrumLocalPanel } from "../components/SpectrumLocalPanel";
import { OnlineReceiversPanel } from "../components/OnlineReceiversPanel";
import { useOcpService } from "../contexts/OcpServiceContext";

type SpectrumMode = "local" | "online";

export function SpectrumPage() {
  const service = useOcpService();
  const spectrumPrefs = service.preferences.pages.spectrum ?? {};
  const [mode, setMode] = useState<SpectrumMode>(
    spectrumPrefs.mode === "online" ? "online" : "local"
  );

  useEffect(() => {
    if (spectrumPrefs.mode === "online" || spectrumPrefs.mode === "local") {
      setMode(spectrumPrefs.mode);
    }
  }, [spectrumPrefs.mode]);

  const selectMode = useCallback((nextMode: SpectrumMode) => {
    setMode(nextMode);
    void service.updatePagePreferences("spectrum", { mode: nextMode });
    if (nextMode === "local") {
      void (window as any).ocp?.resizeOnlineSession?.({ x: 0, y: 0, width: 0, height: 0 });
    } else {
      setTimeout(() => window.dispatchEvent(new Event("ocp:online-sdr:restore-bounds")), 50);
    }
  }, [service]);

  return (
    <div className="absolute inset-0 p-4 flex flex-col gap-3">
      <div className="flex items-center justify-between shrink-0">
        <h2 className="text-lg font-semibold tracking-widest uppercase text-ocp-bright">
          Spectrum
        </h2>
        <div className="flex rounded border border-ocp-border overflow-hidden">
          <button
            type="button"
            className={[
              "px-4 py-1.5 text-xs uppercase tracking-wider font-semibold transition-colors",
              mode === "local"
                ? "bg-ocp-green/20 text-ocp-bright border-ocp-bright"
                : "text-ocp-dim hover:text-ocp-text",
            ].join(" ")}
            onClick={() => selectMode("local")}
          >
            Local RTL
          </button>
          <button
            type="button"
            className={[
              "px-4 py-1.5 text-xs uppercase tracking-wider font-semibold transition-colors border-l border-ocp-border",
              mode === "online"
                ? "bg-ocp-green/20 text-ocp-bright border-ocp-bright"
                : "text-ocp-dim hover:text-ocp-text",
            ].join(" ")}
            onClick={() => selectMode("online")}
          >
            Online Receivers
          </button>
        </div>
      </div>

      <div className="relative flex-1 min-h-0">
        <div className={mode === "local" ? "absolute inset-0 flex" : "hidden"}>
          <SpectrumLocalPanel />
        </div>
        <div className={mode === "online" ? "absolute inset-0 flex" : "hidden"}>
          <OnlineReceiversPanel />
        </div>
      </div>
    </div>
  );
}
