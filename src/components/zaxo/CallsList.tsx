// ==================== CALLS LIST ====================
"use client";

import { useMemo, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Phone, Video, PhoneIncoming, PhoneOutgoing, PhoneMissed, MoreVertical, Trash2, PhoneOff } from "lucide-react";
import { NeuAvatar } from "@/components/neumorphic/NeuAvatar";
import { useAppStore } from "@/store/appStore";
import { useUIStore } from "@/store/uiStore";
import { relativeTime, formatDuration, getContactById } from "@/lib/zaxo/mockData";
import type { Call } from "@/types";

export function CallsList() {
  const { calls, contacts, clearCallHistory } = useAppStore();
  const { setSubPanel } = useUIStore();
  const [filter, setFilter] = useState<"all" | "missed">("all");
  const [menuOpen, setMenuOpen] = useState(false);

  const visible = useMemo(() => {
    if (filter === "missed") return calls.filter((c) => c.direction === "missed");
    return calls;
  }, [calls, filter]);

  return (
    <div className="flex flex-col h-full" style={{ background: "var(--neu-bg)" }}>
      <header className="px-4 pt-4 pb-2 flex items-center justify-between">
        <h1 className="text-2xl font-bold neu-text">Calls</h1>
        <button
          onClick={() => setMenuOpen(!menuOpen)}
          className="neu-pressable rounded-full w-10 h-10 flex items-center justify-center neu-text relative"
        >
          <MoreVertical size={18} />
          {menuOpen && (
            <div className="absolute right-0 top-12 z-30 neu-raised rounded-2xl py-2 min-w-[160px]">
              <button
                onClick={() => { clearCallHistory(); setMenuOpen(false); }}
                className="w-full px-4 py-2 flex items-center gap-3 text-sm neu-text-danger hover:opacity-70"
              >
                <Trash2 size={14} /> Clear call history
              </button>
            </div>
          )}
        </button>
      </header>

      {/* Filter */}
      <div className="px-4 mt-2">
        <div className="flex gap-2 p-1.5 neu-well rounded-2xl">
          {(["all", "missed"] as const).map((f) => (
            <button
              key={f}
              onClick={() => setFilter(f)}
              className={`flex-1 py-2 rounded-xl text-sm font-medium capitalize transition-all ${filter === f ? "neu-raised-sm neu-text" : "neu-text-muted"}`}
            >
              {f}
            </button>
          ))}
        </div>
      </div>

      {/* List */}
      <div className="flex-1 overflow-y-auto neu-scroll px-2 pt-2">
        {visible.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full px-8 text-center py-20">
            <div className="neu-raised-lg rounded-3xl w-24 h-24 flex items-center justify-center mb-5">
              <PhoneOff size={40} className="neu-text-muted" />
            </div>
            <h3 className="text-lg font-semibold neu-text">No call history</h3>
            <p className="text-sm neu-text-muted mt-2 max-w-xs">
              Your voice and video calls will appear here.
            </p>
          </div>
        ) : (
          visible.map((call) => (
            <CallItem key={call.id} call={call} />
          ))
        )}
        <div className="h-4" />
      </div>

      {/* FAB */}
      <button
        onClick={() => setSubPanel({ type: "new_call" })}
        className="absolute bottom-24 right-5 neu-accent w-14 h-14 rounded-full flex items-center justify-center z-20"
        aria-label="New call"
      >
        <Phone size={22} />
      </button>
    </div>
  );
}

function CallItem({ call }: { call: Call }) {
  const { contacts } = useAppStore();
  const { setSubPanel } = useUIStore();
  const other = getContactById(call.otherUserId, contacts);
  if (!other) return null;

  const isMissed = call.direction === "missed";
  const isIncoming = call.direction === "incoming";

  return (
    <div className="flex items-center gap-3 px-3 py-3 rounded-2xl hover:bg-[color:var(--neu-shadow-light)]/5 transition-all">
      <NeuAvatar initial={other.avatarInitial} gradient={other.avatarColor} size={44} />
      <div className="flex-1 min-w-0">
        <div className={`font-semibold text-sm truncate ${isMissed ? "neu-text-danger" : "neu-text"}`}>
          {other.displayName}
        </div>
        <div className="flex items-center gap-1 mt-0.5">
          {isMissed ? (
            <PhoneMissed size={12} className="neu-text-danger" />
          ) : isIncoming ? (
            <PhoneIncoming size={12} className="neu-text-success" />
          ) : (
            <PhoneOutgoing size={12} className="neu-text-accent" />
          )}
          <span className="text-xs neu-text-muted">
            {isMissed ? "Missed" : formatDuration(call.duration)} · {relativeTime(call.timestamp)}
          </span>
        </div>
      </div>
      <button
        onClick={() => setSubPanel({ type: "call_screen", otherUserId: call.otherUserId, callType: call.type })}
        className="neu-pressable rounded-full w-10 h-10 flex items-center justify-center neu-text-accent"
        aria-label={`Call back ${other.displayName}`}
      >
        {call.type === "video" ? <Video size={18} /> : <Phone size={18} />}
      </button>
    </div>
  );
}
