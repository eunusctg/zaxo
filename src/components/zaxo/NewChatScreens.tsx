// ==================== SHARE ZAXO SCREEN (QR CODE) ====================
"use client";

import { useState, useEffect, useRef } from "react";
import { motion } from "framer-motion";
import { X, Copy, Check, Share2, ScanLine, Camera, CameraOff, AlertCircle } from "lucide-react";
import QRCode from "qrcode";
import jsQR from "jsqr";
import { NeuButton } from "@/components/neumorphic/NeuButton";
import { NeuInput } from "@/components/neumorphic/NeuInput";
import { NeuAvatar } from "@/components/neumorphic/NeuAvatar";
import { useAuthStore } from "@/store/authStore";
import { useUIStore } from "@/store/uiStore";
import { useAppStore } from "@/store/appStore";

// Deterministic mock QR pattern from zaxo number (fallback only — replaced by real QR)
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
  const [qrDataUrl, setQrDataUrl] = useState<string>("");

  // Generate real QR code from zaxo:// URI
  useEffect(() => {
    if (!user) return;
    const payload = `zaxo://contact?number=${encodeURIComponent(user.zaxoNumber)}&name=${encodeURIComponent(user.displayName)}`;
    QRCode.toDataURL(payload, {
      errorCorrectionLevel: "H",
      margin: 2,
      width: 480,
      color: { dark: "#1a1a2e", light: "#ffffff" },
    })
      .then(setQrDataUrl)
      .catch((e) => console.warn("[Zaxo] QR gen failed", e));
  }, [user]);

  if (!user) return null;

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
            {qrDataUrl ? (
              // eslint-disable-next-line @next/next/no-img-element
              <img
                src={qrDataUrl}
                alt="Zaxo QR Code"
                width={216}
                height={216}
                style={{ width: "100%", height: "100%", objectFit: "contain" }}
              />
            ) : (
              <div className="w-full h-full flex items-center justify-center text-xs text-gray-400">
                Generating QR…
              </div>
            )}
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

// ==================== QR SCANNER (REAL CAMERA) ====================
export function QRScannerScreen() {
  const { setSubPanel } = useUIStore();
  const { addContactByZaxoNumber, startChatWithContact, findContactByZaxoNumber } = useAppStore();
  const videoRef = useRef<HTMLVideoElement>(null);
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const streamRef = useRef<MediaStream | null>(null);
  const rafRef = useRef<number | null>(null);
  const [error, setError] = useState<string | null>(null);
  const [status, setStatus] = useState<"starting" | "scanning" | "found" | "denied" | "unsupported">("starting");
  const [foundNumber, setFoundNumber] = useState<string | null>(null);
  const [foundName, setFoundName] = useState<string | null>(null);
  const [manualNumber, setManualNumber] = useState("");

  // Parse a scanned QR payload. Supports:
  //   - zaxo://contact?number=XXX&name=YYY
  //   - bare Zaxo number (XXX-XXX-XXX or XXXXXXXXX)
  function parseZaxoPayload(raw: string): { number: string; name?: string } | null {
    if (!raw) return null;
    const trimmed = raw.trim();
    // zaxo:// URI
    if (trimmed.startsWith("zaxo://")) {
      try {
        const url = new URL(trimmed);
        const number = url.searchParams.get("number");
        const name = url.searchParams.get("name");
        if (number) return { number, name: name || undefined };
      } catch {
        return null;
      }
    }
    // Bare number: XXX-XXX-XXX or 9 digits
    const cleaned = trimmed.replace(/[\s-]/g, "");
    if (/^\d{9}$/.test(cleaned) || /^\d{3}-\d{3}-\d{3}$/.test(trimmed)) {
      return { number: trimmed };
    }
    return null;
  }

  function handleScan(raw: string) {
    const parsed = parseZaxoPayload(raw);
    if (!parsed) {
      setError("QR code is not a Zaxo contact. Make sure it's a Zaxo QR code.");
      return;
    }
    setFoundNumber(parsed.number);
    setFoundName(parsed.name || null);
    setStatus("found");
    // Stop the camera
    stopCamera();
  }

  function stopCamera() {
    if (rafRef.current) {
      cancelAnimationFrame(rafRef.current);
      rafRef.current = null;
    }
    if (streamRef.current) {
      streamRef.current.getTracks().forEach((t) => t.stop());
      streamRef.current = null;
    }
  }

  // Camera scanning loop using jsQR
  useEffect(() => {
    let mounted = true;

    async function startCamera() {
      if (typeof navigator === "undefined" || !navigator.mediaDevices?.getUserMedia) {
        setStatus("unsupported");
        setError("Camera API not supported in this browser.");
        return;
      }
      try {
        const stream = await navigator.mediaDevices.getUserMedia({
          video: { facingMode: "environment" },
          audio: false,
        });
        if (!mounted) {
          stream.getTracks().forEach((t) => t.stop());
          return;
        }
        streamRef.current = stream;
        if (videoRef.current) {
          videoRef.current.srcObject = stream;
          videoRef.current.setAttribute("playsinline", "true");
          await videoRef.current.play();
        }
        setStatus("scanning");
        // Begin scan loop
        const tick = () => {
          if (!mounted) return;
          if (videoRef.current && videoRef.current.readyState === videoRef.current.HAVE_ENOUGH_DATA) {
            const video = videoRef.current;
            const canvas = canvasRef.current;
            if (canvas) {
              const w = video.videoWidth || 480;
              const h = video.videoHeight || 640;
              canvas.width = w;
              canvas.height = h;
              const ctx = canvas.getContext("2d", { willReadFrequently: true });
              if (ctx) {
                ctx.drawImage(video, 0, 0, w, h);
                const imageData = ctx.getImageData(0, 0, w, h);
                const code = jsQR(imageData.data, w, h, { inversionAttempts: "dontInvert" });
                if (code && code.data) {
                  handleScan(code.data);
                  return;
                }
              }
            }
          }
          rafRef.current = requestAnimationFrame(tick);
        };
        rafRef.current = requestAnimationFrame(tick);
      } catch (err: unknown) {
        const e = err as DOMException;
        if (e.name === "NotAllowedError" || e.name === "PermissionDeniedError") {
          setStatus("denied");
          setError("Camera permission denied. Please allow camera access in your browser settings, or enter the Zaxo number manually below.");
        } else if (e.name === "NotFoundError" || e.name === "DevicesNotFoundError") {
          setStatus("unsupported");
          setError("No camera found on this device. Enter the Zaxo number manually below.");
        } else {
          setStatus("unsupported");
          setError(`Camera error: ${e.message || "unknown"}`);
        }
      }
    }

    startCamera();
    return () => {
      mounted = false;
      stopCamera();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  function handleAddContact() {
    if (!foundNumber) return;
    const existing = findContactByZaxoNumber(foundNumber);
    if (!existing) {
      addContactByZaxoNumber(foundNumber, foundName || undefined);
    }
    const contact = findContactByZaxoNumber(foundNumber);
    if (contact) {
      const chatId = startChatWithContact(contact.id);
      setSubPanel({ type: "chat_room", chatId });
    } else {
      setSubPanel({ type: "none" });
    }
  }

  function handleManualAdd() {
    const parsed = parseZaxoPayload(manualNumber);
    if (!parsed) {
      setError("Enter a valid Zaxo number (XXX-XXX-XXX or 9 digits).");
      return;
    }
    setError(null);
    setFoundNumber(parsed.number);
    setFoundName(parsed.name || null);
    setStatus("found");
  }

  return (
    <div className="flex flex-col h-full relative" style={{ background: "#000" }}>
      {/* Hidden canvas for frame capture */}
      <canvas ref={canvasRef} style={{ display: "none" }} />

      {/* Header */}
      <header className="flex items-center justify-between px-4 py-4 z-10 relative">
        <h1 className="text-xl font-bold text-white">Scan QR Code</h1>
        <button onClick={() => { stopCamera(); setSubPanel({ type: "none" }); }} className="text-white p-2">
          <X size={20} />
        </button>
      </header>

      {/* Video viewport */}
      <div className="flex-1 flex flex-col items-center justify-center relative overflow-hidden">
        <div
          className="relative rounded-3xl overflow-hidden"
          style={{ width: "100%", maxWidth: 360, height: "100%", maxHeight: 480 }}
        >
          <video
            ref={videoRef}
            className="w-full h-full object-cover"
            playsInline
            muted
          />
          {/* Corner brackets */}
          <div className="absolute inset-0 pointer-events-none">
            <div className="absolute top-1/4 left-1/4 w-12 h-12 border-t-4 border-l-4 border-[var(--neu-accent)] rounded-tl-3xl" />
            <div className="absolute top-1/4 right-1/4 w-12 h-12 border-t-4 border-r-4 border-[var(--neu-accent)] rounded-tr-3xl" />
            <div className="absolute bottom-1/4 left-1/4 w-12 h-12 border-b-4 border-l-4 border-[var(--neu-accent)] rounded-bl-3xl" />
            <div className="absolute bottom-1/4 right-1/4 w-12 h-12 border-b-4 border-r-4 border-[var(--neu-accent)] rounded-br-3xl" />
            {/* Scan line */}
            {status === "scanning" && (
              <motion.div
                className="absolute left-1/4 right-1/4 h-1"
                style={{ background: "linear-gradient(90deg, transparent, var(--neu-accent), transparent)" }}
                animate={{ top: ["25%", "70%", "25%"] }}
                transition={{ duration: 2.5, repeat: Infinity, ease: "easeInOut" }}
              />
            )}
          </div>

          {/* Status overlay */}
          {status === "starting" && (
            <div className="absolute inset-0 flex items-center justify-center bg-black/60">
              <div className="text-white text-sm flex items-center gap-2">
                <Camera size={16} /> Starting camera…
              </div>
            </div>
          )}
          {status === "denied" && (
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/80 p-6 text-center">
              <CameraOff size={48} className="text-white/60 mb-3" />
              <p className="text-white/80 text-sm">{error}</p>
            </div>
          )}
          {status === "unsupported" && (
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/80 p-6 text-center">
              <AlertCircle size={48} className="text-white/60 mb-3" />
              <p className="text-white/80 text-sm">{error}</p>
            </div>
          )}
          {status === "found" && (
            <div className="absolute inset-0 flex flex-col items-center justify-center bg-black/85 p-6 text-center">
              <motion.div
                initial={{ scale: 0.5, opacity: 0 }}
                animate={{ scale: 1, opacity: 1 }}
                className="w-16 h-16 rounded-full bg-green-500 flex items-center justify-center mb-3"
              >
                <Check size={32} className="text-white" />
              </motion.div>
              <p className="text-white text-base font-medium">{foundName || "Zaxo contact found"}</p>
              <p className="text-white/70 text-sm font-mono mt-1">{foundNumber}</p>
            </div>
          )}
        </div>

        <p className="text-white/70 text-sm mt-6 text-center max-w-xs px-6">
          {status === "scanning"
            ? "Point your camera at a Zaxo QR code to add the contact instantly."
            : status === "found"
              ? "Contact detected. Add them to start chatting."
              : ""}
        </p>
      </div>

      {/* Action bar */}
      <div className="p-4 z-10 relative" style={{ background: "rgba(0,0,0,0.85)" }}>
        {status === "found" ? (
          <div className="space-y-2">
            <NeuButton
              variant="accent"
              size="lg"
              fullWidth
              rounded="xl"
              onClick={handleAddContact}
            >
              Add contact & chat
            </NeuButton>
            <NeuButton
              variant="raised"
              size="md"
              fullWidth
              rounded="xl"
              onClick={() => { setFoundNumber(null); setFoundName(null); setStatus("starting"); setError(null); }}
            >
              Scan another
            </NeuButton>
          </div>
        ) : (
          <div className="space-y-2">
            <div className="flex gap-2">
              <input
                type="text"
                placeholder="Enter Zaxo number manually (XXX-XXX-XXX)"
                value={manualNumber}
                onChange={(e) => setManualNumber(e.target.value)}
                className="flex-1 px-4 py-3 rounded-xl bg-white/10 text-white text-sm placeholder-white/40 border border-white/20"
              />
              <button
                onClick={handleManualAdd}
                className="px-4 py-3 rounded-xl bg-[var(--neu-accent)] text-white text-sm font-medium"
              >
                Add
              </button>
            </div>
            {error && <p className="text-red-400 text-xs">{error}</p>}
            <NeuButton
              variant="raised"
              size="md"
              fullWidth
              rounded="xl"
              onClick={() => { stopCamera(); setSubPanel({ type: "none" }); }}
            >
              Cancel
            </NeuButton>
          </div>
        )}
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
