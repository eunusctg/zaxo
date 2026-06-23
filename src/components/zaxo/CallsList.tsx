// ==================== CALLS LIST ====================
"use client";

import { useMemo, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Phone, Video, PhoneIncoming, PhoneOutgoing, PhoneMissed,
  MoreVertical, Trash2, PhoneOff, Info, UserPlus,
} from "lucide-react";
import { NeuAvatar } from "@/components/neumorphic/NeuAvatar";
import { useAppStore } from "@/store/appStore";
import { useUIStore } from "@/store/uiStore";
import { relativeTime, formatDuration, getContactById, formatDateSeparator } from "@/lib/zaxo/mockData";
import type { Call } from "@/types";

export function CallsList() {
  const { calls, contacts, clearCallHistory, addCall } = useAppStore();
  const { setSubPanel } = useUIStore();
  const [filter, setFilter] = useState<"all" | "missed" | "incoming" | "outgoing">("all");
  const [menuOpen, setMenuOpen] = useState(false);

  const visible = useMemo(() => {
    if (filter === "all") return calls;
    return calls.filter((c) => c.direction === filter);
  }, [calls, filter]);

  // Group by date
  const grouped = useMemo(() => {
    const groups: { date: string; items: Call[] }[] = [];
    visible.forEach((call) => {
      const d = formatDateSeparator(call.timestamp);
      const last = groups[groups.length - 1];
      if (last && last.date === d) last.items.push(call);
      else groups.push({ date: d, items: [call] });
    });
    return groups;
  }, [visible]);

  const missedCount = calls.filter((c) => c.direction === "missed").length;

  return (
    <div className="flex flex-col h-full w-full" style={{ background: "var(--neu-bg)" }}>
      <header className="px-3 sm:px-4 pt-4 pb-2 flex items-center justify-between">
        <div>
          <h1 className="text-xl sm:text-2xl font-bold neu-text">Calls</h1>
          {missedCount > 0 && (
            <div className="text-xs neu-text-danger mt-0.5">{missedCount} missed call{missedCount > 1 ? "s" : ""}</div>
          )}
        </div>
        <div className="flex items-center gap-2">
          <button
            onClick={() => setSubPanel({ type: "new_call" })}
            className="neu-pressable rounded-full w-10 h-10 flex items-center justify-center neu-text"
            aria-label="New call"
          >
            <UserPlus size={18} />
          </button>
          <button
            onClick={() => setMenuOpen(!menuOpen)}
            className="neu-pressable rounded-full w-10 h-10 flex items-center justify-center neu-text relative"
            aria-label="More"
          >
            <MoreVertical size={18} />
            {menuOpen && (
              <div className="absolute right-0 top-12 z-30 neu-raised rounded-2xl py-2 min-w-[160px]">
                <button
                  onClick={() => {
                    if (confirm("Clear entire call history?")) clearCallHistory();
                    setMenuOpen(false);
                  }}
                  className="w-full px-4 py-2 flex items-center gap-3 text-sm neu-text-danger hover:opacity-70"
                >
                  <Trash2 size={14} /> Clear call history
                </button>
              </div>
            )}
          </button>
        </div>
      </header>

      {/* Filter chips */}
      <div className="px-3 sm:px-4 mt-2">
        <div className="flex gap-1.5 overflow-x-auto no-scrollbar">
          {(["all", "missed", "incoming", "outgoing"] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`shrink-0 px-3 py-1.5 rounded-full text-xs font-medium capitalize transition-all ${
                filter === f ? "neu-accent text-white" : "neu-raised-sm neu-text-muted"
              }`}
            >
              {f}
            </button>
          ))}
        </div>
      </div>

      {/* List */}
      <div className="flex-1 overflow-y-auto neu-scroll px-2 sm:px-3 pt-3">
        {visible.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full px-8 text-center py-20">
            <div className="neu-raised-lg rounded-3xl w-24 h-24 flex items-center justify-center mb-5">
              <PhoneOff size={40} className="neu-text-muted" />
            </div>
            <h3 className="text-lg font-semibold neu-text">No call history</h3>
            <p className="text-sm neu-text-muted mt-2 max-w-xs">
              Your voice and video calls will appear here, organized by day.
            </p>
          </div>
        ) : (
          grouped.map((group) => (
            <div key={group.date} className="mb-2">
              <div className="px-2 py-1.5 text-xs font-semibold neu-text-muted uppercase tracking-wider">
                {group.date}
              </div>
              <div className="neu-raised rounded-2xl overflow-hidden">
                {group.items.map((call, i) => (
                  <CallItem
                    key={call.id}
                    call={call}
                    isLast={i === group.items.length - 1}
                  />
                ))}
              </div>
            </div>
          ))
        )}
        <div className="h-4" />
      </div>

      {/* FAB */}
      <button
        onClick={() => setSubPanel({ type: "new_call" })}
        className="absolute bottom-24 right-4 sm:right-5 neu-accent w-14 h-14 rounded-full flex items-center justify-center z-20 active:scale-95 transition-transform"
        aria-label="New call"
      >
        <Phone size={22} />
      </button>
    </div>
  );
}

function CallItem({ call, isLast }: { call: Call; isLast: boolean }) {
  const { contacts } = useAppStore();
  const { setSubPanel } = useUIStore();
  const [menuOpen, setMenuOpen] = useState(false);
  const other = getContactById(call.otherUserId, contacts);
  if (!other) return null;

  const isMissed = call.direction === "missed";
  const isIncoming = call.direction === "incoming";

  function startCall(type: "voice" | "video") {
    setSubPanel({ type: "call_screen", otherUserId: call.otherUserId, callType: type });
  }

  return (
    <div
      className={`relative flex items-center gap-3 px-3 py-3 hover:bg-[color:var(--neu-shadow-light)]/5 transition-all ${isLast ? "" : "border-b border-[color:var(--neu-shadow-dark)]/10"}`}
    >
      <NeuAvatar initial={other.avatarInitial} gradient={other.avatarColor} size={44} online={other.online} />
      <button
        onClick={() => {
          // Open chat with this contact
          const { startChatWithContact } = useAppStore.getState();
          const chatId = startChatWithContact(call.otherUserId);
          setSubPanel({ type: "chat_room", chatId });
        }}
        className="flex-1 min-w-0 text-left"
      >
        <div className={`font-semibold text-sm truncate ${isMissed ? "neu-text-danger" : "neu-text"}`}>
          {other.displayName}
        </div>
        <div className="flex items-center gap-1.5 mt-0.5">
          {isMissed ? (
            <PhoneMissed size={12} className="neu-text-danger shrink-0" />
          ) : isIncoming ? (
            <PhoneIncoming size={12} className="neu-text-success shrink-0" />
          ) : (
            <PhoneOutgoing size={12} className="neu-text-accent shrink-0" />
          )}
          <span className="text-xs neu-text-muted truncate">
            {isMissed ? "Missed" : formatDuration(call.duration)} · {relativeTime(call.timestamp)}
          </span>
          <span className="text-xs neu-text-muted shrink-0">
            · {call.type === "video" ? "Video" : "Voice"}
          </span>
        </div>
      </button>

      {/* Quick call-back buttons */}
      <button
        onClick={() => startCall(call.type)}
        className="neu-pressable rounded-full w-9 h-9 flex items-center justify-center neu-text-accent"
        aria-label={`Call back ${other.displayName}`}
      >
        {call.type === "video" ? <Video size={16} /> : <Phone size={16} />}
      </button>

      <button
        onClick={() => setMenuOpen(!menuOpen)}
        className="neu-text-muted p-1"
        aria-label="More"
      >
        <MoreVertical size={16} />
      </button>

      <AnimatePresence>
        {menuOpen && (
          <motion.div
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            className="absolute right-3 top-12 z-30 neu-raised rounded-2xl py-2 min-w-[150px]"
            onClick={() => setMenuOpen(false)}
          >
            <button
              onClick={() => startCall("voice")}
              className="w-full px-4 py-2 flex items-center gap-3 text-sm neu-text hover:opacity-70"
            >
              <Phone size={14} /> Voice call
            </button>
            <button
              onClick={() => startCall("video")}
              className="w-full px-4 py-2 flex items-center gap-3 text-sm neu-text hover:opacity-70"
            >
              <Video size={14} /> Video call
            </button>
            <button
              onClick={() => {
                // Info
                alert(`${other.displayName}\n${other.zaxoNumber}\n${call.type} call · ${call.direction}\n${relativeTime(call.timestamp)}${call.duration > 0 ? ` · ${formatDuration(call.duration)}` : ""}`);
              }}
              className="w-full px-4 py-2 flex items-center gap-3 text-sm neu-text hover:opacity-70"
            >
              <Info size={14} /> Call info
            </button>
            <button
              onClick={() => {
                useAppStore.setState((s) => ({ calls: s.calls.filter((c) => c.id !== call.id) }));
              }}
              className="w-full px-4 py-2 flex items-center gap-3 text-sm neu-text-danger hover:opacity-70"
            >
              <Trash2 size={14} /> Delete
            </button>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}
