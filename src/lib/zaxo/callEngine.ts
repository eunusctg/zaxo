// ==================== WEBRTC CALL ENGINE ====================
// Real peer-to-peer audio/video calls between browser tabs.
// Uses BroadcastChannel signaling (via realtime service) to exchange
// SDP offers/answers and ICE candidates, then connects media via
// RTCPeerConnection. STUN-only (no TURN) — works on LAN / same network.
//
// Lifecycle:
//   1. Caller: startCall() → createOffer → sendSdp → wait for answer
//   2. Callee: receives call_invite → acceptCall() → createAnswer → sendSdp
//   3. Both: ICE candidates exchanged trickle-style
//   4. On connected: local stream → addTrack → peer sends to remote
//   5. Remote stream received via ontrack → attach to remote video element
//   6. endCall() closes peer + stops tracks

"use client";

import { realtime } from "./realtime";
import type { RealtimeEvent } from "./realtime";

const ICE_SERVERS: RTCIceServer[] = [
  { urls: "stun:stun.l.google.com:19302" },
  { urls: "stun:stun1.l.google.com:19302" },
  { urls: "stun:stun2.l.google.com:19302" },
  { urls: "stun:stun3.l.google.com:19302" },
];

export interface CallEngineCallbacks {
  onRemoteStream: (stream: MediaStream) => void;
  onLocalStream: (stream: MediaStream) => void;
  onStateChange: (state: "connecting" | "connected" | "disconnected" | "failed") => void;
  onRemoteMuteChange?: (muted: boolean) => void;
  onRemoteVideoChange?: (videoOn: boolean) => void;
}

class CallEngine {
  private peer: RTCPeerConnection | null = null;
  private localStream: MediaStream | null = null;
  private remoteStream: MediaStream | null = null;
  private callId: string | null = null;
  private remoteUserId: string | null = null;
  private isCaller: boolean = false;
  private callbacks: CallEngineCallbacks | null = null;
  private iceGatheringDone = false;
  private pendingIce: RTCIceCandidateInit[] = [];
  private unsub: (() => void) | null = null;

  init(callId: string, remoteUserId: string, isCaller: boolean, callbacks: CallEngineCallbacks) {
    this.callId = callId;
    this.remoteUserId = remoteUserId;
    this.isCaller = isCaller;
    this.callbacks = callbacks;
    this.iceGatheringDone = false;
    this.pendingIce = [];

    // Subscribe to signaling events for this call
    this.unsub = realtime.subscribe((ev) => this.handleSignaling(ev));

    // Create peer connection
    this.peer = new RTCPeerConnection({ iceServers: ICE_SERVERS });
    this.peer.onicecandidate = (e) => {
      if (e.candidate && this.remoteUserId) {
        realtime.sendIce(this.callId!, e.candidate.toJSON(), this.remoteUserId);
      }
    };
    this.peer.oniceconnectionstatechange = () => {
      const state = this.peer?.iceConnectionState;
      if (state === "connected") this.callbacks?.onStateChange("connected");
      if (state === "disconnected") this.callbacks?.onStateChange("disconnected");
      if (state === "failed") this.callbacks?.onStateChange("failed");
    };
    this.peer.ontrack = (e) => {
      const stream = e.streams[0];
      this.remoteStream = stream;
      this.callbacks?.onRemoteStream(stream);
    };
  }

  private handleSignaling(ev: RealtimeEvent) {
    // Only handle call signaling events that have callId
    if (!("callId" in ev)) return;
    if (!this.callId || ev.callId !== this.callId) return;
    if (!this.peer) return;
    if (ev.kind === "call_sdp" && ev.to === realtime.getMyUserId()) {
      const desc = ev.sdp;
      if (desc.type === "answer" && this.isCaller) {
        this.peer.setRemoteDescription(new RTCSessionDescription(desc)).catch((e) => console.warn("[Zaxo] setRemote answer failed", e));
      } else if (desc.type === "offer" && !this.isCaller) {
        this.peer.setRemoteDescription(new RTCSessionDescription(desc))
          .then(() => this.createAnswer())
          .catch((e) => console.warn("[Zaxo] setRemote offer failed", e));
      }
    } else if (ev.kind === "call_ice" && ev.to === realtime.getMyUserId()) {
      const c = ev.candidate;
      if (c) {
        this.peer.addIceCandidate(new RTCIceCandidate(c)).catch((e) => console.warn("[Zaxo] addIce failed", e));
      }
    }
  }

  async acquireLocalMedia(withVideo: boolean): Promise<MediaStream> {
    const stream = await navigator.mediaDevices.getUserMedia({
      audio: true,
      video: withVideo ? { facingMode: "user", width: { ideal: 640 }, height: { ideal: 480 } } : false,
    });
    this.localStream = stream;
    this.callbacks?.onLocalStream(stream);
    // Add tracks to peer
    if (this.peer) {
      stream.getTracks().forEach((t) => this.peer!.addTrack(t, stream));
    }
    return stream;
  }

  async createOffer() {
    if (!this.peer || !this.remoteUserId) return;
    try {
      const offer = await this.peer.createOffer({ offerToReceiveAudio: true, offerToReceiveVideo: true });
      await this.peer.setLocalDescription(offer);
      realtime.sendSdp(this.callId!, offer, this.remoteUserId);
    } catch (e) {
      console.error("[Zaxo] createOffer failed", e);
    }
  }

  private async createAnswer() {
    if (!this.peer || !this.remoteUserId) return;
    try {
      const answer = await this.peer.createAnswer();
      await this.peer.setLocalDescription(answer);
      realtime.sendSdp(this.callId!, answer, this.remoteUserId);
    } catch (e) {
      console.error("[Zaxo] createAnswer failed", e);
    }
  }

  toggleMute(muted: boolean) {
    if (this.localStream) {
      this.localStream.getAudioTracks().forEach((t) => (t.enabled = !muted));
    }
  }

  toggleVideo(videoOn: boolean) {
    if (this.localStream) {
      this.localStream.getVideoTracks().forEach((t) => (t.enabled = videoOn));
    }
  }

  endCall() {
    try { this.peer?.close(); } catch {}
    this.peer = null;
    this.localStream?.getTracks().forEach((t) => t.stop());
    this.localStream = null;
    this.remoteStream = null;
    this.unsub?.();
    this.unsub = null;
    this.callId = null;
    this.remoteUserId = null;
  }
}

export const callEngine = new CallEngine();
