// ==================== SHARE ZAXO SCREEN (QR CODE) ====================
"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { X, Copy, Check, Share2, ScanLine } from "lucide-react";
import { NeuButton } from "@/components/neumorphic/NeuButton";
import { NeuInput } from "@/components/neumorphic/NeuInput";
import { NeuAvatar } from "@/components/neumorphic/NeuAvatar";
import { useAuthStore } from "@/store/authStore";
import { useUIStore } from "@/store/uiStore";

// Deterministic mock QR pattern from zaxo number
function generateQRMatrix(data: string, size: number = 21): boolean[][] {
  // Simple deterministic pseudo-QR pattern (visual only - not a real QR code)
  const matrix: boolean[][] = [];
  let seed = 0;
  for (let i = 0; i < data.length; i++) seed = (seed * 31 + data.charCodeAt(i)) >>> 0;
  for (let i = 0; i < size; i++) {
    const row: boolean[] = [];
    for (let j = 0; j < size; j++) {
      seed = (seed * 1103515245 + 12345) & 0x7fffffff;
      row.push((seed & 1) === 1);
    }
    matrix.push(row);
  }
  // Add corner squares (finder patterns)
  function setFinder(r: number, c: number) {
    for (let i = -1; i <= 7; i++) {
      for (let j = -1; j <= 7; j++) {
        const rr = r + i, cc = c + j;
        if (rr < 0 || cc < 0 || rr >= size || cc >= size) continue;
        const isBorder = i === 0 || i === 6 || j === 0 || j === 6;
        const isInner = i >= 2 && i <= 4 && j >= 2 && j <= 4;
        const isQuiet = i === -1 || i === 7 || j === -1 || j === 7;
        matrix[rr][cc] = isQuiet ? false : (isBorder || isInner);
      }
    }
  }
  setFinder(0, 0);
  setFinder(0, size - 7);
  setFinder(size - 7, 0);
  return matrix;
}

export function ShareZaxoScreen() {
  const { user } = useAuthStore();
  const { setSubPanel } = useUIStore();
  const [copied, setCopied] = useState(false);

  if (!user) return null;
  const matrix = generateQRMatrix(user.zaxoNumber, 21);

  function handleCopy() {
    navigator.clipboard?.writeText(user!.zaxoNumber);
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  }

  function handleShare() {
    if (navigator.share) {
      navigator.share({
        title: "My Zaxo Number",
        text: `Connect with me on Zaxo! My number is ${user!.zaxoNumber}`,
      }).catch(() => {});
    } else {
      handleCopy();
    }
  }

  return (
    <div className="flex flex-col h-full px-6 py-4" style={{ background: "var(--neu-bg)" }}>
      <header className="flex items-center justify-between mb-4">
        <h1 className="text-xl font-bold neu-text">Share Zaxo Number</h1>
        <button onClick={() => setSubPanel({ type: "none" })} className="neu-text-muted p-2">
          <X size={20} />
        </button>
      </header>

      <div className="flex-1 flex flex-col items-center justify-center">
        {/* QR code card */}
        <motion.div
          initial={{ scale: 0.9, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          className="neu-raised-lg rounded-3xl p-6 w-full max-w-xs"
        >
          <div className="text-center mb-4">
            <NeuAvatar initial={user.avatarInitial} gradient={user.avatarColor} size={64} />
            <div className="font-semibold neu-text mt-2">{user.displayName}</div>
            <div className="text-xs neu-text-muted">{user.about}</div>
          </div>

          <div
            className="bg-white rounded-2xl p-3 mx-auto"
            style={{ width: 240, height: 240 }}
          >
            <div
              className="w-full h-full grid"
              style={{
                gridTemplateColumns: `repeat(${matrix.length}, 1fr)`,
                gap: 0,
              }}
            >
              {matrix.map((row, i) =>
                row.map((cell, j) => (
                  <div
                    key={`${i}-${j}`}
                    style={{
                      background: cell ? "#000" : "transparent",
                    }}
                  />
                )),
              )}
            </div>
          </div>

          <div className="text-center mt-4">
            <div className="text-xs neu-text-muted uppercase tracking-wider">Scan to add me on Zaxo</div>
            <div className="text-2xl font-bold neu-text-accent font-mono tracking-wider mt-2">
              {user.zaxoNumber}
            </div>
          </div>
        </motion.div>

        <div className="w-full max-w-xs mt-6 space-y-3">
          <NeuButton
            variant="accent"
            size="lg"
            fullWidth
            rounded="xl"
            icon={copied ? <Check size={18} /> : <Copy size={18} />}
            onClick={handleCopy}
          >
            {copied ? "Copied to clipboard" : "Copy number"}
          </NeuButton>
          <div className="grid grid-cols-2 gap-3">
            <NeuButton
              variant="raised"
              size="md"
              rounded="xl"
              icon={<Share2 size={16} />}
              onClick={handleShare}
            >
              Share
            </NeuButton>
            <NeuButton
              variant="raised"
              size="md"
              rounded="xl"
              icon={<ScanLine size={16} />}
              onClick={() => setSubPanel({ type: "qr_scanner" })}
            >
              Scan
            </NeuButton>
          </div>
        </div>
      </div>

      <p className="text-xs neu-text-muted text-center mt-4">
        Your Zaxo number is permanent. Share it so others can connect with you.
      </p>
    </div>
  );
}

// ==================== QR SCANNER ====================
export function QRScannerScreen() {
  const { setSubPanel } = useUIStore();
  return (
    <div className="flex flex-col h-full px-6 py-4 relative" style={{ background: "#000" }}>
      <header className="flex items-center justify-between mb-4">
        <h1 className="text-xl font-bold text-white">Scan QR Code</h1>
        <button onClick={() => setSubPanel({ type: "none" })} className="text-white p-2">
          <X size={20} />
        </button>
      </header>

      <div className="flex-1 flex flex-col items-center justify-center">
        <div
          className="relative rounded-3xl overflow-hidden"
          style={{ width: 280, height: 280, background: "rgba(255,255,255,0.05)" }}
        >
          {/* Corner brackets */}
          <div className="absolute top-0 left-0 w-12 h-12 border-t-4 border-l-4 border-[var(--neu-accent)] rounded-tl-3xl" />
          <div className="absolute top-0 right-0 w-12 h-12 border-t-4 border-r-4 border-[var(--neu-accent)] rounded-tr-3xl" />
          <div className="absolute bottom-0 left-0 w-12 h-12 border-b-4 border-l-4 border-[var(--neu-accent)] rounded-bl-3xl" />
          <div className="absolute bottom-0 right-0 w-12 h-12 border-b-4 border-r-4 border-[var(--neu-accent)] rounded-br-3xl" />

          {/* Scan line animation */}
          <motion.div
            className="absolute left-4 right-4 h-1"
            style={{ background: "linear-gradient(90deg, transparent, var(--neu-accent), transparent)" }}
            animate={{ top: ["10%", "85%", "10%"] }}
            transition={{ duration: 2.5, repeat: Infinity, ease: "easeInOut" }}
          />
        </div>

        <p className="text-white/70 text-sm mt-8 text-center max-w-xs">
          Point your camera at a Zaxo QR code to add the contact instantly.
        </p>

        <NeuButton
          variant="raised"
          size="md"
          rounded="xl"
          className="mt-6"
          onClick={() => setSubPanel({ type: "none" })}
        >
          Cancel
        </NeuButton>
      </div>
    </div>
  );
}

// ==================== NEW CHAT ====================
export function NewChatScreen() {
  const { contacts, startChatWithContact, inviteContact } = useAppStore();
  const { setSubPanel } = useUIStore();
  const [query, setQuery] = useState("");

  const filtered = contacts.filter((c) => {
    if (!query) return true;
    const q = query.toLowerCase();
    return c.displayName.toLowerCase().includes(q) || c.zaxoNumber.toLowerCase().includes(q);
  });

  const zaxoUsers = filtered.filter((c) => c.isZaxoUser);
  const invitees = filtered.filter((c) => !c.isZaxoUser);

  return (
    <div className="flex flex-col h-full px-4 py-4" style={{ background: "var(--neu-bg)" }}>
      <header className="flex items-center gap-2 mb-4">
        <button onClick={() => setSubPanel({ type: "none" })} className="neu-text p-1">
          <X size={22} />
        </button>
        <h1 className="text-xl font-bold neu-text">New chat</h1>
      </header>

      <NeuInput
        placeholder="Search by name or Zaxo number"
        value={query}
        onChange={(e) => setQuery(e.target.value)}
        showClear
        onClear={() => setQuery("")}
      />

      <div className="flex-1 overflow-y-auto neu-scroll mt-4">
        <button
          onClick={() => setSubPanel({ type: "new_group" })}
          className="w-full flex items-center gap-3 px-2 py-3 rounded-2xl hover:bg-[color:var(--neu-shadow-light)]/5"
        >
          <div className="w-12 h-12 rounded-full neu-accent flex items-center justify-center">
            <svg width={20} height={20} viewBox="0 0 24 24" fill="none">
              <path d="M17 21v-2a4 4 0 0 0-4-4H5a4 4 0 0 0-4 4v2M9 11a4 4 0 1 0 0-8 4 4 0 0 0 0 8zM23 21v-2a4 4 0 0 0-3-3.87M16 3.13a4 4 0 0 1 0 7.75" stroke="white" strokeWidth="2" strokeLinecap="round" strokeLinejoin="round" />
            </svg>
          </div>
          <div className="flex-1 text-left">
            <div className="font-semibold text-sm neu-text">New group</div>
            <div className="text-xs neu-text-muted">Create a group chat</div>
          </div>
        </button>

        {zaxoUsers.length > 0 && (
          <>
            <div className="px-2 pt-4 pb-2 text-xs font-semibold neu-text-muted uppercase tracking-wider">
              Contacts on Zaxo
            </div>
            {zaxoUsers.map((c) => (
              <button
                key={c.id}
                onClick={() => {
                  const chatId = startChatWithContact(c.id);
                  setSubPanel({ type: "chat_room", chatId });
                }}
                className="w-full flex items-center gap-3 px-2 py-3 rounded-2xl hover:bg-[color:var(--neu-shadow-light)]/5"
              >
                <NeuAvatar initial={c.avatarInitial} gradient={c.avatarColor} size={48} online={c.online} />
                <div className="flex-1 text-left">
                  <div className="font-semibold text-sm neu-text">{c.displayName}</div>
                  <div className="text-xs neu-text-muted font-mono">{c.zaxoNumber}</div>
                </div>
              </button>
            ))}
          </>
        )}

        {invitees.length > 0 && (
          <>
            <div className="px-2 pt-4 pb-2 text-xs font-semibold neu-text-muted uppercase tracking-wider">
              Invite to Zaxo
            </div>
            {invitees.map((c) => (
              <div key={c.id} className="w-full flex items-center gap-3 px-2 py-3 rounded-2xl">
                <NeuAvatar initial={c.avatarInitial} gradient={c.avatarColor} size={48} />
                <div className="flex-1 text-left">
                  <div className="font-semibold text-sm neu-text">{c.displayName}</div>
                  <div className="text-xs neu-text-muted">Not on Zaxo yet</div>
                </div>
                <NeuButton variant="raised" size="sm" rounded="xl" onClick={() => inviteContact(c.id)}>Invite</NeuButton>
              </div>
            ))}
          </>
        )}
      </div>
    </div>
  );
}

// ==================== NEW GROUP ====================
export function NewGroupScreen() {
  const { contacts, createGroup } = useAppStore();
  const { setSubPanel } = useUIStore();
  const [selected, setSelected] = useState<Set<string>>(new Set());
  const [step, setStep] = useState<"select" | "name">("select");
  const [groupName, setGroupName] = useState("");
  const [description, setDescription] = useState("");

  const zaxoUsers = contacts.filter((c) => c.isZaxoUser);

  function toggle(id: string) {
    const next = new Set(selected);
    if (next.has(id)) next.delete(id);
    else next.add(id);
    setSelected(next);
  }

  function handleCreate() {
    if (!groupName.trim() || selected.size === 0) return;
    const chatId = createGroup(groupName.trim(), Array.from(selected), description.trim());
    setSubPanel({ type: "chat_room", chatId });
  }

  if (step === "select") {
    return (
      <div className="flex flex-col h-full px-4 py-4" style={{ background: "var(--neu-bg)" }}>
        <header className="flex items-center gap-2 mb-4">
          <button onClick={() => setSubPanel({ type: "none" })} className="neu-text p-1">
            <X size={22} />
          </button>
          <h1 className="text-xl font-bold neu-text flex-1">New group</h1>
          {selected.size > 0 && (
            <span className="neu-accent rounded-full px-3 py-1 text-xs text-white">
              {selected.size} selected
            </span>
          )}
        </header>

        <div className="flex-1 overflow-y-auto neu-scroll">
          {zaxoUsers.map((c) => {
            const isSelected = selected.has(c.id);
            return (
              <button
                key={c.id}
                onClick={() => toggle(c.id)}
                className="w-full flex items-center gap-3 px-2 py-3 rounded-2xl hover:bg-[color:var(--neu-shadow-light)]/5"
              >
                <NeuAvatar initial={c.avatarInitial} gradient={c.avatarColor} size={48} online={c.online} />
                <div className="flex-1 text-left">
                  <div className="font-semibold text-sm neu-text">{c.displayName}</div>
                  <div className="text-xs neu-text-muted font-mono">{c.zaxoNumber}</div>
                </div>
                <div
                  className={`w-6 h-6 rounded-full flex items-center justify-center transition-all ${isSelected ? "neu-accent" : "neu-raised-sm"}`}
                >
                  {isSelected && <Check size={14} className="text-white" />}
                </div>
              </button>
            );
          })}
        </div>

        <NeuButton
          variant="accent"
          size="lg"
          fullWidth
          rounded="xl"
          disabled={selected.size === 0}
          onClick={() => setStep("name")}
        >
          {selected.size === 0 ? "Select members" : `Next (${selected.size})`}
        </NeuButton>
      </div>
    );
  }

  return (
    <div className="flex flex-col h-full px-4 py-4" style={{ background: "var(--neu-bg)" }}>
      <header className="flex items-center gap-2 mb-4">
        <button onClick={() => setStep("select")} className="neu-text p-1">
          <X size={22} />
        </button>
        <h1 className="text-xl font-bold neu-text">Group info</h1>
      </header>

      <div className="flex flex-col items-center mt-4 mb-6">
        <div
          className="w-24 h-24 rounded-full flex items-center justify-center text-white text-3xl font-bold neu-raised"
          style={{ background: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)" }}
        >
          {groupName.charAt(0).toUpperCase() || "G"}
        </div>
      </div>

      <div className="space-y-3">
        <div>
          <label className="text-xs neu-text-muted uppercase tracking-wider px-1">Group name</label>
          <NeuInput
            placeholder="Enter group name"
            value={groupName}
            onChange={(e) => setGroupName(e.target.value)}
            autoFocus
          />
        </div>
        <div>
          <label className="text-xs neu-text-muted uppercase tracking-wider px-1">Description (optional)</label>
          <NeuInput
            placeholder="What's this group about?"
            value={description}
            onChange={(e) => setDescription(e.target.value)}
          />
        </div>
      </div>

      <div className="text-xs neu-text-muted mt-4 px-1">
        {selected.size} member{selected.size > 1 ? "s" : ""} selected
      </div>

      <div className="flex-1" />

      <NeuButton
        variant="accent"
        size="lg"
        fullWidth
        rounded="xl"
        disabled={!groupName.trim()}
        onClick={handleCreate}
      >
        Create group
      </NeuButton>
    </div>
  );
}
