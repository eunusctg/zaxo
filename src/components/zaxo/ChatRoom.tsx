// ==================== CHAT ROOM ====================
"use client";

import { useEffect, useRef, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  ChevronLeft, Phone, Video, MoreVertical, Smile, Paperclip,
  Mic, Send, Camera, FileText, MapPin, User, X, Reply, Star,
  Trash2, Copy, Forward, Pencil, Check, CheckCheck, Play, Pause,
  Download, File,
} from "lucide-react";
import { NeuAvatar } from "@/components/neumorphic/NeuAvatar";
import { NeuButton } from "@/components/neumorphic/NeuButton";
import { useAppStore } from "@/store/appStore";
import { useUIStore } from "@/store/uiStore";
import { useAuthStore } from "@/store/authStore";
import { formatTime, formatDateSeparator, getContactById } from "@/lib/zaxo/mockData";
import type { Message, Chat } from "@/types";

const QUICK_EMOJIS = ["👍", "❤️", "😂", "😮", "😢", "😡", "🙏", "🔥"];

export function ChatRoom({ chatId }: { chatId: string }) {
  const { chats, contacts, messages, sendMessage, markChatRead, setTyping, toggleReaction } = useAppStore();
  const { setSubPanel } = useUIStore();
  const { user } = useAuthStore();
  const [draft, setDraft] = useState("");
  const [showEmoji, setShowEmoji] = useState(false);
  const [showAttach, setShowAttach] = useState(false);
  const [recording, setRecording] = useState(false);
  const [recordSeconds, setRecordSeconds] = useState(0);
  const [replyTo, setReplyTo] = useState<Message | null>(null);
  const [activeMessage, setActiveMessage] = useState<Message | null>(null);
  const [showReactionPicker, setShowReactionPicker] = useState<string | null>(null);

  const chat = chats.find((c) => c.id === chatId);
  const chatMessages = messages[chatId] || [];
  const scrollRef = useRef<HTMLDivElement>(null);

  // Mark as read on open
  useEffect(() => {
    markChatRead(chatId);
  }, [chatId, markChatRead]);

  // Simulate other user typing then responding
  const otherTyping = chat?.typingUserIds.length || 0;

  // Auto-scroll to bottom
  useEffect(() => {
    if (scrollRef.current) {
      scrollRef.current.scrollTop = scrollRef.current.scrollHeight;
    }
  }, [chatMessages.length, otherTyping]);

  // Recording timer
  useEffect(() => {
    if (recording) {
      const interval = setInterval(() => setRecordSeconds((s) => s + 1), 1000);
      return () => clearInterval(interval);
    } else {
      setRecordSeconds(0);
    }
  }, [recording]);

  if (!chat) {
    return (
      <div className="flex items-center justify-center h-full neu-text-muted">
        Chat not found
      </div>
    );
  }

  const other = chat.type === "individual" ? getContactById(chat.participantIds[0], contacts) : null;
  const name = chat.type === "group" ? chat.name || "Group" : other?.displayName || "Unknown";
  const subtitle = chat.type === "group"
    ? `${chat.participantIds.length + 1} members`
    : other?.online ? "online" : other ? `last seen ${relativeShort(other.lastSeen)}` : "";
  const avatarInitial = chat.type === "group" ? chat.avatarInitial || "G" : other?.avatarInitial || "?";
  const avatarGradient = chat.type === "group" ? chat.avatarColor || "" : other?.avatarColor || "";

  function handleSend() {
    if (!draft.trim()) return;
    sendMessage(chatId, draft.trim());
    setDraft("");
    setReplyTo(null);
    // Simulate a reply for individual chats
    if (chat?.type === "individual") {
      const otherId = chat.participantIds[0];
      setTimeout(() => {
        setTyping(chatId, [otherId]);
        setTimeout(() => {
          setTyping(chatId, []);
          const replies = ["Got it! 👍", "Haha nice", "Sounds good", "Talk soon!", "👀", "Will do!", "Perfect!"];
          const reply = replies[Math.floor(Math.random() * replies.length)];
          // Use store directly to send from other user
          useAppStore.setState((state) => {
            const newMsg: Message = {
              id: `m_${Date.now()}_other`,
              chatId,
              senderId: otherId,
              type: "text",
              text: reply,
              timestamp: Date.now(),
              status: "delivered",
              reactions: {},
              disappearing: "off",
            };
            return {
              messages: {
                ...state.messages,
                [chatId]: [...(state.messages[chatId] || []), newMsg],
              },
              chats: state.chats.map((c) =>
                c.id === chatId ? { ...c, lastMessage: newMsg, updatedAt: newMsg.timestamp } : c,
              ),
            };
          });
        }, 1500);
      }, 800);
    }
  }

  function handleVoiceSend() {
    if (recordSeconds < 1) return;
    sendMessage(chatId, "", "voice", { duration: recordSeconds });
    setRecording(false);
  }

  // Group messages by day
  const grouped = (() => {
    const groups: { date: string; items: Message[] }[] = [];
    chatMessages.forEach((m) => {
      const d = formatDateSeparator(m.timestamp);
      const last = groups[groups.length - 1];
      if (last && last.date === d) {
        last.items.push(m);
      } else {
        groups.push({ date: d, items: [m] });
      }
    });
    return groups;
  })();

  return (
    <div className="flex flex-col h-full" style={{ background: "var(--neu-bg)" }}>
      {/* Header */}
      <header className="px-3 pt-4 pb-3 flex items-center gap-2 neu-raised-sm rounded-b-3xl">
        <button onClick={() => setSubPanel({ type: "none" })} className="neu-text p-1">
          <ChevronLeft size={24} />
        </button>
        <button
          onClick={() => setSubPanel({ type: chat.type === "group" ? "group_info" : "chat_info", chatId })}
          className="flex items-center gap-3 flex-1 min-w-0"
        >
          <NeuAvatar initial={avatarInitial} gradient={avatarGradient} size={40} online={other?.online} />
          <div className="text-left min-w-0">
            <div className="font-semibold text-sm neu-text truncate">{name}</div>
            <div className="text-xs neu-text-muted truncate">
              {otherTyping > 0 ? (
                <span className="neu-text-accent">typing…</span>
              ) : subtitle}
            </div>
          </div>
        </button>
        <button onClick={() => setSubPanel({ type: "call_screen", otherUserId: chat.type === "individual" ? chat.participantIds[0] : "", callType: "voice" })} className="neu-pressable rounded-full w-10 h-10 flex items-center justify-center neu-text">
          <Phone size={18} />
        </button>
        <button onClick={() => setSubPanel({ type: "call_screen", otherUserId: chat.type === "individual" ? chat.participantIds[0] : "", callType: "video" })} className="neu-pressable rounded-full w-10 h-10 flex items-center justify-center neu-text">
          <Video size={18} />
        </button>
        <button className="neu-pressable rounded-full w-10 h-10 flex items-center justify-center neu-text">
          <MoreVertical size={18} />
        </button>
      </header>

      {/* Messages */}
      <div ref={scrollRef} className="flex-1 overflow-y-auto neu-scroll px-3 py-4">
        {chatMessages.length === 0 && (
          <div className="flex flex-col items-center justify-center h-full text-center px-8">
            <div className="neu-raised-sm rounded-2xl px-5 py-4 text-xs neu-text-muted max-w-xs">
              🔒 Messages are end-to-end encrypted. No one outside this chat can read them.
            </div>
          </div>
        )}
        {grouped.map((group) => (
          <div key={group.date}>
            <div className="flex justify-center my-3">
              <div className="neu-raised-sm rounded-full px-3 py-1 text-[10px] neu-text-muted font-medium">
                {group.date}
              </div>
            </div>
            {group.items.map((msg, i) => {
              const isMine = msg.senderId === "me";
              const prev = group.items[i - 1];
              const showAvatar = chat.type === "group" && !isMine && (!prev || prev.senderId !== msg.senderId);
              return (
                <MessageBubble
                  key={msg.id}
                  msg={msg}
                  isMine={isMine}
                  chat={chat}
                  showAvatar={showAvatar}
                  onReply={() => setReplyTo(msg)}
                  onReact={() => setShowReactionPicker(showReactionPicker === msg.id ? null : msg.id)}
                  onLongPress={() => setActiveMessage(msg)}
                  reactionPickerOpen={showReactionPicker === msg.id}
                  onReactionPick={(emoji) => {
                    toggleReaction(chatId, msg.id, emoji, user?.id || "me");
                    setShowReactionPicker(null);
                  }}
                />
              );
            })}
          </div>
        ))}
        {otherTyping > 0 && (
          <div className="flex items-center gap-2 mt-1 mb-3">
            {chat.type === "group" && <NeuAvatar initial={other?.avatarInitial || "?"} gradient={other?.avatarColor || ""} size={28} />}
            <div className="neu-raised-sm rounded-2xl rounded-bl-md px-4 py-3 flex items-center gap-1">
              <span className="typing-dot w-1.5 h-1.5 rounded-full neu-text-muted" />
              <span className="typing-dot w-1.5 h-1.5 rounded-full neu-text-muted" />
              <span className="typing-dot w-1.5 h-1.5 rounded-full neu-text-muted" />
            </div>
          </div>
        )}
        <div className="h-2" />
      </div>

      {/* Reply preview */}
      <AnimatePresence>
        {replyTo && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            className="px-3 overflow-hidden"
          >
            <div className="neu-inset rounded-xl px-3 py-2 flex items-center gap-2">
              <Reply size={14} className="neu-text-accent" />
              <div className="flex-1 min-w-0">
                <div className="text-xs font-medium neu-text-accent">
                  Replying to {replyTo.senderId === "me" ? "yourself" : name.split(" ")[0]}
                </div>
                <div className="text-xs neu-text-muted truncate">
                  {replyTo.text || `[${replyTo.type}]`}
                </div>
              </div>
              <button onClick={() => setReplyTo(null)} className="neu-text-muted">
                <X size={16} />
              </button>
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Attachment panel */}
      <AnimatePresence>
        {showAttach && (
          <motion.div
            initial={{ height: 0, opacity: 0 }}
            animate={{ height: "auto", opacity: 1 }}
            exit={{ height: 0, opacity: 0 }}
            className="px-4 overflow-hidden"
          >
            <div className="grid grid-cols-4 gap-3 py-3">
              <AttachOption icon={<Camera size={22} />} label="Camera" color="#FF6B6B" onClick={() => { sendMessage(chatId, "📸 Photo captured", "image", { mediaName: "photo.jpg" }); setShowAttach(false); }} />
              <AttachOption icon={<FileText size={22} />} label="Document" color="#6C5CE7" onClick={() => { sendMessage(chatId, "", "document", { mediaName: "document.pdf", mediaSize: 245000 }); setShowAttach(false); }} />
              <AttachOption icon={<MapPin size={22} />} label="Location" color="#00B894" onClick={() => { sendMessage(chatId, "", "location", { location: { lat: 3.139, lng: 101.6869, label: "Kuala Lumpur" } }); setShowAttach(false); }} />
              <AttachOption icon={<User size={22} />} label="Contact" color="#FECA57" onClick={() => { sendMessage(chatId, "", "contact", { contactCard: { name: "Alex Rivera", zaxoNumber: "246-810-935" } }); setShowAttach(false); }} />
            </div>
          </motion.div>
        )}
      </AnimatePresence>

      {/* Input bar */}
      <div className="px-3 pb-3 pt-2">
        {recording ? (
          <div className="neu-raised-sm rounded-2xl px-4 py-3 flex items-center gap-3">
            <div className="w-3 h-3 rounded-full" style={{ background: "var(--neu-danger)" }} />
            <span className="text-sm neu-text font-mono">
              {Math.floor(recordSeconds / 60)}:{(recordSeconds % 60).toString().padStart(2, "0")}
            </span>
            <div className="flex-1 h-6 flex items-center">
              {/* Fake waveform */}
              {Array.from({ length: 30 }).map((_, i) => (
                <span
                  key={i}
                  className="waveform-bar"
                  style={{ height: `${20 + Math.sin(i * 1.7 + recordSeconds) * 12 + Math.random() * 8}%` }}
                />
              ))}
            </div>
            <button onClick={() => setRecording(false)} className="neu-text-muted">
              <X size={20} />
            </button>
            <button onClick={handleVoiceSend} className="neu-accent rounded-full w-10 h-10 flex items-center justify-center">
              <Send size={16} />
            </button>
          </div>
        ) : (
          <div className="flex items-end gap-2">
            <div className="flex-1 neu-raised-sm rounded-2xl px-3 py-2 flex items-end gap-2">
              <button
                onClick={() => { setShowEmoji(!showEmoji); setShowAttach(false); }}
                className="neu-text-muted hover:neu-text-accent p-1.5 shrink-0"
              >
                <Smile size={20} />
              </button>
              <textarea
                value={draft}
                onChange={(e) => setDraft(e.target.value)}
                onKeyDown={(e) => {
                  if (e.key === "Enter" && !e.shiftKey) {
                    e.preventDefault();
                    handleSend();
                  }
                }}
                placeholder="Message"
                rows={1}
                className="flex-1 bg-transparent outline-none border-none text-sm neu-text placeholder:text-[color:var(--neu-text-muted)] resize-none max-h-24 py-1.5"
                style={{ minHeight: 24 }}
              />
              <button
                onClick={() => { setShowAttach(!showAttach); setShowEmoji(false); }}
                className="neu-text-muted hover:neu-text-accent p-1.5 shrink-0"
              >
                <Paperclip size={20} />
              </button>
              <button className="neu-text-muted hover:neu-text-accent p-1.5 shrink-0">
                <Camera size={20} />
              </button>
            </div>
            <button
              onClick={() => { if (draft.trim()) handleSend(); else setRecording(true); }}
              className="neu-accent rounded-full w-12 h-12 flex items-center justify-center shrink-0"
              aria-label={draft.trim() ? "Send" : "Record voice message"}
            >
              {draft.trim() ? <Send size={20} /> : <Mic size={20} />}
            </button>
          </div>
        )}

        {/* Quick emoji */}
        <AnimatePresence>
          {showEmoji && (
            <motion.div
              initial={{ opacity: 0, y: 8 }}
              animate={{ opacity: 1, y: 0 }}
              exit={{ opacity: 0, y: 8 }}
              className="mt-2 neu-raised-sm rounded-2xl p-3 grid grid-cols-8 gap-1"
            >
              {["😀","😂","😍","🥰","😘","😎","🤔","😴","🙄","😡","😭","🥺","😱","🤯","🤩","😈","👍","👎","👏","🙌","🙏","💪","🔥","✨","❤️","💔","💯","🎉","🎂","🍕","☕","🌈"].map((e) => (
                <button
                  key={e}
                  onClick={() => setDraft(draft + e)}
                  className="text-xl p-1.5 rounded-lg hover:neu-inset transition-all"
                >
                  {e}
                </button>
              ))}
            </motion.div>
          )}
        </AnimatePresence>
      </div>

      {/* Message action sheet */}
      <AnimatePresence>
        {activeMessage && (
          <MessageActionSheet
            msg={activeMessage}
            chat={chat}
            onClose={() => setActiveMessage(null)}
            onReply={() => { setReplyTo(activeMessage); setActiveMessage(null); }}
          />
        )}
      </AnimatePresence>
    </div>
  );
}

function MessageBubble({
  msg, isMine, chat, showAvatar, onReply, onReact, onLongPress, reactionPickerOpen, onReactionPick,
}: {
  msg: Message;
  isMine: boolean;
  chat: Chat;
  showAvatar: boolean;
  onReply: () => void;
  onReact: () => void;
  onLongPress: () => void;
  reactionPickerOpen: boolean;
  onReactionPick: (e: string) => void;
}) {
  const { contacts } = useAppStore();
  const sender = msg.senderId === "me" ? null : getContactById(msg.senderId, contacts);
  const longPressTimer = useRef<ReturnType<typeof setTimeout> | null>(null);

  function handlePressStart() {
    longPressTimer.current = setTimeout(() => onLongPress(), 500);
  }
  function handlePressEnd() {
    if (longPressTimer.current) clearTimeout(longPressTimer.current);
  }

  if (msg.type === "system") {
    return (
      <div className="flex justify-center my-2">
        <div className="neu-raised-sm rounded-full px-3 py-1 text-[11px] neu-text-muted">
          {msg.text}
        </div>
      </div>
    );
  }

  const reactions = Object.entries(msg.reactions);
  const reactionGroups: { [emoji: string]: number } = {};
  reactions.forEach(([, emoji]) => {
    reactionGroups[emoji] = (reactionGroups[emoji] || 0) + 1;
  });

  return (
    <div className={`flex items-end gap-2 mb-1.5 ${isMine ? "justify-end" : "justify-start"}`}>
      {showAvatar && sender && (
        <NeuAvatar initial={sender.avatarInitial} gradient={sender.avatarColor} size={28} />
      )}
      {!showAvatar && !isMine && <div style={{ width: 28 }} />}
      <div className={`relative max-w-[78%] ${isMine ? "items-end" : "items-start"}`}>
        {showAvatar && chat.type === "group" && sender && (
          <div className="text-[11px] font-medium neu-text-accent mb-0.5 ml-1">
            {sender.displayName}
          </div>
        )}
        <div
          onPointerDown={handlePressStart}
          onPointerUp={handlePressEnd}
          onPointerLeave={handlePressEnd}
          onClick={() => reactionPickerOpen && onReact()}
          className={`px-3.5 py-2 text-sm cursor-pointer transition-all active:scale-[0.98] ${
            isMine
              ? "neu-accent text-white"
              : "neu-raised-sm neu-text"
          }`}
          style={{
            borderRadius: isMine
              ? "18px 18px 4px 18px"
              : "18px 18px 18px 4px",
          }}
        >
          {msg.deletedForEveryone ? (
            <span className="italic opacity-70 text-xs">🚫 This message was deleted</span>
          ) : (
            <MessageContent msg={msg} isMine={isMine} />
          )}
          <div className={`flex items-center gap-1 mt-1 ${isMine ? "justify-end" : "justify-start"}`}>
            <span className={`text-[10px] ${isMine ? "text-white/70" : "neu-text-muted"}`}>
              {formatTime(msg.timestamp)}
              {msg.edited && <span className="ml-1">· edited</span>}
            </span>
            {isMine && !msg.deletedForEveryone && <MessageStatus status={msg.status} mine />}
          </div>
        </div>

        {/* Reaction picker */}
        {reactionPickerOpen && (
          <motion.div
            initial={{ opacity: 0, y: 4, scale: 0.95 }}
            animate={{ opacity: 1, y: 0, scale: 1 }}
            className={`absolute z-30 ${isMine ? "right-0" : "left-8"} -top-12 neu-raised rounded-full px-2 py-1.5 flex gap-1`}
          >
            {QUICK_EMOJIS.map((e) => (
              <button
                key={e}
                onClick={(ev) => { ev.stopPropagation(); onReactionPick(e); }}
                className="text-xl hover:scale-125 transition-transform p-1"
              >
                {e}
              </button>
            ))}
          </motion.div>
        )}

        {/* Reactions */}
        {Object.keys(reactionGroups).length > 0 && (
          <div className={`flex gap-1 mt-1 ${isMine ? "justify-end" : "justify-start"}`}>
            {Object.entries(reactionGroups).map(([emoji, count]) => (
              <div key={emoji} className="neu-raised-sm rounded-full px-2 py-0.5 text-xs flex items-center gap-1">
                <span>{emoji}</span>
                {count > 1 && <span className="neu-text-muted text-[10px]">{count}</span>}
              </div>
            ))}
          </div>
        )}

        {/* Quick action bar */}
        <div className={`absolute top-0 ${isMine ? "right-full mr-1" : "left-full ml-1"} opacity-0 hover:opacity-100 transition-opacity flex gap-0.5`}>
          <button onClick={onReact} className="neu-raised-sm rounded-full w-7 h-7 flex items-center justify-center neu-text-muted hover:neu-text-accent">
            <Smile size={14} />
          </button>
          <button onClick={onReply} className="neu-raised-sm rounded-full w-7 h-7 flex items-center justify-center neu-text-muted hover:neu-text-accent">
            <Reply size={14} />
          </button>
        </div>
      </div>
    </div>
  );
}

function MessageContent({ msg, isMine }: { msg: Message; isMine: boolean }) {
  if (msg.type === "text") {
    return <div className="whitespace-pre-wrap break-words">{msg.text}</div>;
  }
  if (msg.type === "image") {
    return (
      <div>
        <div
          className="rounded-xl mb-1 flex items-center justify-center text-3xl"
          style={{
            width: 200,
            height: 200,
            background: isMine ? "rgba(255,255,255,0.2)" : "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
          }}
        >
          🖼️
        </div>
        {msg.mediaName && <div className="text-[11px] opacity-70">{msg.mediaName}</div>}
      </div>
    );
  }
  if (msg.type === "voice") {
    return <VoiceMessagePlayer duration={msg.duration || 0} isMine={isMine} />;
  }
  if (msg.type === "video") {
    return (
      <div>
        <div
          className="rounded-xl mb-1 flex items-center justify-center text-3xl"
          style={{ width: 220, height: 140, background: "rgba(0,0,0,0.3)" }}
        >
          ▶️
        </div>
        <div className="text-[11px] opacity-70">🎥 Video</div>
      </div>
    );
  }
  if (msg.type === "document") {
    return (
      <div className="flex items-center gap-3 py-1 pr-3">
        <div className="w-11 h-11 rounded-xl flex items-center justify-center" style={{ background: isMine ? "rgba(255,255,255,0.25)" : "var(--neu-accent)" }}>
          <File size={22} className="text-white" />
        </div>
        <div>
          <div className="font-medium text-sm">{msg.mediaName || "Document"}</div>
          <div className="text-[11px] opacity-70">{(msg.mediaSize || 0) > 1024 * 1024 ? `${Math.round((msg.mediaSize || 0) / 1024 / 1024 * 10) / 10} MB` : `${Math.round((msg.mediaSize || 0) / 1024)} KB`}</div>
        </div>
        <Download size={16} className="opacity-70 ml-2" />
      </div>
    );
  }
  if (msg.type === "location") {
    return (
      <div>
        <div
          className="rounded-xl mb-1 flex items-center justify-center"
          style={{ width: 200, height: 130, background: "linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)" }}
        >
          <MapPin size={36} className="text-white" />
        </div>
        <div className="text-[11px] opacity-70">📍 {msg.location?.label || "Location"}</div>
      </div>
    );
  }
  if (msg.type === "contact") {
    return (
      <div className="flex items-center gap-3 py-1 pr-3">
        <div className="w-10 h-10 rounded-full flex items-center justify-center text-white" style={{ background: "linear-gradient(135deg, #f093fb 0%, #f5576c 100%)" }}>
          <User size={18} />
        </div>
        <div>
          <div className="font-medium text-sm">{msg.contactCard?.name}</div>
          <div className="text-[11px] opacity-70 font-mono">{msg.contactCard?.zaxoNumber}</div>
        </div>
      </div>
    );
  }
  if (msg.type === "sticker") {
    return <div className="text-5xl py-2">{msg.text}</div>;
  }
  return <div>{msg.text}</div>;
}

function VoiceMessagePlayer({ duration, isMine }: { duration: number; isMine: boolean }) {
  const [playing, setPlaying] = useState(false);
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    if (playing) {
      const interval = setInterval(() => {
        setProgress((p) => {
          if (p >= 100) {
            setPlaying(false);
            return 0;
          }
          return p + (100 / (duration * 10));
        });
      }, 100);
      return () => clearInterval(interval);
    }
  }, [playing, duration]);

  return (
    <div className="flex items-center gap-2 py-1 pr-3 min-w-[180px]">
      <button
        onClick={(e) => { e.stopPropagation(); setPlaying(!playing); }}
        className="w-9 h-9 rounded-full flex items-center justify-center shrink-0"
        style={{ background: isMine ? "rgba(255,255,255,0.25)" : "var(--neu-accent)" }}
      >
        {playing ? <Pause size={16} className="text-white" /> : <Play size={16} className="text-white ml-0.5" />}
      </button>
      <div className="flex-1 h-7 flex items-center">
        {Array.from({ length: 28 }).map((_, i) => {
          const filled = (i / 28) * 100 < progress;
          return (
            <span
              key={i}
              className="waveform-bar"
              style={{
                height: `${20 + Math.sin(i * 1.4) * 14 + Math.random() * 10}%`,
                background: filled ? (isMine ? "white" : "var(--neu-accent)") : (isMine ? "rgba(255,255,255,0.4)" : "var(--neu-text-muted)"),
              }}
            />
          );
        })}
      </div>
      <span className={`text-[11px] font-mono ${isMine ? "text-white/80" : "neu-text-muted"}`}>
        {Math.floor(duration / 60)}:{(duration % 60).toString().padStart(2, "0")}
      </span>
    </div>
  );
}

function MessageStatus({ status, mine }: { status: string; mine: boolean }) {
  if (status === "sending") return <span className="text-[10px] opacity-60">⌛</span>;
  if (status === "sent") return <Check size={12} className="opacity-70" />;
  if (status === "delivered") return <CheckCheck size={12} className="opacity-70" />;
  if (status === "read") return <CheckCheck size={12} style={{ color: "#4FA3FF" }} />;
  return null;
}

function AttachOption({ icon, label, color, onClick }: { icon: React.ReactNode; label: string; color: string; onClick: () => void }) {
  return (
    <button onClick={onClick} className="flex flex-col items-center gap-1.5">
      <div className="w-14 h-14 neu-raised-sm rounded-2xl flex items-center justify-center" style={{ color }}>
        {icon}
      </div>
      <span className="text-[11px] neu-text-muted">{label}</span>
    </button>
  );
}

function MessageActionSheet({ msg, chat, onClose, onReply }: { msg: Message; chat: Chat; onClose: () => void; onReply: () => void }) {
  const { toggleStarMessage, deleteMessage, editMessage } = useAppStore();
  const [editing, setEditing] = useState(false);
  const [editText, setEditText] = useState(msg.text || "");

  const isMine = msg.senderId === "me";

  function handleCopy() {
    navigator.clipboard?.writeText(msg.text || "");
    onClose();
  }

  function handleDelete(forEveryone: boolean) {
    deleteMessage(chat.id, msg.id, forEveryone);
    onClose();
  }

  function handleEdit() {
    if (editText.trim() && editText !== msg.text) {
      editMessage(chat.id, msg.id, editText.trim());
    }
    setEditing(false);
    onClose();
  }

  return (
    <motion.div
      initial={{ opacity: 0 }}
      animate={{ opacity: 1 }}
      exit={{ opacity: 0 }}
      className="fixed inset-0 z-50 flex items-end justify-center"
      onClick={onClose}
    >
      <div className="absolute inset-0 bg-black/40" />
      <motion.div
        initial={{ y: 200 }}
        animate={{ y: 0 }}
        exit={{ y: 200 }}
        transition={{ type: "spring", damping: 30 }}
        onClick={(e) => e.stopPropagation()}
        className="relative z-10 w-full max-w-md neu-raised rounded-t-3xl p-4 pb-6"
      >
        {/* Drag handle */}
        <div className="w-12 h-1 rounded-full mx-auto neu-text-muted opacity-30 mb-3" />

        {/* Message preview */}
        {!editing && (
          <div className="neu-inset rounded-2xl px-4 py-3 mb-4 max-h-32 overflow-y-auto neu-scroll">
            <div className="text-xs neu-text-muted mb-1">
              {formatDateSeparator(msg.timestamp)} · {formatTime(msg.timestamp)}
            </div>
            <div className="text-sm neu-text whitespace-pre-wrap break-words">
              {msg.deletedForEveryone ? "🚫 This message was deleted" : msg.text || `[${msg.type}]`}
            </div>
          </div>
        )}

        {editing && (
          <div className="mb-4">
            <textarea
              value={editText}
              onChange={(e) => setEditText(e.target.value)}
              className="neu-well rounded-2xl px-4 py-3 text-sm neu-text outline-none w-full resize-none"
              rows={3}
            />
            <div className="flex gap-2 mt-2">
              <NeuButton variant="raised" fullWidth rounded="xl" onClick={() => setEditing(false)}>Cancel</NeuButton>
              <NeuButton variant="accent" fullWidth rounded="xl" onClick={handleEdit}>Save</NeuButton>
            </div>
          </div>
        )}

        {!editing && (
          <div className="grid grid-cols-4 gap-3">
            <ActionItem icon={<Reply size={18} />} label="Reply" onClick={onReply} />
            <ActionItem icon={<Copy size={18} />} label="Copy" onClick={handleCopy} />
            <ActionItem icon={<Star size={18} />} label={msg.starred ? "Unstar" : "Star"} onClick={() => { toggleStarMessage(chat.id, msg.id); onClose(); }} />
            <ActionItem icon={<Forward size={18} />} label="Forward" onClick={onClose} />
            {isMine && msg.type === "text" && (
              <ActionItem icon={<Pencil size={18} />} label="Edit" onClick={() => setEditing(true)} />
            )}
            {isMine && (
              <ActionItem icon={<Trash2 size={18} />} label="Delete" danger onClick={() => handleDelete(true)} />
            )}
          </div>
        )}
      </motion.div>
    </motion.div>
  );
}

function ActionItem({ icon, label, onClick, danger }: { icon: React.ReactNode; label: string; onClick: () => void; danger?: boolean }) {
  return (
    <button
      onClick={onClick}
      className="flex flex-col items-center gap-1.5 p-2"
    >
      <div className={`w-12 h-12 neu-raised-sm rounded-2xl flex items-center justify-center ${danger ? "neu-text-danger" : "neu-text-accent"}`}>
        {icon}
      </div>
      <span className={`text-[11px] ${danger ? "neu-text-danger" : "neu-text-muted"}`}>{label}</span>
    </button>
  );
}

function relativeShort(timestamp: number): string {
  const diff = Date.now() - timestamp;
  if (diff < 60000) return "just now";
  if (diff < 3600000) return `${Math.floor(diff / 60000)} min ago`;
  if (diff < 86400000) return `${Math.floor(diff / 3600000)}h ago`;
  return `${Math.floor(diff / 86400000)}d ago`;
}
