// ==================== CALL STATE STORE ====================
// Tracks incoming-call UI state, active call state, and group call
// participant roster. Bridges realtime call-signaling events into
// reactive UI state.

"use client";

import { create } from "zustand";
import { realtime } from "@/lib/zaxo/realtime";

export interface IncomingCallInfo {
  callId: string;
  callerId: string;
  callerName: string;
  callType: "voice" | "video";
  chatId: string;
  isGroup: boolean;
}

export interface ActiveCallInfo {
  callId: string;
  otherUserId: string;
  callType: "voice" | "video";
  chatId?: string;
  isGroup: boolean;
  direction: "incoming" | "outgoing";
  state: "calling" | "ringing" | "connected" | "ended";
  startedAt: number;
}

interface CallStateState {
  incomingCall: IncomingCallInfo | null;
  activeCall: ActiveCallInfo | null;
  groupParticipants: string[]; // user ids currently in the group call

  setActiveCall: (call: ActiveCallInfo | null) => void;
  setIncomingCall: (call: IncomingCallInfo | null) => void;
  updateActiveCallState: (state: ActiveCallInfo["state"]) => void;
  addGroupParticipant: (userId: string) => void;
  removeGroupParticipant: (userId: string) => void;
  endActiveCall: () => void;
}

export const useCallStateStore = create<CallStateState>((set, get) => ({
  incomingCall: null,
  activeCall: null,
  groupParticipants: [],

  setActiveCall: (call) => set({ activeCall: call }),
  setIncomingCall: (call) => set({ incomingCall: call }),
  updateActiveCallState: (state) => {
    const cur = get().activeCall;
    if (!cur) return;
    set({ activeCall: { ...cur, state } });
  },
  addGroupParticipant: (userId) => {
    if (get().groupParticipants.includes(userId)) return;
    set({ groupParticipants: [...get().groupParticipants, userId] });
  },
  removeGroupParticipant: (userId) => {
    set({ groupParticipants: get().groupParticipants.filter((u) => u !== userId) });
  },
  endActiveCall: () => {
    set({ activeCall: null, incomingCall: null, groupParticipants: [] });
  },
}));

// Subscribe to realtime call events at module load (once)
if (typeof window !== "undefined") {
  realtime.subscribe((ev) => {
    const store = useCallStateStore.getState();
    if (ev.kind === "call_invite") {
      // Don't show incoming call if we're the caller or already in a call
      if (store.activeCall || store.incomingCall) return;
      store.setIncomingCall({
        callId: ev.callId,
        callerId: ev.callerId,
        callerName: ev.callerName,
        callType: ev.callType,
        chatId: ev.chatId,
        isGroup: ev.isGroup,
      });
    } else if (ev.kind === "call_accept") {
      // Callee accepted — caller transitions to ringing/connected
      if (store.activeCall && store.activeCall.callId === ev.callId) {
        store.updateActiveCallState("ringing");
      }
    } else if (ev.kind === "call_decline" || ev.kind === "call_end") {
      if (store.activeCall && store.activeCall.callId === ev.callId) {
        store.updateActiveCallState("ended");
        setTimeout(() => store.endActiveCall(), 800);
      }
      if (store.incomingCall && store.incomingCall.callId === ev.callId) {
        store.setIncomingCall(null);
      }
    } else if (ev.kind === "call_state") {
      if (store.activeCall && store.activeCall.callId === ev.callId) {
        store.updateActiveCallState(ev.state);
        if (ev.state === "ended") {
          setTimeout(() => store.endActiveCall(), 800);
        }
      }
    }
  });
}
