// ==================== STATUS SCREEN ====================
"use client";

import { useEffect, useMemo, useRef, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Camera, Plus, X, Eye, Reply, ChevronLeft, ChevronRight, Pause,
  Type, Image as ImageIcon, Send, Trash2, MoreVertical, TextCursorInput,
} from "lucide-react";
import { NeuAvatar } from "@/components/neumorphic/NeuAvatar";
import { NeuButton } from "@/components/neumorphic/NeuButton";
import { useAppStore } from "@/store/appStore";
import { useUIStore } from "@/store/uiStore";
import { useAuthStore } from "@/store/authStore";
import { relativeTime, getContactById, STATUS_COLORS } from "@/lib/zaxo/mockData";
import type { StatusItem } from "@/types";

const TEXT_COLORS = ["#FFFFFF", "#FDFD96", "#FFB7C5", "#B5EAD7", "#C7CEEA"];

export function StatusScreen() {
  const { statuses, contacts } = useAppStore();
  const { setSubPanel } = useUIStore();
  const { user } = useAuthStore();

  const myStatuses = useMemo(() => statuses.filter((s) => s.userId === "me"), [statuses]);
  const otherStatuses = useMemo(() => statuses.filter((s) => s.userId !== "me"), [statuses]);

  // Expire stale statuses (older than 24h)
  useEffect(() => {
    const now = Date.now();
    const expired = statuses.filter((s) => s.expiresAt < now);
    if (expired.length > 0) {
      expired.forEach((s) => useAppStore.getState().deleteStatus(s.id));
    }
  }, [statuses]);

  // Group other statuses by user
  const grouped = useMemo(() => {
    const map = new Map<string, StatusItem[]>();
    otherStatuses.forEach((s) => {
      if (!map.has(s.userId)) map.set(s.userId, []);
      map.get(s.userId)!.push(s);
    });
    return Array.from(map.entries()).map(([userId, items]) => {
      const allViewed = items.every((s) => s.viewers.includes("me"));
      return { userId, items, allViewed };
    });
  }, [otherStatuses]);

  const recent = grouped.filter((g) => !g.allViewed);
  const viewed = grouped.filter((g) => g.allViewed);

  return (
    <div className="flex flex-col h-full w-full" style={{ background: "var(--neu-bg)" }}>
      <header className="px-3 sm:px-4 pt-4 pb-2 flex items-center justify-between">
        <h1 className="text-xl sm:text-2xl font-bold neu-text">Status</h1>
      </header>

      <div className="flex-1 overflow-y-auto neu-scroll px-2 sm:px-3 pt-2">
        {/* My status */}
        <button
          onClick={() => myStatuses.length > 0 ? setSubPanel({ type: "status_viewer", userId: "me" }) : setSubPanel({ type: "status_create" })}
          className="w-full flex items-center gap-3 px-2 sm:px-3 py-3 rounded-2xl hover:bg-[color:var(--neu-shadow-light)]/5 transition-all active:scale-[0.99]"
        >
          <div className="relative shrink-0">
            {user && (
              <NeuAvatar
                initial={user.avatarInitial}
                gradient={user.avatarColor}
                size={48}
                ring={myStatuses.length > 0 ? "unviewed" : "none"}
              />
            )}
            {myStatuses.length === 0 && (
              <div className="absolute -bottom-0.5 -right-0.5 w-5 h-5 rounded-full neu-accent flex items-center justify-center border-2" style={{ borderColor: "var(--neu-bg)" }}>
                <Plus size={12} className="text-white" />
              </div>
            )}
          </div>
          <div className="flex-1 text-left min-w-0">
            <div className="font-semibold text-sm neu-text">My status</div>
            <div className="text-xs neu-text-muted truncate">
              {myStatuses.length > 0
                ? `${myStatuses.length} update${myStatuses.length > 1 ? "s" : ""} · ${relativeTime(myStatuses[0].createdAt)}`
                : "Tap to add status update"}
            </div>
          </div>
          {myStatuses.length > 0 && (
            <button
              onClick={(e) => { e.stopPropagation(); setSubPanel({ type: "status_create" }); }}
              className="neu-pressable rounded-full w-9 h-9 flex items-center justify-center shrink-0"
              aria-label="Add another status"
            >
              <Plus size={16} className="neu-text-accent" />
            </button>
          )}
        </button>

        {/* Recent updates */}
        {recent.length > 0 && (
          <>
            <div className="px-2 sm:px-3 pt-4 pb-1 text-xs font-semibold neu-text-muted uppercase tracking-wider">Recent updates</div>
            {recent.map((g) => (
              <StatusRow key={g.userId} userId={g.userId} items={g.items} />
            ))}
          </>
        )}

        {/* Viewed updates */}
        {viewed.length > 0 && (
          <>
            <div className="px-2 sm:px-3 pt-4 pb-1 text-xs font-semibold neu-text-muted uppercase tracking-wider">Viewed updates</div>
            {viewed.map((g) => (
              <StatusRow key={g.userId} userId={g.userId} items={g.items} />
            ))}
          </>
        )}

        {otherStatuses.length === 0 && (
          <div className="flex flex-col items-center justify-center h-64 px-8 text-center">
            <div className="neu-raised-lg rounded-3xl w-24 h-24 flex items-center justify-center mb-4">
              <Camera size={36} className="neu-text-accent" />
            </div>
            <h3 className="text-base font-semibold neu-text">No status updates</h3>
            <p className="text-xs neu-text-muted mt-2 max-w-xs">
              Status updates from your contacts will appear here. They disappear after 24 hours.
            </p>
          </div>
        )}
        <div className="h-4" />
      </div>

      {/* FAB */}
      <button
        onClick={() => setSubPanel({ type: "status_create" })}
        className="absolute bottom-24 right-4 sm:right-5 neu-accent w-14 h-14 rounded-full flex items-center justify-center z-20 active:scale-95 transition-transform"
        aria-label="Add status"
      >
        <Camera size={22} />
      </button>
    </div>
  );
}

function StatusRow({ userId, items }: { userId: string; items: StatusItem[] }) {
  const { contacts } = useAppStore();
  const { setSubPanel } = useUIStore();
  const contact = getContactById(userId, contacts);
  if (!contact) return null;
  const viewed = items.every((s) => s.viewers.includes("me"));

  return (
    <button
      onClick={() => setSubPanel({ type: "status_viewer", userId })}
      className="w-full flex items-center gap-3 px-2 sm:px-3 py-3 rounded-2xl hover:bg-[color:var(--neu-shadow-light)]/5 transition-all active:scale-[0.99]"
    >
      <NeuAvatar
        initial={contact.avatarInitial}
        gradient={contact.avatarColor}
        size={48}
        ring={viewed ? "viewed" : "unviewed"}
      />
      <div className="flex-1 text-left min-w-0">
        <div className="font-semibold text-sm neu-text truncate">{contact.displayName}</div>
        <div className="text-xs neu-text-muted truncate">
          {relativeTime(items[items.length - 1].createdAt)}
          {items.length > 1 && ` · ${items.length} updates`}
        </div>
      </div>
    </button>
  );
}

// ==================== STATUS VIEWER ====================
export function StatusViewer({ userId }: { userId: string }) {
  const { statuses, contacts, viewStatus, deleteStatus } = useAppStore();
  const { setSubPanel } = useUIStore();
  const { user } = useAuthStore();

  const userStatuses = useMemo(() =>
    userId === "me" ? statuses.filter((s) => s.userId === "me") : statuses.filter((s) => s.userId === userId),
    [statuses, userId]);

  const [idx, setIdx] = useState(0);
  const [paused, setPaused] = useState(false);
  const [progress, setProgress] = useState(0);
  const [replyText, setReplyText] = useState("");
  const [showViewers, setShowViewers] = useState(false);
  const tickRef = useRef<ReturnType<typeof setInterval> | null>(null);

  const contact = userId === "me" ? null : getContactById(userId, contacts);
  const current = userStatuses[idx];

  // Mark viewed
  useEffect(() => {
    if (current) viewStatus(current.id, user?.id || "me");
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [idx, current?.id]);

  // Auto-advance progress
  useEffect(() => {
    if (!current || paused) return;
    setProgress(0);
    const DURATION = 6000; // 6s per status
    const start = Date.now();
    tickRef.current = setInterval(() => {
      const elapsed = Date.now() - start;
      const p = Math.min(100, (elapsed / DURATION) * 100);
      setProgress(p);
      if (p >= 100) {
        if (tickRef.current) clearInterval(tickRef.current);
        if (idx < userStatuses.length - 1) {
          setIdx(idx + 1);
        } else {
          setSubPanel({ type: "none" });
        }
      }
    }, 50);
    return () => { if (tickRef.current) clearInterval(tickRef.current); };
  }, [idx, current, paused, userStatuses.length, setSubPanel]);

  // Auto-close when no statuses left
  useEffect(() => {
    if (!current) {
      const t = setTimeout(() => setSubPanel({ type: "none" }), 100);
      return () => clearTimeout(t);
    }
  }, [current, setSubPanel]);

  if (!current) {
    return null;
  }

  const name = userId === "me" ? user?.displayName || "You" : contact?.displayName || "Unknown";

  function next() {
    if (idx < userStatuses.length - 1) setIdx(idx + 1);
    else setSubPanel({ type: "none" });
  }
  function prev() {
    if (idx > 0) setIdx(idx - 1);
  }

  function sendReply() {
    if (!replyText.trim()) return;
    // In a real app, this would send a chat message to the user with the status context
    // For demo: just clear + show a toast-like confirmation
    const { startChatWithContact } = useAppStore.getState();
    const chatId = startChatWithContact(userId === "me" ? (contact?.id || "u_sarah") : userId);
    useAppStore.getState().sendMessage(chatId, `Reply to your status: "${replyText}"`);
    setReplyText("");
    setSubPanel({ type: "none" });
  }

  return (
    <div className="flex flex-col h-full w-full relative" style={{ background: "#0a0a0f" }}>
      {/* Progress bars */}
      <div className="absolute top-0 left-0 right-0 z-30 flex gap-1 p-2.5 sm:p-3">
        {userStatuses.map((_, i) => (
          <div key={i} className="flex-1 h-0.5 bg-white/30 rounded-full overflow-hidden">
            <div
              className="h-full bg-white transition-all"
              style={{ width: i < idx ? "100%" : i === idx ? `${progress}%` : "0%" }}
            />
          </div>
        ))}
      </div>

      {/* Header */}
      <div className="absolute top-5 left-0 right-0 z-20 flex items-center gap-3 px-3 sm:px-4 pt-3">
        <NeuAvatar initial={contact?.avatarInitial || user?.avatarInitial || "?"} gradient={contact?.avatarColor || user?.avatarColor || ""} size={36} />
        <div className="flex-1 min-w-0">
          <div className="text-sm font-medium text-white truncate">{name}</div>
          <div className="text-xs text-white/60">{relativeTime(current.createdAt)}</div>
        </div>
        {userId === "me" && (
          <>
            <button
              onClick={() => setShowViewers(!showViewers)}
              className="text-white/80 hover:text-white p-2"
              aria-label="Viewers"
            >
              <Eye size={20} />
            </button>
            <button
              onClick={() => {
                if (confirm("Delete this status?")) {
                  deleteStatus(current.id);
                  if (idx > 0) setIdx(idx - 1);
                  else if (userStatuses.length <= 1) setSubPanel({ type: "none" });
                }
              }}
              className="text-white/80 hover:text-white p-2"
              aria-label="Delete"
            >
              <Trash2 size={20} />
            </button>
          </>
        )}
        <button onClick={() => setPaused(!paused)} className="text-white/80 hover:text-white p-2" aria-label={paused ? "Play" : "Pause"}>
          {paused ? <ChevronRight size={20} /> : <Pause size={20} />}
        </button>
        <button onClick={() => setSubPanel({ type: "none" })} className="text-white/80 hover:text-white p-2" aria-label="Close">
          <X size={22} />
        </button>
      </div>

      {/* Tap zones */}
      <button
        onClick={prev}
        className="absolute left-0 top-0 bottom-0 w-1/3 z-10"
        aria-label="Previous"
      />
      <button
        onClick={next}
        className="absolute right-0 top-0 bottom-0 w-1/3 z-10"
        aria-label="Next"
      />

      {/* Content */}
      <div className="flex-1 flex items-center justify-center px-4 sm:px-6">
        {current.type === "text" ? (
          <motion.div
            key={current.id}
            initial={{ scale: 0.92, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="w-full max-w-md aspect-square rounded-3xl flex items-center justify-center p-6 sm:p-8"
            style={{ background: current.backgroundColor || STATUS_COLORS[0] }}
          >
            <div className="text-white text-xl sm:text-2xl font-bold text-center leading-relaxed break-words">
              {current.text}
            </div>
          </motion.div>
        ) : (
          <motion.div
            key={current.id}
            initial={{ scale: 0.92, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="w-full max-w-md aspect-[3/4] rounded-3xl flex items-center justify-center relative overflow-hidden"
            style={{ background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)" }}
          >
            <div className="text-center text-white">
              <ImageIcon size={48} className="mx-auto opacity-50" />
              <div className="mt-3 text-sm opacity-70">Photo status</div>
            </div>
            {current.caption && (
              <div className="absolute bottom-0 left-0 right-0 p-4 text-center text-white text-sm bg-gradient-to-t from-black/60 to-transparent">
                {current.caption}
              </div>
            )}
          </motion.div>
        )}
      </div>

      {/* Footer: reply bar (other user) or viewers count (me) */}
      {userId !== "me" ? (
        <div className="absolute bottom-6 left-0 right-0 px-4 sm:px-6 flex items-center gap-2 z-20">
          <input
            value={replyText}
            onChange={(e) => setReplyText(e.target.value)}
            onKeyDown={(e) => { if (e.key === "Enter") sendReply(); }}
            placeholder={`Reply to ${name.split(" ")[0]}…`}
            className="flex-1 bg-white/10 backdrop-blur rounded-full px-4 py-2.5 text-sm text-white placeholder:text-white/50 outline-none border border-white/15"
          />
          <button
            onClick={sendReply}
            disabled={!replyText.trim()}
            className="neu-accent rounded-full w-11 h-11 flex items-center justify-center disabled:opacity-40"
            aria-label="Send reply"
          >
            <Send size={16} />
          </button>
        </div>
      ) : (
        current.viewers.length > 0 && (
          <div className="absolute bottom-6 left-0 right-0 px-4 sm:px-6 flex items-center justify-center gap-2 text-white/70 text-xs z-20">
            <Eye size={14} /> {current.viewers.length} viewer{current.viewers.length > 1 ? "s" : ""}
          </div>
        )
      )}

      {/* Viewers sheet */}
      <AnimatePresence>
        {showViewers && userId === "me" && (
          <motion.div
            initial={{ y: "100%" }}
            animate={{ y: 0 }}
            exit={{ y: "100%" }}
            transition={{ type: "spring", damping: 30 }}
            className="absolute bottom-0 left-0 right-0 z-40 bg-white dark:bg-zinc-900 rounded-t-3xl p-4 pb-6 max-h-[60%] overflow-y-auto"
          >
            <div className="w-12 h-1 bg-zinc-300 dark:bg-zinc-700 rounded-full mx-auto mb-3" />
            <h3 className="text-base font-semibold mb-3" style={{ color: "var(--neu-text)" }}>Viewers</h3>
            {current.viewers.length === 0 ? (
              <p className="text-sm" style={{ color: "var(--neu-text-muted)" }}>No views yet</p>
            ) : (
              current.viewers.map((vid) => {
                const v = getContactById(vid, contacts);
                if (!v) return null;
                return (
                  <div key={vid} className="flex items-center gap-3 py-2">
                    <NeuAvatar initial={v.avatarInitial} gradient={v.avatarColor} size={36} />
                    <div className="text-sm font-medium" style={{ color: "var(--neu-text)" }}>{v.displayName}</div>
                  </div>
                );
              })
            )}
            <NeuButton variant="raised" fullWidth rounded="xl" className="mt-3" onClick={() => setShowViewers(false)}>Close</NeuButton>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

// ==================== STATUS CREATOR ====================
export function StatusCreator() {
  const { addStatus } = useAppStore();
  const { setSubPanel } = useUIStore();
  const { user } = useAuthStore();
  const [type, setType] = useState<"text" | "image">("text");
  const [text, setText] = useState("");
  const [caption, setCaption] = useState("");
  const [bgColor, setBgColor] = useState(STATUS_COLORS[0]);
  const [textColor, setTextColor] = useState(TEXT_COLORS[0]);

  function handlePost() {
    if (type === "text" && !text.trim()) return;
    const newStatus: StatusItem = {
      id: `s_me_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
      userId: "me",
      type,
      text: type === "text" ? text.trim() : undefined,
      backgroundColor: type === "text" ? bgColor : undefined,
      caption: type === "image" ? caption.trim() || undefined : undefined,
      createdAt: Date.now(),
      expiresAt: Date.now() + 24 * 60 * 60 * 1000,
      viewers: [],
      privacy: "contacts",
    };
    addStatus(newStatus);
    setSubPanel({ type: "none" });
  }

  return (
    <div className="flex flex-col h-full w-full px-4 sm:px-6 py-4" style={{ background: "var(--neu-bg)" }}>
      <header className="flex items-center justify-between mb-4">
        <h1 className="text-lg sm:text-xl font-bold neu-text">New status</h1>
        <button onClick={() => setSubPanel({ type: "none" })} className="neu-text-muted p-2">
          <X size={20} />
        </button>
      </header>

      {/* Type selector */}
      <div className="flex gap-2 p-1.5 neu-well rounded-2xl mb-4">
        <button
          onClick={() => setType("text")}
          className={`flex-1 py-2 rounded-xl text-sm font-medium transition-all flex items-center justify-center gap-2 ${type === "text" ? "neu-raised-sm neu-text" : "neu-text-muted"}`}
        >
          <TextCursorInput size={16} /> Text
        </button>
        <button
          onClick={() => setType("image")}
          className={`flex-1 py-2 rounded-xl text-sm font-medium transition-all flex items-center justify-center gap-2 ${type === "image" ? "neu-raised-sm neu-text" : "neu-text-muted"}`}
        >
          <ImageIcon size={16} /> Image
        </button>
      </div>

      {/* Preview */}
      <div
        className="aspect-square w-full max-w-sm mx-auto rounded-3xl flex items-center justify-center p-6 mb-4"
        style={{ background: type === "text" ? bgColor : "linear-gradient(135deg, #667eea 0%, #764ba2 100%)" }}
      >
        {type === "image" ? (
          <div className="text-center text-white/80">
            <ImageIcon size={48} className="mx-auto opacity-50" />
            <div className="mt-2 text-xs">Photo placeholder</div>
            <div className="mt-1 text-[10px] opacity-60">(Camera upload coming soon)</div>
          </div>
        ) : (
          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="Type a status…"
            className="w-full bg-transparent outline-none border-none text-center font-bold resize-none placeholder:opacity-50"
            style={{ color: textColor, fontSize: "1.5rem", lineHeight: 1.4 }}
            rows={5}
            maxLength={200}
          />
        )}
      </div>

      {/* Color picker */}
      {type === "text" && (
        <>
          <div className="text-xs neu-text-muted mb-1.5">Background</div>
          <div className="flex gap-2 mb-3 overflow-x-auto no-scrollbar">
            {STATUS_COLORS.map((c) => (
              <button
                key={c}
                onClick={() => setBgColor(c)}
                className={`w-9 h-9 rounded-full shrink-0 transition-all ${bgColor === c ? "ring-2 ring-offset-2 ring-offset-[var(--neu-bg)]" : ""}`}
                style={{ background: c, boxShadow: bgColor === c ? `0 0 0 2px ${c}` : "none" }}
                aria-label={`Background ${c}`}
              />
            ))}
          </div>
          <div className="text-xs neu-text-muted mb-1.5">Text color</div>
          <div className="flex gap-2 mb-4">
            {TEXT_COLORS.map((c) => (
              <button
                key={c}
                onClick={() => setTextColor(c)}
                className={`w-9 h-9 rounded-full shrink-0 transition-all border ${textColor === c ? "ring-2 ring-offset-2 ring-offset-[var(--neu-bg)]" : ""}`}
                style={{ background: c, borderColor: "rgba(0,0,0,0.1)" }}
                aria-label={`Text color ${c}`}
              />
            ))}
          </div>
        </>
      )}

      {type === "image" && (
        <input
          value={caption}
          onChange={(e) => setCaption(e.target.value)}
          placeholder="Add a caption…"
          className="neu-well rounded-2xl px-4 py-3 text-sm neu-text outline-none border-none mb-4"
        />
      )}

      <div className="flex-1" />

      <NeuButton variant="accent" size="lg" fullWidth rounded="xl" onClick={handlePost} disabled={type === "text" && !text.trim()}>
        Post status
      </NeuButton>
      <p className="text-[10px] neu-text-muted text-center mt-2">
        Status auto-deletes after 24 hours · Visible to your contacts
      </p>
    </div>
  );
}
