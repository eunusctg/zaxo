// ==================== CALL SCREEN ====================
"use client";

import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Mic, MicOff, Video, VideoOff, Phone, PhoneOff, Volume2, VolumeX,
  Camera, SwitchCamera, ChevronDown, ScreenShare, Users, Plus,
} from "lucide-react";
import { NeuAvatar } from "@/components/neumorphic/NeuAvatar";
import { useAppStore } from "@/store/appStore";
import { useUIStore } from "@/store/uiStore";
import { useAuthStore } from "@/store/authStore";
import { getContactById } from "@/lib/zaxo/mockData";
import type { Call } from "@/types";

export function CallScreen({ otherUserId, callType }: { otherUserId: string; callType: "voice" | "video" }) {
  const { contacts, addCall } = useAppStore();
  const { setSubPanel } = useUIStore();
  const { user } = useAuthStore();
  const other = getContactById(otherUserId, contacts);

  const [state, setState] = useState<"calling" | "ringing" | "connected" | "ended">("calling");
  const [muted, setMuted] = useState(false);
  const [speaker, setSpeaker] = useState(true);
  const [videoOn, setVideoOn] = useState(callType === "video");
  const [cameraFront, setCameraFront] = useState(true);
  const [seconds, setSeconds] = useState(0);
  const [minimized, setMinimized] = useState(false);

  // Call state machine
  useEffect(() => {
    const t1 = setTimeout(() => setState("ringing"), 1500);
    const t2 = setTimeout(() => setState("connected"), 3500);
    return () => { clearTimeout(t1); clearTimeout(t2); };
  }, []);

  // Call duration
  useEffect(() => {
    if (state === "connected") {
      const interval = setInterval(() => setSeconds((s) => s + 1), 1000);
      return () => clearInterval(interval);
    }
  }, [state]);

  function handleEndCall() {
    setState("ended");
    // Log the call to history
    const newCall: Call = {
      id: `call_${Date.now()}`,
      otherUserId,
      type: callType,
      direction: "outgoing",
      timestamp: Date.now(),
      duration: seconds,
    };
    addCall(newCall);
    setTimeout(() => setSubPanel({ type: "none" }), 400);
  }

  function statusText(): string {
    if (state === "calling") return "Calling…";
    if (state === "ringing") return "Ringing…";
    if (state === "connected") return formatTime(seconds);
    return "Call ended";
  }

  if (!other) return null;

  return (
    <div
      className="flex flex-col h-full relative"
      style={{
        background: callType === "video" && videoOn
          ? "linear-gradient(135deg, #1a1c22 0%, #2d2d44 100%)"
          : "var(--neu-bg)",
      }}
    >
      {/* Video background (mock) */}
      {callType === "video" && videoOn && state === "connected" && (
        <div className="absolute inset-0 flex items-center justify-center" style={{ background: "linear-gradient(135deg, #1a1c22 0%, #2d2d44 100%)" }}>
          <div className="text-center">
            <NeuAvatar initial={other.avatarInitial} gradient={other.avatarColor} size={140} />
            <div className="text-white mt-4 text-lg font-medium">{other.displayName}</div>
            <div className="text-white/60 text-sm">Video paused (demo mode)</div>
          </div>
        </div>
      )}

      {/* Local video PiP */}
      {callType === "video" && videoOn && state === "connected" && (
        <div className="absolute top-20 right-4 z-20 w-24 h-32 rounded-2xl overflow-hidden" style={{ background: "linear-gradient(135deg, #6C5CE7 0%, #A29BFE 100%)" }}>
          <div className="w-full h-full flex items-center justify-center">
            <span className="text-white text-3xl font-bold">{user?.avatarInitial}</span>
          </div>
        </div>
      )}

      {/* Header */}
      <header className="px-4 pt-4 pb-2 flex items-center justify-between z-10 relative">
        <button
          onClick={() => setMinimized(!minimized)}
          className="neu-pressable rounded-full w-10 h-10 flex items-center justify-center text-white"
        >
          <ChevronDown size={20} />
        </button>
        <div className="text-white text-sm font-medium">
          {callType === "video" ? "Video call" : "Voice call"}
        </div>
        <div className="w-10" />
      </header>

      {/* Caller info */}
      <div className="flex-1 flex flex-col items-center justify-center px-8 z-10 relative">
        <motion.div
          initial={{ scale: 0.85, opacity: 0 }}
          animate={{ scale: 1, opacity: 1 }}
          transition={{ duration: 0.5 }}
          className="relative"
        >
          {(state === "calling" || state === "ringing") && (
            <>
              <div className="absolute inset-0 rounded-full ring-pulse" style={{ background: "var(--neu-accent)", opacity: 0.4 }} />
              <div className="absolute inset-0 rounded-full ring-pulse" style={{ background: "var(--neu-accent)", opacity: 0.3, animationDelay: "0.6s" }} />
            </>
          )}
          <NeuAvatar initial={other.avatarInitial} gradient={other.avatarColor} size={120} />
        </motion.div>

        <motion.h2
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className={`text-2xl font-bold mt-6 ${callType === "video" && videoOn && state === "connected" ? "text-white" : "neu-text"}`}
        >
          {other.displayName}
        </motion.h2>
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
          className={`text-sm mt-1 font-mono ${callType === "video" && videoOn && state === "connected" ? "text-white/70" : "neu-text-muted"}`}
        >
          {other.zaxoNumber}
        </motion.div>
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.7 }}
          className={`mt-3 text-sm ${callType === "video" && videoOn && state === "connected" ? "text-white/80" : "neu-text-muted"}`}
        >
          {statusText()}
        </motion.div>
      </div>

      {/* Action buttons */}
      <div className="px-6 pb-8 z-10 relative">
        <div className="flex items-center justify-center gap-4 mb-4">
          <CallButton
            icon={muted ? <MicOff size={22} /> : <Mic size={22} />}
            label={muted ? "Unmute" : "Mute"}
            active={muted}
            onClick={() => setMuted(!muted)}
          />
          {callType === "video" && (
            <CallButton
              icon={videoOn ? <Video size={22} /> : <VideoOff size={22} />}
              label={videoOn ? "Video on" : "Video off"}
              active={!videoOn}
              onClick={() => setVideoOn(!videoOn)}
            />
          )}
          <CallButton
            icon={speaker ? <Volume2 size={22} /> : <VolumeX size={22} />}
            label={speaker ? "Speaker" : "Earpiece"}
            active={!speaker}
            onClick={() => setSpeaker(!speaker)}
          />
          {callType === "video" && videoOn && (
            <CallButton
              icon={<SwitchCamera size={22} />}
              label="Flip"
              onClick={() => setCameraFront(!cameraFront)}
            />
          )}
        </div>

        <div className="flex items-center justify-center gap-4">
          <CallButton
            icon={<ScreenShare size={22} />}
            label="Share"
            small
          />
          <CallButton
            icon={<Users size={22} />}
            label="Add"
            small
          />
          <button
            onClick={handleEndCall}
            className="neu-danger rounded-full w-16 h-16 flex items-center justify-center scale-pulse"
            aria-label="End call"
          >
            <PhoneOff size={26} />
          </button>
        </div>
      </div>

      {/* Minimized bar */}
      <AnimatePresence>
        {minimized && (
          <motion.div
            initial={{ y: 100 }}
            animate={{ y: 0 }}
            exit={{ y: 100 }}
            className="absolute bottom-4 left-4 right-4 z-30 neu-raised rounded-2xl px-4 py-3 flex items-center gap-3"
          >
            <NeuAvatar initial={other.avatarInitial} gradient={other.avatarColor} size={36} />
            <div className="flex-1 min-w-0">
              <div className="text-sm font-medium neu-text truncate">{other.displayName}</div>
              <div className="text-xs neu-text-accent">{statusText()}</div>
            </div>
            <button onClick={() => setMinimized(false)} className="neu-pressable rounded-full w-9 h-9 flex items-center justify-center neu-text">
              <ChevronDown size={18} className="rotate-180" />
            </button>
            <button onClick={handleEndCall} className="neu-danger rounded-full w-9 h-9 flex items-center justify-center">
              <PhoneOff size={16} />
            </button>
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

function CallButton({
  icon, label, onClick, active = false, small = false,
}: {
  icon: React.ReactNode;
  label: string;
  onClick?: () => void;
  active?: boolean;
  small?: boolean;
}) {
  const size = small ? 48 : 56;
  return (
    <div className="flex flex-col items-center gap-1.5">
      <button
        onClick={onClick}
        className={`rounded-full flex items-center justify-center transition-all active:scale-95 ${active ? "neu-inset" : "neu-pressable"}`}
        style={{
          width: size,
          height: size,
          color: "white",
          background: active ? "var(--neu-danger)" : "rgba(108, 92, 231, 0.85)",
          boxShadow: active
            ? "inset 3px 3px 6px rgba(0,0,0,0.25), inset -3px -3px 6px rgba(255,255,255,0.15)"
            : "3px 3px 8px var(--neu-shadow-dark), -3px -3px 8px var(--neu-shadow-light)",
        }}
      >
        {icon}
      </button>
      <span className="text-[10px] neu-text-muted">{label}</span>
    </div>
  );
}

function formatTime(seconds: number): string {
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  return `${m.toString().padStart(2, "0")}:${s.toString().padStart(2, "0")}`;
}
