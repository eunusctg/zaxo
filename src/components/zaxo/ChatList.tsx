// ==================== CHAT LIST ====================
"use client";

import { useEffect, useMemo, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Search, MessageSquarePlus, Archive, Pin, BellOff, Users, MoreVertical, Check, CheckCheck, Bell, BellRing, X, Phone, Video, MessageCircle } from "lucide-react";
import { NeuButton, NeuInput } from "@/components/neumorphic";
import { NeuAvatar } from "@/components/neumorphic/NeuAvatar";
import { useAppStore } from "@/store/appStore";
import { useUIStore } from "@/store/uiStore";
import { useAuthStore } from "@/store/authStore";
import { formatTime, formatDuration, getContactById, relativeTime } from "@/lib/zaxo/mockData";
import { notifications } from "@/lib/zaxo/notifications";
import type { Chat } from "@/types";

export function ChatList() {
  const { chats, contacts } = useAppStore();
  const { showSearch, searchQuery, setShowSearch, setSubPanel, setSubPanel: sp } = useUIStore();
  const [menuOpenFor, setMenuOpenFor] = useState<string | null>(null);
  const [showNotifPanel, setShowNotifPanel] = useState(false);
  const [notifQueue, setNotifQueue] = useState<Array<{ id: string; category: string; title: string; body: string; timestamp: number; chatId?: string }>>([]);
  const [notifPermission, setNotifPermission] = useState<NotificationPermission>("default");

  // Real cross-tab messages now flow via the realtime service in appStore.initRealtime().
  // No more ambient simulated messages — open this app in two browser tabs to test
  // real-time chat between them (each tab acts as a separate "device").

  // Subscribe to in-app notification queue
  useEffect(() => {
    const unsub = notifications.subscribeInApp((queue) => {
      setNotifQueue(queue);
    });
    setNotifPermission(notifications.getPermission());
    return () => unsub();
  }, []);

  async function handleBellClick() {
    if (notifications.getPermission() === "default") {
      const p = await notifications.requestPermission();
      setNotifPermission(p);
    }
    setShowNotifPanel(!showNotifPanel);
  }

  const visibleChats = useMemo(() => {
    return chats
      .filter((c) => !c.isArchived)
      .filter((c) => {
        if (!showSearch || !searchQuery) return true;
        const other = c.type === "individual" ? getContactById(c.participantIds[0], contacts) : null;
        const q = searchQuery.toLowerCase();
        const name = c.type === "group" ? c.name || "" : other?.displayName || "";
        const zaxo = other?.zaxoNumber || "";
        const last = c.lastMessage?.text || "";
        return (
          name.toLowerCase().includes(q) ||
          zaxo.toLowerCase().includes(q) ||
          last.toLowerCase().includes(q)
        );
      })
      .sort((a, b) => {
        if (a.isPinned !== b.isPinned) return a.isPinned ? -1 : 1;
        return (b.updatedAt || 0) - (a.updatedAt || 0);
      });
  }, [chats, contacts, showSearch, searchQuery]);

  const archivedCount = chats.filter((c) => c.isArchived).length;

  return (
    <div className="flex flex-col h-full w-full" style={{ background: "var(--neu-bg)" }}>
      {/* Header */}
      <header className="px-3 sm:px-4 pt-4 pb-2 flex items-center justify-between gap-2">
        <h1 className="text-xl sm:text-2xl font-bold neu-text">Chats</h1>
        <div className="flex items-center gap-2">
          <button
            onClick={handleBellClick}
            className="neu-pressable rounded-full w-10 h-10 flex items-center justify-center neu-text relative"
            aria-label="Notifications"
          >
            {notifQueue.length > 0 ? <BellRing size={18} className="neu-text-accent" /> : <Bell size={18} />}
            {notifQueue.length > 0 && (
              <span className="absolute -top-1 -right-1 bg-red-500 text-white text-[9px] font-bold rounded-full w-4 h-4 flex items-center justify-center">
                {notifQueue.length > 9 ? "9+" : notifQueue.length}
              </span>
            )}
          </button>
          <button
            onClick={() => setShowSearch(!showSearch)}
            className="neu-pressable rounded-full w-10 h-10 flex items-center justify-center neu-text"
            aria-label="Search"
          >
            <Search size={18} />
          </button>
          <button
            onClick={() => sp({ type: "new_chat" })}
            className="neu-pressable rounded-full w-10 h-10 flex items-center justify-center neu-text"
            aria-label="New chat"
          >
            <MessageSquarePlus size={18} />
          </button>
        </div>
      </header>

      {/* Notification panel */}
      <AnimatePresence>
        {showNotifPanel && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            className="px-3 sm:px-4 overflow-hidden"
          >
            <div className="neu-raised-sm rounded-2xl p-3">
              <div className="flex items-center justify-between mb-2">
                <div className="text-xs font-semibold neu-text-muted uppercase tracking-wider">Notifications</div>
                <div className="flex items-center gap-2">
                  {notifPermission !== "granted" && (
                    <button
                      onClick={async () => {
                        const p = await notifications.requestPermission();
                        setNotifPermission(p);
                      }}
                      className="text-[10px] neu-text-accent font-medium px-2 py-1 rounded-full neu-inset"
                    >
                      Enable system alerts
                    </button>
                  )}
                  {notifQueue.length > 0 && (
                    <button
                      onClick={() => notifications.clearInApp()}
                      className="text-[10px] neu-text-muted hover:neu-text-danger"
                    >
                      Clear all
                    </button>
                  )}
                </div>
              </div>
              {notifQueue.length === 0 ? (
                <div className="text-xs neu-text-muted py-4 text-center">No notifications yet</div>
              ) : (
                <div className="space-y-1 max-h-64 overflow-y-auto neu-scroll">
                  {notifQueue.slice(0, 10).map((n) => (
                    <button
                      key={n.id}
                      onClick={() => {
                        if (n.chatId) setSubPanel({ type: "chat_room", chatId: n.chatId });
                        notifications.dismissInApp(n.id);
                        setShowNotifPanel(false);
                      }}
                      className="w-full flex items-start gap-2 px-2 py-2 rounded-xl hover:bg-[color:var(--neu-shadow-light)]/5 text-left"
                    >
                      <div className="w-8 h-8 rounded-full neu-inset flex items-center justify-center flex-shrink-0">
                        {n.category === "call_incoming" || n.category === "call_group" || n.category === "call_missed" ? (
                          <Phone size={14} className="neu-text-accent" />
                        ) : n.category === "status" ? (
                          <MessageCircle size={14} className="neu-text-accent" />
                        ) : (
                          <MessageCircle size={14} className="neu-text-accent" />
                        )}
                      </div>
                      <div className="flex-1 min-w-0">
                        <div className="text-xs font-medium neu-text truncate">{n.title}</div>
                        <div className="text-[11px] neu-text-muted truncate">{n.body}</div>
                        <div className="text-[10px] neu-text-muted opacity-60 mt-0.5">{relativeTime(n.timestamp)}</div>
                      </div>
                      <button
                        onClick={(e) => { e.stopPropagation(); notifications.dismissInApp(n.id); }}
                        className="neu-text-muted hover:neu-text-danger p-1"
                        aria-label="Dismiss"
                      >
                        <X size={12} />
                      </button>
                    </button>
                  ))}
                </div>
              )}
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Search bar */}
      <AnimatePresence>
        {showSearch && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            className="px-4 overflow-hidden"
          >
            <NeuInput
              autoFocus
              placeholder="Search by name, Zaxo number, or message"
              value={searchQuery}
              onChange={(e) => useUIStore.getState().setSearchQuery(e.target.value)}
              showClear
              onClear={() => useUIStore.getState().setSearchQuery("")}
              icon={<Search size={16} />}
            />
          </motion.div>
        )}
      </AnimatePresence>

      {/* Archived row */}
      {archivedCount > 0 && !showSearch && (
        <button
          className="mx-4 mt-2 neu-raised-sm rounded-2xl px-4 py-3 flex items-center gap-3"
          // could open archived list - simplified here
        >
          <div className="neu-inset rounded-xl w-10 h-10 flex items-center justify-center neu-text-muted">
            <Archive size={18} />
          </div>
          <div className="flex-1 text-left">
            <div className="text-sm font-medium neu-text">Archived</div>
            <div className="text-xs neu-text-muted">{archivedCount} chat{archivedCount > 1 ? "s" : ""}</div>
          </div>
        </button>
      )}

      {/* Chat list */}
      <div className="flex-1 overflow-y-auto neu-scroll px-2 pt-2">
        {visibleChats.length === 0 ? (
          <EmptyChatsState />
        ) : (
          visibleChats.map((chat) => (
            <ChatListItem key={chat.id} chat={chat} menuOpen={menuOpenFor === chat.id} onMenuToggle={() => setMenuOpenFor(menuOpenFor === chat.id ? null : chat.id)} />
          ))
        )}
        <div className="h-4" />
      </div>

      {/* FAB */}
      <button
        onClick={() => sp({ type: "new_chat" })}
        className="absolute bottom-24 right-5 neu-accent w-14 h-14 rounded-full flex items-center justify-center z-20"
        aria-label="New chat"
        style={{ boxShadow: "4px 4px 12px var(--neu-shadow-dark), -4px -4px 12px var(--neu-shadow-light), inset 1px 1px 0 rgba(255,255,255,0.2)" }}
      >
        <MessageSquarePlus size={24} />
      </button>
    </div>
  );
}

function ChatListItem({ chat, menuOpen, onMenuToggle }: { chat: Chat; menuOpen: boolean; onMenuToggle: () => void }) {
  const { contacts } = useAppStore();
  const { setSubPanel } = useUIStore();
  const { user } = useAuthStore();
  const other = chat.type === "individual" ? getContactById(chat.participantIds[0], contacts) : null;

  const name = chat.type === "group" ? chat.name || "Group" : other?.displayName || "Unknown";
  const avatarInitial = chat.type === "group" ? chat.avatarInitial || "G" : other?.avatarInitial || "?";
  const avatarGradient = chat.type === "group" ? chat.avatarColor || "" : other?.avatarColor || "";
  const online = chat.type === "individual" && other?.online;

  const lastMsg = chat.lastMessage;
  const isMine = lastMsg?.senderId === "me";

  function previewText(): string {
    if (!lastMsg) return "Tap to start chatting";
    if (lastMsg.deletedForEveryone) return "🚫 This message was deleted";
    if (lastMsg.type === "system") return lastMsg.text || "";
    if (lastMsg.type === "image") return "📸 Photo";
    if (lastMsg.type === "video") return "🎥 Video";
    if (lastMsg.type === "voice") return `🎤 Voice message (${formatDuration(lastMsg.duration || 0)})`;
    if (lastMsg.type === "document") return `📄 ${lastMsg.mediaName || "Document"}`;
    if (lastMsg.type === "location") return "📍 Location";
    if (lastMsg.type === "contact") return "👤 Contact card";
    if (lastMsg.type === "sticker") return "🎨 Sticker";
    const senderPrefix = chat.type === "group" && !isMine && lastMsg.senderId !== "me"
      ? `${getContactById(lastMsg.senderId, contacts)?.displayName.split(" ")[0] || "Someone"}: `
      : isMine
        ? "You: "
        : "";
    return senderPrefix + (lastMsg.text || "");
  }

  return (
    <div className="relative">
      <div
        role="button"
        tabIndex={0}
        onClick={() => setSubPanel({ type: "chat_room", chatId: chat.id })}
        onKeyDown={(e) => { if (e.key === "Enter" || e.key === " ") { e.preventDefault(); setSubPanel({ type: "chat_room", chatId: chat.id }); } }}
        className="w-full flex items-center gap-3 px-3 py-3 rounded-2xl hover:bg-[color:var(--neu-shadow-light)]/5 transition-all active:scale-[0.99] cursor-pointer"
      >
        <NeuAvatar
          initial={avatarInitial}
          gradient={avatarGradient}
          size={50}
          online={online}
        />
        <div className="flex-1 min-w-0 text-left">
          <div className="flex items-center justify-between gap-2">
            <div className="flex items-center gap-1.5 min-w-0">
              <span className="font-semibold text-sm neu-text truncate">{name}</span>
              {chat.isMuted && <BellOff size={12} className="neu-text-muted shrink-0" />}
            </div>
            <span className={`text-[11px] shrink-0 ${chat.unreadCount > 0 ? "neu-text-accent font-medium" : "neu-text-muted"}`}>
              {lastMsg ? formatTime(lastMsg.timestamp) : ""}
            </span>
          </div>
          <div className="flex items-center justify-between gap-2 mt-0.5">
            <div className="flex items-center gap-1 min-w-0 flex-1">
              {isMine && lastMsg && lastMsg.type !== "system" && (
                <MessageStatus status={lastMsg.status} />
              )}
              {chat.typingUserIds.length > 0 ? (
                <span className="text-xs neu-text-accent truncate flex items-center gap-1">
                  typing
                  <span className="flex gap-0.5">
                    <span className="typing-dot inline-block w-1 h-1 rounded-full neu-text-accent" />
                    <span className="typing-dot inline-block w-1 h-1 rounded-full neu-text-accent" />
                    <span className="typing-dot inline-block w-1 h-1 rounded-full neu-text-accent" />
                  </span>
                </span>
              ) : (
                <span className="text-xs neu-text-muted truncate">{previewText()}</span>
              )}
            </div>
            <div className="flex items-center gap-1.5 shrink-0">
              {chat.isPinned && <Pin size={12} className="neu-text-muted" />}
              {chat.unreadCount > 0 && (
                <div className="min-w-[20px] h-[20px] px-1.5 rounded-full neu-accent flex items-center justify-center text-[10px] font-bold text-white">
                  {chat.unreadCount > 9 ? "9+" : chat.unreadCount}
                </div>
              )}
              <button
                onClick={(e) => { e.stopPropagation(); onMenuToggle(); }}
                className="neu-text-muted hover:neu-text p-1"
              >
                <MoreVertical size={14} />
              </button>
            </div>
          </div>
        </div>
      </div>

      <AnimatePresence>
        {menuOpen && (
          <motion.div
            initial={{ opacity: 0, y: -4 }}
            animate={{ opacity: 1, y: 0 }}
            exit={{ opacity: 0, y: -4 }}
            className="absolute right-3 top-16 z-30 neu-raised rounded-2xl py-2 min-w-[160px]"
          >
            <MenuButton icon={<Pin size={14} />} label={chat.isPinned ? "Unpin chat" : "Pin chat"} onClick={() => { useAppStore.getState().togglePinChat(chat.id); onMenuToggle(); }} />
            <MenuButton icon={<BellOff size={14} />} label={chat.isMuted ? "Unmute" : "Mute"} onClick={() => { useAppStore.getState().toggleMuteChat(chat.id); onMenuToggle(); }} />
            <MenuButton icon={<Archive size={14} />} label="Archive" onClick={() => { useAppStore.getState().toggleArchiveChat(chat.id); onMenuToggle(); }} />
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

function MenuButton({ icon, label, onClick }: { icon: React.ReactNode; label: string; onClick: () => void }) {
  return (
    <button
      onClick={onClick}
      className="w-full px-4 py-2 flex items-center gap-3 text-sm neu-text hover:opacity-70 transition-opacity"
    >
      {icon}
      {label}
    </button>
  );
}

function MessageStatus({ status }: { status: string }) {
  if (status === "sending") return <Clock size={12} className="neu-text-muted shrink-0" />;
  if (status === "sent") return <Check size={12} className="neu-text-muted shrink-0" />;
  if (status === "delivered") return <CheckCheck size={12} className="neu-text-muted shrink-0" />;
  if (status === "read") return <CheckCheck size={12} className="shrink-0" style={{ color: "#4FA3FF" }} />;
  return null;
}

function Clock({ size, className }: { size: number; className?: string }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" className={className}>
      <circle cx="12" cy="12" r="9" stroke="currentColor" strokeWidth="2" />
      <path d="M12 7v5l3 2" stroke="currentColor" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
    </svg>
  );
}

function EmptyChatsState() {
  const { setSubPanel } = useUIStore();
  return (
    <div className="flex flex-col items-center justify-center h-full px-8 text-center py-20">
      <div className="neu-raised-lg rounded-3xl w-28 h-28 flex items-center justify-center mb-5">
        <MessageSquarePlus size={48} className="neu-text-accent" />
      </div>
      <h3 className="text-lg font-semibold neu-text">No chats yet</h3>
      <p className="text-sm neu-text-muted mt-2 max-w-xs">
        Start a conversation with someone using their Zaxo number, or invite a friend to join.
      </p>
      <NeuButton
        variant="accent"
        size="md"
        rounded="xl"
        className="mt-5"
        icon={<MessageSquarePlus size={16} />}
        onClick={() => setSubPanel({ type: "new_chat" })}
      >
        Start new chat
      </NeuButton>
    </div>
  );
}
