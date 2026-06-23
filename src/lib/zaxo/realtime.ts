// ==================== REALTIME SERVICE ====================
// Cross-tab / cross-device realtime via BroadcastChannel + WebRTC.
// This service powers:
//   - Real-time messaging between tabs
//   - Typing indicators
//   - Online/last-seen presence
//   - Call signaling (offer/answer/ICE) for 1:1 and group calls
//   - Read receipts
//   - Reaction broadcasts
//
// Each browser tab acts as a "device". The current user is identified by
// their Zaxo number. Other tabs in the same browser see each other as
// "remote users" — which is enough to demo real realtime without a backend.

"use client";

import type { Message } from "@/types";

type Listener<T = unknown> = (payload: T) => void;

export type RealtimeEvent =
  | { kind: "message"; chatId: string; message: Message; from: string }
  | { kind: "typing"; chatId: string; userId: string; typing: boolean; from: string }
  | { kind: "presence"; userId: string; online: boolean; lastSeen: number; from: string }
  | { kind: "read"; chatId: string; messageIds: string[]; from: string }
  | { kind: "reaction"; chatId: string; messageId: string; emoji: string; userId: string; from: string }
  | { kind: "status_view"; statusId: string; viewerId: string; from: string }
  // Call signaling
  | { kind: "call_invite"; callId: string; callerId: string; callerName: string; callType: "voice" | "video"; chatId: string; isGroup: boolean; from: string }
  | { kind: "call_accept"; callId: string; from: string }
  | { kind: "call_decline"; callId: string; from: string }
  | { kind: "call_end"; callId: string; from: string }
  | { kind: "call_sdp"; callId: string; sdp: RTCSessionDescriptionInit; from: string; to: string }
  | { kind: "call_ice"; callId: string; candidate: RTCIceCandidateInit; from: string; to: string }
  | { kind: "call_state"; callId: string; state: "ringing" | "connected" | "ended"; from: string };

const CHANNEL_NAME = "zaxo-realtime";
const HEARTBEAT_INTERVAL_MS = 5000;
const PRESENCE_TIMEOUT_MS = 12000;

class RealtimeService {
  private channel: BroadcastChannel | null = null;
  private listeners = new Set<Listener<RealtimeEvent>>();
  private myUserId: string = "me";
  private myDisplayName: string = "Me";
  private heartbeatTimer: ReturnType<typeof setInterval> | null = null;
  private presenceCheckTimer: ReturnType<typeof setInterval> | null = null;
  private presenceMap = new Map<string, { online: boolean; lastSeen: number }>();
  private initialized = false;

  init(userId: string, displayName: string) {
    if (this.initialized) return;
    this.initialized = true;
    this.myUserId = userId;
    this.myDisplayName = displayName;
    if (typeof window === "undefined") return;
    if (typeof BroadcastChannel === "undefined") {
      console.warn("[Zaxo] BroadcastChannel not supported — realtime disabled");
      return;
    }
    this.channel = new BroadcastChannel(CHANNEL_NAME);
    this.channel.onmessage = (e: MessageEvent<RealtimeEvent>) => {
      const ev = e.data;
      if (!ev || !ev.from || ev.from === this.myUserId) return; // skip own
      this.handleIncoming(ev);
    };
    // Initial presence announcement
    this.broadcast({ kind: "presence", userId: this.myUserId, online: true, lastSeen: Date.now(), from: this.myUserId });
    // Heartbeat
    this.heartbeatTimer = setInterval(() => {
      this.broadcast({ kind: "presence", userId: this.myUserId, online: true, lastSeen: Date.now(), from: this.myUserId });
    }, HEARTBEAT_INTERVAL_MS);
    // Periodic presence GC
    this.presenceCheckTimer = setInterval(() => {
      const now = Date.now();
      let changed = false;
      this.presenceMap.forEach((p, uid) => {
        if (p.online && now - p.lastSeen > PRESENCE_TIMEOUT_MS) {
          p.online = false;
          p.lastSeen = now;
          changed = true;
          this.emit({ kind: "presence", userId: uid, online: false, lastSeen: now, from: uid });
        }
      });
      if (changed) {
        // emit handled inline
      }
    }, PRESENCE_TIMEOUT_MS);
    // On tab close, announce offline
    window.addEventListener("beforeunload", () => {
      this.broadcast({ kind: "presence", userId: this.myUserId, online: false, lastSeen: Date.now(), from: this.myUserId });
    });
    // On tab hide, mark last seen
    document.addEventListener("visibilitychange", () => {
      if (document.visibilityState === "hidden") {
        this.broadcast({ kind: "presence", userId: this.myUserId, online: false, lastSeen: Date.now(), from: this.myUserId });
      } else {
        this.broadcast({ kind: "presence", userId: this.myUserId, online: true, lastSeen: Date.now(), from: this.myUserId });
      }
    });
  }

  private handleIncoming(ev: RealtimeEvent) {
    if (ev.kind === "presence") {
      this.presenceMap.set(ev.userId, { online: ev.online, lastSeen: ev.lastSeen });
    }
    this.emit(ev);
  }

  private emit(ev: RealtimeEvent) {
    this.listeners.forEach((fn) => {
      try { fn(ev); } catch (e) { console.error("[Zaxo] listener error", e); }
    });
  }

  subscribe(fn: Listener<RealtimeEvent>): () => void {
    this.listeners.add(fn);
    return () => { this.listeners.delete(fn); };
  }

  private broadcast(ev: RealtimeEvent) {
    if (!this.channel) return;
    try {
      this.channel.postMessage(ev);
    } catch (e) {
      console.error("[Zaxo] broadcast error", e);
    }
  }

  getMyUserId() { return this.myUserId; }

  // Presence queries
  getPresence(userId: string): { online: boolean; lastSeen: number } {
    return this.presenceMap.get(userId) ?? { online: false, lastSeen: 0 };
  }

  getAllOnlineUserIds(): string[] {
    const out: string[] = [];
    this.presenceMap.forEach((p, uid) => { if (p.online) out.push(uid); });
    return out;
  }

  // Public senders
  sendMessage(chatId: string, message: Message) {
    this.broadcast({ kind: "message", chatId, message, from: this.myUserId });
  }
  setTyping(chatId: string, typing: boolean, userId: string) {
    this.broadcast({ kind: "typing", chatId, userId, typing, from: this.myUserId });
  }
  markRead(chatId: string, messageIds: string[]) {
    this.broadcast({ kind: "read", chatId, messageIds, from: this.myUserId });
  }
  sendReaction(chatId: string, messageId: string, emoji: string, userId: string) {
    this.broadcast({ kind: "reaction", chatId, messageId, emoji, userId, from: this.myUserId });
  }
  sendStatusView(statusId: string, viewerId: string) {
    this.broadcast({ kind: "status_view", statusId, viewerId, from: this.myUserId });
  }

  // Call signaling
  inviteToCall(callId: string, callerName: string, callType: "voice" | "video", chatId: string, isGroup: boolean) {
    this.broadcast({ kind: "call_invite", callId, callerId: this.myUserId, callerName, callType, chatId, isGroup, from: this.myUserId });
  }
  acceptCall(callId: string) {
    this.broadcast({ kind: "call_accept", callId, from: this.myUserId });
  }
  declineCall(callId: string) {
    this.broadcast({ kind: "call_decline", callId, from: this.myUserId });
  }
  endCall(callId: string) {
    this.broadcast({ kind: "call_end", callId, from: this.myUserId });
  }
  sendSdp(callId: string, sdp: RTCSessionDescriptionInit, to: string) {
    this.broadcast({ kind: "call_sdp", callId, sdp, from: this.myUserId, to });
  }
  sendIce(callId: string, candidate: RTCIceCandidateInit, to: string) {
    this.broadcast({ kind: "call_ice", callId, candidate, from: this.myUserId, to });
  }
  sendCallState(callId: string, state: "ringing" | "connected" | "ended") {
    this.broadcast({ kind: "call_state", callId, state, from: this.myUserId });
  }
}

export const realtime = new RealtimeService();
