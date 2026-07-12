import { useCallback, useRef, useEffect } from "react";

export function useAudioEngine(enabled: boolean) {
  const ctxRef = useRef<AudioContext | null>(null);

  useEffect(() => {
    if (enabled && !ctxRef.current) {
      const AudioCtx = (window as any).AudioContext || (window as any).webkitAudioContext;
      if (AudioCtx) {
        ctxRef.current = new AudioCtx();
      }
    }
    return () => {
      ctxRef.current?.close();
      ctxRef.current = null;
    };
  }, [enabled]);

  const ping = useCallback((frequency = 900, duration = 0.08, type: OscillatorType = "sine") => {
    if (!enabled || !ctxRef.current) return;
    const ctx = ctxRef.current;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = type;
    osc.frequency.setValueAtTime(frequency, ctx.currentTime);
    gain.gain.setValueAtTime(0.08, ctx.currentTime);
    gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + duration);
    osc.connect(gain);
    gain.connect(ctx.destination);
    osc.start();
    osc.stop(ctx.currentTime + duration);
  }, [enabled]);

  const click = useCallback(() => {
    if (!enabled || !ctxRef.current) return;
    ping(220, 0.04, "square");
  }, [enabled, ping]);

  return { ping, click };
}
