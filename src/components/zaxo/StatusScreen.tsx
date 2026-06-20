// ==================== STATUS SCREEN ====================
"use client";

import { useMemo } from "react";
import { motion } from "framer-motion";
import { Camera, Plus, X, Eye, Reply, ChevronLeft, ChevronRight, Pause, Type, Image as ImageIcon } from "lucide-react";
import { NeuAvatar } from "@/components/neumorphic/NeuAvatar";
import { NeuButton } from "@/components/neumorphic/NeuButton";
import { useAppStore } from "@/store/appStore";
import { useUIStore } from "@/store/uiStore";
import { useAuthStore } from "@/store/authStore";
import { relativeTime, getContactById, STATUS_COLORS } from "@/lib/zaxo/mockData";
import type { StatusItem } from "@/types";

export function StatusScreen() {
  const { statuses, contacts } = useAppStore();
  const { setSubPanel } = useUIStore();
  const { user } = useAuthStore();

  const myStatuses = useMemo(() => statuses.filter((s) => s.userId === "me"), [statuses]);
  const otherStatuses = useMemo(() => statuses.filter((s) => s.userId !== "me"), [statuses]);

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
    <div className="flex flex-col h-full" style={{ background: "var(--neu-bg)" }}>
      <header className="px-4 pt-4 pb-2 flex items-center justify-between">
        <h1 className="text-2xl font-bold neu-text">Status</h1>
      </header>

      <div className="flex-1 overflow-y-auto neu-scroll px-2 pt-2">
        {/* My status */}
        <button
          onClick={() => myStatuses.length > 0 ? setSubPanel({ type: "status_viewer", userId: "me" }) : setSubPanel({ type: "status_create" })}
          className="w-full flex items-center gap-3 px-3 py-3 rounded-2xl hover:bg-[color:var(--neu-shadow-light)]/5 transition-all"
        >
          <div className="relative">
            {user && (
              <NeuAvatar
                initial={user.avatarInitial}
                gradient={user.avatarColor}
                size={50}
                ring={myStatuses.length > 0 ? "unviewed" : "none"}
              />
            )}
            {myStatuses.length === 0 && (
              <div className="absolute -bottom-0.5 -right-0.5 w-5 h-5 rounded-full neu-accent flex items-center justify-center border-2" style={{ borderColor: "var(--neu-bg)" }}>
                <Plus size={12} className="text-white" />
              </div>
            )}
          </div>
          <div className="flex-1 text-left">
            <div className="font-semibold text-sm neu-text">My status</div>
            <div className="text-xs neu-text-muted">
              {myStatuses.length > 0
                ? `${myStatuses.length} update${myStatuses.length > 1 ? "s" : ""} · ${relativeTime(myStatuses[0].createdAt)}`
                : "Tap to add status update"}
            </div>
          </div>
        </button>

        {/* Recent updates */}
        {recent.length > 0 && (
          <>
            <div className="px-3 pt-4 pb-1 text-xs font-semibold neu-text-muted uppercase tracking-wider">Recent updates</div>
            {recent.map((g) => (
              <StatusRow key={g.userId} userId={g.userId} items={g.items} />
            ))}
          </>
        )}

        {/* Viewed updates */}
        {viewed.length > 0 && (
          <>
            <div className="px-3 pt-4 pb-1 text-xs font-semibold neu-text-muted uppercase tracking-wider">Viewed updates</div>
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
        className="absolute bottom-24 right-5 neu-accent w-14 h-14 rounded-full flex items-center justify-center z-20"
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
      className="w-full flex items-center gap-3 px-3 py-3 rounded-2xl hover:bg-[color:var(--neu-shadow-light)]/5 transition-all"
    >
      <NeuAvatar
        initial={contact.avatarInitial}
        gradient={contact.avatarColor}
        size={50}
        ring={viewed ? "viewed" : "unviewed"}
      />
      <div className="flex-1 text-left">
        <div className="font-semibold text-sm neu-text">{contact.displayName}</div>
        <div className="text-xs neu-text-muted">
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

  const contact = userId === "me" ? null : getContactById(userId, contacts);
  const current = userStatuses[idx];

  // Auto-advance
  useEffect(() => {
    if (!current || paused) return;
    viewStatus(current.id, user?.id || "me");
    const timer = setTimeout(() => {
      if (idx < userStatuses.length - 1) {
        setIdx(idx + 1);
      } else {
        setSubPanel({ type: "none" });
      }
    }, 5000);
    return () => clearTimeout(timer);
  }, [idx, current, paused, userStatuses.length]);

  if (!current) {
    setSubPanel({ type: "none" });
    return null;
  }

  const name = userId === "me" ? user?.displayName || "You" : contact?.displayName || "Unknown";

  return (
    <div className="flex flex-col h-full relative" style={{ background: "#0a0a0f" }}>
      {/* Progress bars */}
      <div className="absolute top-0 left-0 right-0 z-30 flex gap-1 p-3">
        {userStatuses.map((_, i) => (
          <div key={i} className="flex-1 h-0.5 bg-white/30 rounded-full overflow-hidden">
            <motion.div
              className="h-full bg-white"
              initial={{ width: i < idx ? "100%" : "0%" }}
              animate={{ width: i === idx && !paused ? "100%" : i < idx ? "100%" : "0%" }}
              transition={{ duration: i === idx && !paused ? 5 : 0, ease: "linear" }}
            />
          </div>
        ))}
      </div>

      {/* Header */}
      <div className="absolute top-6 left-0 right-0 z-20 flex items-center gap-3 px-4 pt-3">
        <NeuAvatar initial={contact?.avatarInitial || user?.avatarInitial || "?"} gradient={contact?.avatarColor || user?.avatarColor || ""} size={36} />
        <div className="flex-1 min-w-0">
          <div className="text-sm font-medium text-white truncate">{name}</div>
          <div className="text-xs text-white/60">{relativeTime(current.createdAt)}</div>
        </div>
        {userId === "me" && (
          <button
            onClick={() => { deleteStatus(current.id); if (idx > 0) setIdx(idx - 1); }}
            className="text-white/80 hover:text-white p-2"
          >
            <X size={20} />
          </button>
        )}
        <button onClick={() => setPaused(!paused)} className="text-white/80 hover:text-white p-2">
          {paused ? <ChevronRight size={20} /> : <Pause size={20} />}
        </button>
      </div>

      {/* Tap zones */}
      <button
        onClick={() => idx > 0 && setIdx(idx - 1)}
        className="absolute left-0 top-0 bottom-0 w-1/3 z-10"
        aria-label="Previous"
      />
      <button
        onClick={() => idx < userStatuses.length - 1 ? setIdx(idx + 1) : setSubPanel({ type: "none" })}
        className="absolute right-0 top-0 bottom-0 w-1/3 z-10"
        aria-label="Next"
      />

      {/* Content */}
      <div className="flex-1 flex items-center justify-center px-6">
        {current.type === "text" ? (
          <motion.div
            key={current.id}
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="w-full max-w-md aspect-square rounded-3xl flex items-center justify-center p-8"
            style={{ background: current.backgroundColor || STATUS_COLORS[0] }}
          >
            <div className="text-white text-2xl font-bold text-center leading-relaxed">
              {current.text}
            </div>
          </motion.div>
        ) : (
          <motion.div
            key={current.id}
            initial={{ scale: 0.9, opacity: 0 }}
            animate={{ scale: 1, opacity: 1 }}
            className="w-full max-w-md aspect-[3/4] rounded-3xl flex items-center justify-center"
            style={{ background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)" }}
          >
            <div className="text-center text-white">
              <ImageIcon size={48} className="mx-auto opacity-50" />
              <div className="mt-3 text-sm opacity-70">{current.caption}</div>
            </div>
          </motion.div>
        )}
        {current.caption && current.type !== "text" && (
          <div className="absolute bottom-20 left-0 right-0 text-center text-white text-sm px-8">
            {current.caption}
          </div>
        )}
      </div>

      {/* Footer */}
      {userId !== "me" && (
        <div className="absolute bottom-8 left-0 right-0 px-6 flex items-center justify-center gap-3 z-20">
          <button
            onClick={() => setSubPanel({ type: "none" })}
            className="neu-raised-sm rounded-full px-4 py-2.5 flex items-center gap-2 text-white"
            style={{ background: "rgba(255,255,255,0.15)", backdropFilter: "blur(8px)" }}
          >
            <Reply size={16} /> Reply privately
          </button>
        </div>
      )}

      {userId === "me" && current.viewers.length > 0 && (
        <div className="absolute bottom-8 left-0 right-0 px-6 flex items-center justify-center gap-2 text-white/70 text-xs z-20">
          <Eye size={14} /> {current.viewers.length} viewer{current.viewers.length > 1 ? "s" : ""}
        </div>
      )}
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
  const [bgColor, setBgColor] = useState(STATUS_COLORS[0]);

  function handlePost() {
    if (type === "text" && !text.trim()) return;
    const newStatus: StatusItem = {
      id: `s_me_${Date.now()}`,
      userId: "me",
      type,
      text: type === "text" ? text.trim() : undefined,
      backgroundColor: type === "text" ? bgColor : undefined,
      caption: type === "image" ? text.trim() || undefined : undefined,
      createdAt: Date.now(),
      expiresAt: Date.now() + 24 * 60 * 60 * 1000,
      viewers: [],
      privacy: "contacts",
    };
    addStatus(newStatus);
    setSubPanel({ type: "none" });
  }

  return (
    <div className="flex flex-col h-full px-6 py-4" style={{ background: "var(--neu-bg)" }}>
      <header className="flex items-center justify-between mb-4">
        <h1 className="text-xl font-bold neu-text">New status</h1>
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
          <Type size={16} /> Text
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
        className="aspect-square rounded-3xl flex items-center justify-center p-8 mb-4"
        style={{ background: type === "text" ? bgColor : "linear-gradient(135deg, #667eea 0%, #764ba2 100%)" }}
      >
        {type === "image" ? (
          <div className="text-center text-white/80">
            <ImageIcon size={48} className="mx-auto opacity-50" />
            <div className="mt-2 text-xs">Photo placeholder</div>
          </div>
        ) : (
          <textarea
            value={text}
            onChange={(e) => setText(e.target.value)}
            placeholder="Type a status…"
            className="w-full bg-transparent outline-none border-none text-white text-2xl font-bold text-center resize-none placeholder:text-white/50"
            rows={5}
          />
        )}
      </div>

      {/* Color picker */}
      {type === "text" && (
        <div className="flex gap-2 mb-4 overflow-x-auto no-scrollbar">
          {STATUS_COLORS.map((c) => (
            <button
              key={c}
              onClick={() => setBgColor(c)}
              className={`w-10 h-10 rounded-full shrink-0 transition-all ${bgColor === c ? "ring-2 ring-offset-2 ring-offset-[var(--neu-bg)]" : ""}`}
              style={{ background: c, boxShadow: bgCol(c) === c ? `0 0 0 2px ${c}` : "none" }}
            />
          ))}
        </div>
      )}

      {type === "image" && (
        <input
          value={text}
          onChange={(e) => setText(e.target.value)}
          placeholder="Add a caption…"
          className="neu-well rounded-2xl px-4 py-3 text-sm neu-text outline-none border-none mb-4"
        />
      )}

      <div className="flex-1" />

      <NeuButton variant="accent" size="lg" fullWidth rounded="xl" onClick={handlePost}>
        Post status
      </NeuButton>
      <p className="text-[10px] neu-text-muted text-center mt-2">
        Status auto-deletes after 24 hours
      </p>
    </div>
  );
}

function bgCol(c: string) { return c; }
