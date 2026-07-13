import { useState, useRef, useEffect, useCallback } from "react";
import { AnalogButton } from "../components/AnalogButton";
import { StatusLamp } from "../components/StatusLamp";
import { useOcpService } from "../contexts/OcpServiceContext";

interface Message {
  id: number;
  text: string;
  from: string | number;
  to: string | number;
  channel: number;
  timestamp: number;
  outgoing: boolean;
}

/** Channels available in Meshtastic (0–7). */
const CHANNELS = Array.from({ length: 8 }, (_, i) => ({
  id: i,
  name: i === 0 ? "LongFast" : i === 1 ? "Tactical" : `Channel ${i}`,
}));

function formatTime(ts: number): string {
  const d = new Date(ts);
  return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
}

/** Resolve a node id to a human-friendly label. */
function nodeLabel(id: string | number, nodes: any[]): string {
  if (id === "you" || id === 0 || id === "0") return "You";
  const node = nodes.find((n) => n.id === id || n.id === Number(id));
  if (node?.name) return node.name;
  if (typeof id === "number") return `!${id.toString(16)}`;
  return String(id);
}

export function MessagingPage() {
  const { state, messages, sendMessage, sendError } = useOcpService();
  const [activeChannel, setActiveChannel] = useState<number>(0);
  const [draft, setDraft] = useState("");
  const [destNode, setDestNode] = useState<string>(""); // empty = broadcast
  const [localError, setLocalError] = useState<string | undefined>(undefined);
  const bottomRef = useRef<HTMLDivElement>(null);

  const connected = state.connected;
  const transportKind = state.transportKind;

  // Filter messages for the active channel
  const thread: Message[] = (messages as Message[]).filter(
    (m) => m.channel === activeChannel
  );

  // Auto-scroll to bottom on new messages
  useEffect(() => {
    bottomRef.current?.scrollIntoView({ behavior: "smooth" });
  }, [thread.length]);

  // Clear local error after a timeout
  useEffect(() => {
    if (!localError) return;
    const timer = setTimeout(() => setLocalError(undefined), 5000);
    return () => clearTimeout(timer);
  }, [localError]);

  const handleSend = useCallback(async () => {
    const text = draft.trim();
    if (!text) return;
    if (!connected) {
      setLocalError("No device connected");
      return;
    }

    const dest = destNode.trim();
    const result = await sendMessage({
      text,
      channel: activeChannel,
      destinationNodeId: dest ? Number(dest) : undefined,
    });

    if (result.ok) {
      setDraft("");
      setLocalError(undefined);
    } else {
      setLocalError(result.error || "Send failed");
    }
  }, [draft, activeChannel, destNode, connected, sendMessage]);

  const handleKeyDown = useCallback(
    (e: React.KeyboardEvent) => {
      if (e.key === "Enter" && !e.shiftKey) {
        e.preventDefault();
        handleSend();
      }
    },
    [handleSend]
  );

  return (
    <div className="absolute inset-0 flex">
      {/* Channel sidebar */}
      <div className="w-56 border-r border-ocp-border bg-ocp-panel flex flex-col">
        <div className="h-12 border-b border-ocp-border flex items-center px-4">
          <span className="text-xs uppercase tracking-wider text-ocp-accent font-semibold">
            Channels
          </span>
        </div>
        <div className="flex-1 overflow-auto">
          {CHANNELS.map((ch) => {
            const unread = (messages as Message[]).filter(
              (m) => m.channel === ch.id && !m.outgoing
            ).length;
            const lastMsg = (messages as Message[])
              .filter((m) => m.channel === ch.id)
              .slice(-1)[0];
            return (
              <button
                key={ch.id}
                onClick={() => setActiveChannel(ch.id)}
                className={[
                  "w-full text-left px-4 py-3 border-b border-ocp-border transition-colors",
                  activeChannel === ch.id
                    ? "bg-ocp-panel-2 border-l-2 border-l-ocp-accent"
                    : "hover:bg-ocp-panel-2/50",
                ].join(" ")}
              >
                <div className="flex items-center justify-between">
                  <span className="text-sm font-medium text-ocp-text">
                    {ch.name}
                  </span>
                  {unread > 0 && (
                    <span className="px-1.5 py-0.5 rounded text-[10px] bg-ocp-accent text-ocp-bg font-bold">
                      {unread}
                    </span>
                  )}
                </div>
                {lastMsg && (
                  <div className="text-[10px] text-ocp-text-dim truncate mt-1">
                    {lastMsg.outgoing ? "You: " : ""}
                    {lastMsg.text}
                  </div>
                )}
              </button>
            );
          })}
        </div>

        {/* Destination node input */}
        <div className="border-t border-ocp-border p-3">
          <label className="text-[10px] uppercase tracking-wider text-ocp-text-dim block mb-1">
            Destination Node
          </label>
          <input
            type="text"
            value={destNode}
            onChange={(e) => setDestNode(e.target.value)}
            placeholder="Broadcast (empty)"
            className="w-full px-2 py-1.5 rounded-md border border-ocp-border bg-ocp-bg text-ocp-text text-xs placeholder:text-ocp-text-dim/50 focus:outline-none focus:border-ocp-accent transition-colors"
          />
        </div>
      </div>

      {/* Thread area */}
      <div className="flex-1 flex flex-col min-w-0 bg-ocp-bg">
        {/* Header */}
        <div className="h-12 border-b border-ocp-border flex items-center justify-between px-4">
          <span className="text-sm font-semibold text-ocp-accent text-glow">
            {CHANNELS[activeChannel].name}
          </span>
          <div className="flex items-center gap-3">
            <span className="text-[10px] text-ocp-text-dim font-mono">
              {thread.length} messages
            </span>
            <StatusLamp
              state={connected ? "on" : "off"}
              label={connected ? `${transportKind || "connected"}` : "offline"}
            />
          </div>
        </div>

        {/* Connection warning */}
        {!connected && (
          <div className="px-4 py-2 bg-ocp-red/10 border-b border-ocp-red/30 text-xs text-ocp-red text-center">
            No Meshtastic device connected — connect a node to send and receive messages.
          </div>
        )}

        {/* Error banner */}
        {(localError || sendError) && (
          <div className="px-4 py-2 bg-ocp-red/10 border-b border-ocp-red/30 text-xs text-ocp-red text-center">
            {localError || sendError}
          </div>
        )}

        {/* Message list */}
        <div className="flex-1 overflow-auto p-4 space-y-3">
          {thread.length === 0 && (
            <div className="text-center text-ocp-text-dim text-xs mt-8">
              {connected
                ? "No messages yet. Send one below."
                : "Connect a Meshtastic device to start messaging."}
            </div>
          )}
          {thread.map((m) => {
            const isMe = m.outgoing || m.from === "you" || m.from === 0 || m.from === "0";
            return (
              <div
                key={`${m.id}-${m.timestamp}`}
                className={[
                  "flex flex-col max-w-[70%]",
                  isMe ? "items-end self-end" : "items-start self-start",
                ].join(" ")}
              >
                <div
                  className={[
                    "px-3 py-2 rounded-lg text-xs leading-relaxed",
                    isMe
                      ? "bg-ocp-accent text-ocp-bg rounded-br-none"
                      : "bg-ocp-panel-2 text-ocp-text border border-ocp-border rounded-bl-none",
                  ].join(" ")}
                >
                  <div
                    className={[
                      "text-[10px] mb-1 font-semibold",
                      isMe ? "text-ocp-bg/70" : "text-ocp-accent",
                    ].join(" ")}
                  >
                    {isMe ? "You" : nodeLabel(m.from, state.nodes)}
                  </div>
                  {m.text}
                </div>
                <div className="flex items-center gap-1.5 mt-1 text-[9px] text-ocp-text-dim font-mono">
                  <span>{formatTime(m.timestamp)}</span>
                </div>
              </div>
            );
          })}
          <div ref={bottomRef} />
        </div>

        {/* Input area */}
        <div className="p-3 border-t border-ocp-border bg-ocp-panel flex gap-2">
          <input
            type="text"
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={handleKeyDown}
            disabled={!connected}
            placeholder={
              connected ? "Type message..." : "No device connected"
            }
            className="flex-1 px-3 py-2 rounded-md border border-ocp-border bg-ocp-bg text-ocp-text text-xs placeholder:text-ocp-text-dim/50 focus:outline-none focus:border-ocp-accent disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
          />
          <AnalogButton
            variant="accent"
            onClick={handleSend}
            disabled={!connected || !draft.trim()}
          >
            Send
          </AnalogButton>
        </div>
      </div>
    </div>
  );
}