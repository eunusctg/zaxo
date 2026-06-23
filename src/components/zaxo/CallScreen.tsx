// ==================== CALL SCREEN (REAL WebRTC) ====================
// Real peer-to-peer audio/video calls via WebRTC.
// Signaling flows through BroadcastChannel (realtime service).
//   Outgoing: caller initiates → inviteToCall → wait for accept → createOffer
//   Incoming: callee accepts → wait for offer → createAnswer
// Both sides exchange ICE candidates and connect media streams.

"use client";

import { useEffect, useRef, useState, useCallback } from "react";
import { motion, AnimatePresence } from "framer-motion";
import {
  Mic, MicOff, Video, VideoOff, Phone, PhoneOff, Volume2, VolumeX,
  ChevronDown, ScreenShare, UserPlus, Info,
} from "lucide-react";
import { NeuAvatar } from "@/components/neumorphic/NeuAvatar";
import { useAppStore } from "@/store/appStore";
import { useUIStore } from "@/store/uiStore";
import { useAuthStore } from "@/store/authStore";
import { useCallStateStore } from "@/store/callStateStore";
import { getContactById, formatDuration } from "@/lib/zaxo/mockData";
import { realtime } from "@/lib/zaxo/realtime";
import { callEngine } from "@/lib/zaxo/callEngine";
import type { Call } from "@/types";

type CallState = "calling" | "ringing" | "connected" | "ended";

export function CallScreen({ otherUserId, callType }: { otherUserId: string; callType: "voice" | "video" }) {
  const { contacts, addCall, insertCallMessage } = useAppStore();
  const { setSubPanel } = useUIStore();
  const { user } = useAuthStore();
  const { activeCall, setActiveCall } = useCallStateStore();
  const other = getContactById(otherUserId, contacts);

  const [state, setState] = useState<CallState>("calling");
  const [muted, setMuted] = useState(false);
  const [speaker, setSpeaker] = useState(true);
  const [videoOn, setVideoOn] = useState(callType === "video");
  const [seconds, setSeconds] = useState(0);
  const [minimized, setMinimized] = useState(false);
  const [camError, setCamError] = useState<string | null>(null);
  const [showInfo, setShowInfo] = useState(false);
  const [remoteStream, setRemoteStream] = useState<MediaStream | null>(null);
  const [localStream, setLocalStream] = useState<MediaStream | null>(null);
  const [connectionStatus, setConnectionStatus] = useState<string>("initializing");

  // Determine if we're the caller or callee
  const isIncoming = activeCall?.direction === "incoming";
  const callId = activeCall?.callId || `call_${otherUserId}_${Date.now()}`;

  // If no activeCall yet (e.g., user tapped call button), create one as outgoing
  useEffect(() => {
    if (!activeCall) {
      setActiveCall({
        callId,
        otherUserId,
        callType,
        chatId,
        isGroup: false,
        direction: "outgoing",
        state: "calling",
        startedAt: Date.now(),
      });
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Find chatId for logging the call message
  const chatId = useAppStore.getState().chats.find(
    (c) => c.type === "individual" && c.participantIds[0] === otherUserId,
  )?.id;

  const localVideoRef = useRef<HTMLVideoElement>(null);
  const remoteVideoRef = useRef<HTMLVideoElement>(null);
  const startTimeRef = useRef<number>(0);
  const acceptedRef = useRef<boolean>(false);
  const remoteUserIdRef = useRef<string>(otherUserId);

  // Initialize call engine + acquire local media
  useEffect(() => {
    if (!other) return;
    // For demo: use otherUserId as the remote. In a multi-tab scenario,
    // the remote user's tab is identified by their zaxo number.
    remoteUserIdRef.current = other.id;

    // Initialize WebRTC peer connection
    callEngine.init(callId, other.id, !isIncoming, {
      onLocalStream: (stream) => {
        setLocalStream(stream);
        if (localVideoRef.current && callType === "video") {
          localVideoRef.current.srcObject = stream;
          localVideoRef.current.muted = true;
          localVideoRef.current.play().catch(() => {});
        }
      },
      onRemoteStream: (stream) => {
        setRemoteStream(stream);
        if (remoteVideoRef.current) {
          remoteVideoRef.current.srcObject = stream;
          remoteVideoRef.current.play().catch(() => {});
        }
        setState("connected");
        startTimeRef.current = Date.now();
        setConnectionStatus("connected");
      },
      onStateChange: (s) => {
        setConnectionStatus(s);
        if (s === "connected") {
          setState("connected");
          startTimeRef.current = Date.now();
        } else if (s === "failed" || s === "disconnected") {
          setConnectionStatus(s);
        }
      },
    });

    // Acquire local media (camera + mic)
    callEngine.acquireLocalMedia(callType === "video" && videoOn)
      .then(() => {
        setCamError(null);
        setConnectionStatus("local-ready");
        // If caller: send invite + create offer immediately
        if (!isIncoming) {
          // Send invite via realtime (callerId, callType, chatId, isGroup)
          realtime.inviteToCall(callId, user?.displayName || "Me", callType, chatId || "", false);
          // Wait for the remote to accept, then create offer
          const unsub = realtime.subscribe((ev) => {
            if (ev.kind === "call_accept" && ev.callId === callId) {
              if (!acceptedRef.current) {
                acceptedRef.current = true;
                setState("ringing");
                setConnectionStatus("creating-offer");
                setTimeout(() => callEngine.createOffer(), 200);
              }
            } else if (ev.kind === "call_sdp" && ev.callId === callId && ev.to === realtime.getMyUserId()) {
              // Got SDP from callee — connection is being established
              if (ev.sdp.type === "answer") {
                setState("connected");
                startTimeRef.current = Date.now();
              }
            } else if (ev.kind === "call_decline" && ev.callId === callId) {
              setState("ended");
              setTimeout(() => setSubPanel({ type: "none" }), 800);
            }
          });
          return () => unsub();
        } else {
          // Incoming: we already accepted. Create answer when offer arrives.
          setState("connected"); // assume connected; actual media connects on offer/answer
          startTimeRef.current = Date.now();
        }
      })
      .catch((err: unknown) => {
        const e = err as DOMException;
        if (e.name === "NotAllowedError") setCamError("Camera/microphone permission denied. Please allow access in browser settings.");
        else if (e.name === "NotFoundError") setCamError("No camera/microphone found on this device.");
        else setCamError(`Media error: ${e.message || "unknown"}`);
        setConnectionStatus("media-error");
      });

    return () => {
      callEngine.endCall();
    };
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  // Apply mute toggle to actual track
  useEffect(() => {
    callEngine.toggleMute(muted);
  }, [muted]);

  // Apply video toggle
  useEffect(() => {
    callEngine.toggleVideo(videoOn);
    if (localVideoRef.current && localStream) {
      localVideoRef.current.srcObject = videoOn ? localStream : null;
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, [videoOn]);

  // Call duration timer
  useEffect(() => {
    if (state === "connected") {
      const interval = setInterval(() => {
        setSeconds(Math.floor((Date.now() - startTimeRef.current) / 1000));
      }, 1000);
      return () => clearInterval(interval);
    }
  }, [state]);

  const handleEndCall = useCallback(() => {
    callEngine.endCall();
    realtime.endCall(callId);
    realtime.sendCallState(callId, "ended");
    // Compute duration
    const duration = state === "connected"
      ? Math.floor((Date.now() - startTimeRef.current) / 1000)
      : 0;
    const missed = duration === 0 && state !== "connected";
    setState("ended");
    // Log call
    const newCall: Call = {
      id: callId,
      otherUserId,
      type: callType,
      direction: missed ? "missed" : isIncoming ? "incoming" : "outgoing",
      timestamp: Date.now(),
      duration,
    };
    addCall(newCall);
    // Insert call system message in chat if chat exists
    if (chatId) {
      insertCallMessage(chatId, callType, missed ? "missed" : isIncoming ? "incoming" : "outgoing", duration);
    }
    // Clear active call state
    setActiveCall(null);
    setTimeout(() => setSubPanel({ type: "none" }), 500);
  }, [state, otherUserId, callType, addCall, insertCallMessage, chatId, setSubPanel, callId, isIncoming, setActiveCall]);

  function statusText(): string {
    if (state === "calling") return "Calling…";
    if (state === "ringing") return "Ringing…";
    if (state === "connected") return formatDuration(seconds);
    return "Call ended";
  }

  if (!other) return null;

  const showVideo = callType === "video" && videoOn && !camError;

  return (
    <div
      className="flex flex-col h-full w-full relative"
      style={{
        background: showVideo
          ? "linear-gradient(135deg, #1a1c22 0%, #2d2d44 100%)"
          : "var(--neu-bg)",
      }}
    >
      {/* Remote video (real WebRTC stream) */}
      {showVideo && (
        <div className="absolute inset-0 flex items-center justify-center" style={{ background: "#000" }}>
          <video
            ref={remoteVideoRef}
            className="w-full h-full object-cover"
            playsInline
            autoPlay
          />
          {!remoteStream && (
            <div className="absolute inset-0 flex items-center justify-center">
              <div className="text-center">
                <NeuAvatar initial={other.avatarInitial} gradient={other.avatarColor} size={140} />
                <div className="text-white mt-4 text-lg font-medium">{other.displayName}</div>
                <div className="text-white/60 text-sm">Waiting for peer video…</div>
              </div>
            </div>
          )}
        </div>
      )}

      {/* Local video PiP (real camera feed) */}
      {showVideo && (
        <div className="absolute top-16 right-3 z-20 w-24 sm:w-28 h-32 sm:h-36 rounded-2xl overflow-hidden border-2 border-white/20" style={{ background: "#000" }}>
          <video
            ref={localVideoRef}
            className="w-full h-full object-cover scale-x-[-1]"
            playsInline
            muted
          />
        </div>
      )}

      {/* Camera error banner */}
      {camError && callType === "video" && videoOn && (
        <div className="absolute top-20 left-3 right-3 z-30 bg-red-500/90 text-white text-xs px-3 py-2 rounded-xl">
          {camError}
        </div>
      )}

      {/* Connection status indicator */}
      <div className="absolute top-3 left-1/2 -translate-x-1/2 z-30 px-3 py-1 rounded-full text-[10px] font-mono"
        style={{ background: "rgba(0,0,0,0.4)", color: "white" }}>
        ● {connectionStatus}
      </div>

      {/* Header */}
      <header className="px-3 sm:px-4 pt-4 pb-2 flex items-center justify-between z-10 relative">
        <button
          onClick={() => setMinimized(!minimized)}
          className="neu-pressable rounded-full w-10 h-10 flex items-center justify-center text-white"
          aria-label="Minimize"
        >
          <ChevronDown size={20} />
        </button>
        <div className="text-white text-sm font-medium">
          {callType === "video" ? "Video call" : "Voice call"}
        </div>
        <button
          onClick={() => setShowInfo(!showInfo)}
          className="neu-pressable rounded-full w-10 h-10 flex items-center justify-center text-white"
          aria-label="Info"
        >
          <Info size={18} />
        </button>
      </header>

      {/* Caller info */}
      <div className="flex-1 flex flex-col items-center justify-center px-6 sm:px-8 z-10 relative">
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
          className={`text-xl sm:text-2xl font-bold mt-6 ${showVideo ? "text-white" : "neu-text"}`}
        >
          {other.displayName}
        </motion.h2>
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.5 }}
          className={`text-sm mt-1 font-mono ${showVideo ? "text-white/70" : "neu-text-muted"}`}
        >
          {other.zaxoNumber}
        </motion.div>
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          transition={{ delay: 0.7 }}
          className={`mt-3 text-sm ${showVideo ? "text-white/80" : "neu-text-muted"}`}
        >
          {statusText()}
        </motion.div>

        {state === "connected" && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            className="mt-2 text-xs text-white/50 neu-text-muted"
          >
            🔒 End-to-end encrypted · WebRTC P2P
          </motion.div>
        )}
      </div>

      {/* Action buttons */}
      <div className="px-4 sm:px-6 pb-6 sm:pb-8 z-10 relative">
        <div className="flex items-center justify-center gap-3 sm:gap-4 mb-4">
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
        </div>

        <div className="flex items-center justify-center gap-3 sm:gap-4">
          <CallButton
            icon={<ScreenShare size={22} />}
            label="Share"
            small
          />
          <CallButton
            icon={<UserPlus size={22} />}
            label="Add"
            small
          />
          <button
            onClick={handleEndCall}
            className="neu-danger rounded-full w-16 h-16 flex items-center justify-center scale-pulse active:scale-95 transition-transform"
            aria-label="End call"
          >
            <PhoneOff size={26} />
          </button>
        </div>
      </div>

      {/* Info sheet */}
      <AnimatePresence>
        {showInfo && (
          <motion.div
            initial={{ opacity: 0 }}
            animate={{ opacity: 1 }}
            exit={{ opacity: 0 }}
            onClick={() => setShowInfo(false)}
            className="absolute inset-0 z-40 flex items-end justify-center"
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
              <div className="w-12 h-1 rounded-full mx-auto neu-text-muted opacity-30 mb-3" />
              <h3 className="text-base font-semibold neu-text mb-3">Call info</h3>
              <div className="space-y-2 text-sm">
                <div className="flex justify-between"><span className="neu-text-muted">Contact</span><span className="neu-text">{other.displayName}</span></div>
                <div className="flex justify-between"><span className="neu-text-muted">Zaxo number</span><span className="neu-text font-mono">{other.zaxoNumber}</span></div>
                <div className="flex justify-between"><span className="neu-text-muted">Type</span><span className="neu-text capitalize">{callType} call</span></div>
                <div className="flex justify-between"><span className="neu-text-muted">Direction</span><span className="neu-text capitalize">{isIncoming ? "incoming" : "outgoing"}</span></div>
                <div className="flex justify-between"><span className="neu-text-muted">Status</span><span className="neu-text capitalize">{state}</span></div>
                <div className="flex justify-between"><span className="neu-text-muted">Connection</span><span className="neu-text font-mono">{connectionStatus}</span></div>
                {state === "connected" && (
                  <div className="flex justify-between"><span className="neu-text-muted">Duration</span><span className="neu-text font-mono">{formatDuration(seconds)}</span></div>
                )}
                <div className="flex justify-between"><span className="neu-text-muted">Encryption</span><span className="neu-text-success">End-to-end (DTLS-SRTP)</span></div>
                <div className="flex justify-between"><span className="neu-text-muted">Transport</span><span className="neu-text-success">WebRTC P2P</span></div>
              </div>
              <button
                onClick={handleEndCall}
                className="neu-danger rounded-2xl w-full py-3 mt-4 flex items-center justify-center gap-2 text-white font-medium"
              >
                <PhoneOff size={16} /> End call
              </button>
            </motion.div>
          </motion.div>
        )}
      </AnimatePresence>

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
            <button onClick={() => setMinimized(false)} className="neu-pressable rounded-full w-9 h-9 flex items-center justify-center neu-text" aria-label="Expand">
              <ChevronDown size={18} className="rotate-180" />
            </button>
            <button onClick={handleEndCall} className="neu-danger rounded-full w-9 h-9 flex items-center justify-center" aria-label="End call">
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
        aria-label={label}
      >
        {icon}
      </button>
      <span className="text-[10px] neu-text-muted">{label}</span>
    </div>
  );
}
