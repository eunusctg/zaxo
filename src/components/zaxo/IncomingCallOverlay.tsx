// ==================== INCOMING CALL OVERLAY ====================
// Full-screen overlay shown when another tab/user calls us.
// Uses real ringtone (WebAudio synthesized), Answer/Decline buttons.
// On Answer: opens CallScreen in "incoming" mode + accepts via realtime.

"use client";

import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Phone, PhoneOff, Video, Mic } from "lucide-react";
import { NeuAvatar } from "@/components/neumorphic/NeuAvatar";
import { useCallStateStore } from "@/store/callStateStore";
import { useAppStore } from "@/store/appStore";
import { useUIStore } from "@/store/uiStore";
import { useAuthStore } from "@/store/authStore";
import { realtime } from "@/lib/zaxo/realtime";
import { notifications } from "@/lib/zaxo/notifications";

export function IncomingCallOverlay() {
  const { incomingCall, setIncomingCall, setActiveCall } = useCallStateStore();
  const { contacts } = useAppStore();
  const { setSubPanel } = useUIStore();
  const { user } = useAuthStore();
  const [callerContact, setCallerContact] = useState<{ avatarInitial: string; avatarColor: string; displayName: string; zaxoNumber: string } | null>(null);

  useEffect(() => {
    if (!incomingCall) {
      notifications.stopRingtone();
      return;
    }
    notifications.playRingtone();
    // Fire system notification for incoming call
    notifications.notify(
      `call_${incomingCall.callId}`,
      incomingCall.isGroup ? "call_group" : "call_incoming",
      incomingCall.callerName,
      `Incoming ${incomingCall.callType} call${incomingCall.isGroup ? " (group)" : ""}`,
      {
        callId: incomingCall.callId,
        tag: `call_${incomingCall.callId}`,
        requireInteraction: true,
      },
    );
    return () => {
      notifications.stopRingtone();
      notifications.cancel(`call_${incomingCall.callId}`);
    };
  }, [incomingCall]);

  // Resolve caller contact for avatar
  useEffect(() => {
    if (!incomingCall) {
      setCallerContact(null);
      return;
    }
    const c = contacts.find((ct) => ct.id === incomingCall.callerId || ct.zaxoNumber === incomingCall.callerName);
    if (c) {
      setCallerContact({
        avatarInitial: c.avatarInitial,
        avatarColor: c.avatarColor,
        displayName: c.displayName,
        zaxoNumber: c.zaxoNumber,
      });
    } else {
      setCallerContact({
        avatarInitial: incomingCall.callerName.charAt(0).toUpperCase(),
        avatarColor: "linear-gradient(135deg, #6C5CE7 0%, #A29BFE 100%)",
        displayName: incomingCall.callerName,
        zaxoNumber: "",
      });
    }
  }, [incomingCall, contacts]);

  function handleAnswer() {
    if (!incomingCall) return;
    realtime.acceptCall(incomingCall.callId);
    setActiveCall({
      callId: incomingCall.callId,
      otherUserId: incomingCall.callerId,
      callType: incomingCall.callType,
      chatId: incomingCall.chatId,
      isGroup: incomingCall.isGroup,
      direction: "incoming",
      state: "connected",
      startedAt: Date.now(),
    });
    setSubPanel({ type: "call_screen", otherUserId: incomingCall.callerId, callType: incomingCall.callType });
    setIncomingCall(null);
  }

  function handleDecline() {
    if (!incomingCall) return;
    realtime.declineCall(incomingCall.callId);
    setIncomingCall(null);
  }

  return (
    <AnimatePresence>
      {incomingCall && callerContact && (
        <motion.div
          initial={{ opacity: 0 }}
          animate={{ opacity: 1 }}
          exit={{ opacity: 0 }}
          className="absolute inset-0 z-50 flex flex-col items-center justify-between py-12 px-6"
          style={{
            background: "linear-gradient(180deg, rgba(108, 92, 231, 0.95) 0%, rgba(40, 30, 80, 0.98) 100%)",
            backdropFilter: "blur(20px)",
          }}
        >
          {/* Caller info */}
          <div className="flex flex-col items-center mt-8">
            <motion.div
              initial={{ scale: 0.7, opacity: 0 }}
              animate={{ scale: 1, opacity: 1 }}
              transition={{ type: "spring", damping: 20 }}
              className="relative"
            >
              {/* Pulse rings */}
              <div className="absolute inset-0 rounded-full animate-ping" style={{ background: "rgba(255,255,255,0.2)", animationDuration: "2s" }} />
              <div className="absolute inset-0 rounded-full animate-ping" style={{ background: "rgba(255,255,255,0.15)", animationDuration: "2s", animationDelay: "0.7s" }} />
              <NeuAvatar
                initial={callerContact.avatarInitial}
                gradient={callerContact.avatarColor}
                size={130}
              />
            </motion.div>
            <motion.h2
              initial={{ opacity: 0, y: 10 }}
              animate={{ opacity: 1, y: 0 }}
              transition={{ delay: 0.2 }}
              className="text-white text-2xl font-bold mt-6"
            >
              {callerContact.displayName}
            </motion.h2>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.3 }}
              className="text-white/70 text-sm font-mono mt-1"
            >
              {callerContact.zaxoNumber}
            </motion.div>
            <motion.div
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              transition={{ delay: 0.4 }}
              className="flex items-center gap-2 mt-4 px-4 py-2 rounded-full"
              style={{ background: "rgba(255,255,255,0.1)" }}
            >
              {incomingCall.callType === "video" ? <Video size={16} className="text-white" /> : <Mic size={16} className="text-white" />}
              <span className="text-white text-sm font-medium">
                Incoming {incomingCall.callType} call{incomingCall.isGroup ? " · group" : ""}
              </span>
            </motion.div>
          </div>

          {/* Action buttons */}
          <motion.div
            initial={{ opacity: 0, y: 30 }}
            animate={{ opacity: 1, y: 0 }}
            transition={{ delay: 0.5 }}
            className="flex items-center gap-12"
          >
            <button
              onClick={handleDecline}
              className="flex flex-col items-center gap-2 active:scale-95 transition-transform"
              aria-label="Decline"
            >
              <div
                className="w-16 h-16 rounded-full flex items-center justify-center"
                style={{
                  background: "linear-gradient(135deg, #ff6b6b, #ee0a0a)",
                  boxShadow: "0 8px 24px rgba(238, 10, 10, 0.5)",
                }}
              >
                <PhoneOff size={26} className="text-white" />
              </div>
              <span className="text-white/80 text-xs">Decline</span>
            </button>
            <button
              onClick={handleAnswer}
              className="flex flex-col items-center gap-2 active:scale-95 transition-transform"
              aria-label="Answer"
            >
              <motion.div
                animate={{ scale: [1, 1.05, 1] }}
                transition={{ duration: 1.2, repeat: Infinity }}
                className="w-16 h-16 rounded-full flex items-center justify-center"
                style={{
                  background: "linear-gradient(135deg, #43e97b, #38f9d7)",
                  boxShadow: "0 8px 24px rgba(67, 233, 123, 0.5)",
                }}
              >
                {incomingCall.callType === "video"
                  ? <Video size={26} className="text-white" />
                  : <Phone size={26} className="text-white" />}
              </motion.div>
              <span className="text-white/80 text-xs">Answer</span>
            </button>
          </motion.div>
        </motion.div>
      )}
    </AnimatePresence>
  );
}
