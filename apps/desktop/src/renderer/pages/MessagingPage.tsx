import { useState } from "react";
import { AnalogButton } from "../components/AnalogButton";
import { TextField } from "../components/TextField";

interface Message {
  id: string;
  sender: string;
  text: string;
  timestamp: number;
  me: boolean;
  status: "sending" | "sent" | "delivered" | "read";
}

interface Channel {
  id: string;
  name: string;
  lastMessage: string;
  unread: number;
}

const MOCK_CHANNELS: Channel[] = [
  { id: "0", name: "LongFast", lastMessage: "Base station online.", unread: 2 },
  { id: "1", name: "Tactical", lastMessage: "Moving to checkpoint B.", unread: 0 },
  { id: "2", name: "Mike", lastMessage: "Copy that.", unread: 1 },
];

const MOCK_MESSAGES: Record<string, Message[]> = {
  "0": [
    { id: "a1", sender: "T-Beam", text: "Base station online.", timestamp: Date.now() - 120_000, me: false, status: "read" },
    { id: "a2", sender: "RAK-4631", text: "Roger, mesh link stable.", timestamp: Date.now() - 90_000, me: false, status: "read" },
    { id: "a3", sender: "You", text: "Keep this channel open for status.", timestamp: Date.now() - 30_000, me: true, status: "delivered" },
    { id: "a4", sender: "T-Beam", text: "Copy. Standing by.", timestamp: Date.now() - 5_000, me: false, status: "read" },
  ],
  "1": [
    { id: "b1", sender: "Mike", text: "Moving to checkpoint B.", timestamp: Date.now() - 300_000, me: false, status: "read" },
  ],
  "2": [
    { id: "c1", sender: "Mike", text: "Copy that.", timestamp: Date.now() - 600_000, me: false, status: "read" },
  ],
};

function formatTime(ts: number): string {
  const d = new Date(ts);
  return d.toLocaleTimeString([], { hour: "2-digit", minute: "2-digit" });
}

export function MessagingPage() {
  const [activeChannel, setActiveChannel] = useState<string>("0");
  const [messages, setMessages] = useState(MOCK_MESSAGES);
  const [draft, setDraft] = useState("");

  const channel = MOCK_CHANNELS.find((c) => c.id === activeChannel)!;
  const thread = messages[activeChannel] || [];

  const send = () => {
    if (!draft.trim()) return;
    const msg: Message = {
      id: `${Date.now()}`,
      sender: "You",
      text: draft.trim(),
      timestamp: Date.now(),
      me: true,
      status: "sending",
    };
    setMessages((prev) => ({
      ...prev,
      [activeChannel]: [...(prev[activeChannel] || []), msg],
    }));
    setDraft("");
    // Simulate delivery
    setTimeout(() => {
      setMessages((prev) => ({
        ...prev,
        [activeChannel]: prev[activeChannel].map((m) =>
          m.id === msg.id ? { ...m, status: "delivered" } : m
        ),
      }));
    }, 800);
  };

  return (
    <div className="absolute inset-0 flex">
      {/* Channel list */}
      <div className="w-64 border-r border-ocp-border bg-ocp-panel flex flex-col">
        <div className="h-12 border-b border-ocp-border flex items-center px-4">
          <span className="text-xs uppercase tracking-wider text-ocp-accent font-semibold">Channels</span>
        </div>
        <div className="flex-1 overflow-auto">
          {MOCK_CHANNELS.map((c) => (
            <button
              key={c.id}
              onClick={() => setActiveChannel(c.id)}
              className={[
                "w-full text-left px-4 py-3 border-b border-ocp-border transition-colors",
                activeChannel === c.id
                  ? "bg-ocp-panel-2 border-l-2 border-l-ocp-accent"
                  : "hover:bg-ocp-panel-2/50",
              ].join(" ")}
            >
              <div className="flex items-center justify-between">
                <span className="text-sm font-medium text-ocp-text">{c.name}</span>
                {c.unread > 0 && (
                  <span className="px-1.5 py-0.5 rounded text-[10px] bg-ocp-accent text-ocp-bg font-bold">
                    {c.unread}
                  </span>
                )}
              </div>
              <div className="text-[10px] text-ocp-text-dim truncate mt-1">{c.lastMessage}</div>
            </button>
          ))}
        </div>
      </div>

      {/* Thread */}
      <div className="flex-1 flex flex-col min-w-0 bg-ocp-bg">
        <div className="h-12 border-b border-ocp-border flex items-center justify-between px-4">
          <span className="text-sm font-semibold text-ocp-accent text-glow">{channel.name}</span>
          <span className="text-[10px] text-ocp-text-dim font-mono">
            {thread.length} messages
          </span>
        </div>

        <div className="flex-1 overflow-auto p-4 space-y-3">
          {thread.map((m) => (
            <div
              key={m.id}
              className={[
                "flex flex-col max-w-[70%]",
                m.me ? "items-end self-end" : "items-start self-start",
              ].join(" ")}
            >
              <div
                className={[
                  "px-3 py-2 rounded-lg text-xs leading-relaxed",
                  m.me
                    ? "bg-ocp-accent text-ocp-bg rounded-br-none"
                    : "bg-ocp-panel-2 text-ocp-text border border-ocp-border rounded-bl-none",
                ].join(" ")}
              >
                <div className={["text-[10px] mb-1 font-semibold", m.me ? "text-ocp-bg/70" : "text-ocp-accent"].join(" ")}>
                  {m.sender}
                </div>
                {m.text}
              </div>
              <div className="flex items-center gap-1.5 mt-1 text-[9px] text-ocp-text-dim font-mono">
                <span>{formatTime(m.timestamp)}</span>
                {m.me && <span className="uppercase">{m.status}</span>}
              </div>
            </div>
          ))}
        </div>

        <div className="p-3 border-t border-ocp-border bg-ocp-panel flex gap-2">
          <input
            type="text"
            value={draft}
            onChange={(e) => setDraft(e.target.value)}
            onKeyDown={(e) => e.key === "Enter" && send()}
            placeholder="Type message..."
            className="flex-1 px-3 py-2 rounded-md border border-ocp-border bg-ocp-bg text-ocp-text text-xs placeholder:text-ocp-text-dim/50 focus:outline-none focus:border-ocp-accent"
          />
          <AnalogButton variant="accent" onClick={send} disabled={!draft.trim()}>
            Send
          </AnalogButton>
        </div>
      </div>
    </div>
  );
}
