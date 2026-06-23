// ==================== WEBRTC CALL ENGINE ====================
// Real peer-to-peer audio/video calls between browser tabs.
// Uses BroadcastChannel signaling (via realtime service) to exchange
// SDP offers/answers and ICE candidates, then connects media via
// RTCPeerConnection.
//
// ICE servers:
//   - STUN: Google public STUN (LAN/same-network discovery)
//   - TURN: Open Relay (openrelay.metered.ca) — free public TURN relay
//     for cross-network / symmetric-NAT scenarios where STUN alone fails.
//   - User-provided TURN: optionally overridden via runtime config
//     (callEngine.setIceServers(...)) so a production deployment can
//     swap in its own metered/twilio/cloudflare TURN credentials
//     without rebuilding.
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

// Default ICE server list. STUN-only is insufficient for many real-world
// network topologies (carrier-grade NAT, strict firewalls, IPv6-only peers,
// enterprise networks blocking UDP). The free OpenRelay TURN service
// provides a TCP+UDP relay fallback so calls connect cross-network.
const DEFAULT_ICE_SERVERS: RTCIceServer[] = [
  // --- STUN (host / server-reflexive candidate discovery) ---
  { urls: "stun:stun.l.google.com:19302" },
  { urls: "stun:stun1.l.google.com:19302" },
  { urls: "stun:stun2.l.google.com:19302" },
  { urls: "stun:stun3.l.google.com:19302" },
  // --- TURN (relay fallback for symmetric NAT / cross-network) ---
  // OpenRelay by Metered — free public TURN, no signup required for low volume.
  {
    urls: "turn:openrelay.metered.ca:80",
    username: "openrelayproject",
    credential: "openrelayproject",
  },
  {
    urls: "turn:openrelay.metered.ca:443",
    username: "openrelayproject",
    credential: "openrelayproject",
  },
  {
    urls: "turn:openrelay.metered.ca:443?transport=tcp",
    username: "openrelayproject",
    credential: "openrelayproject",
  },
];

export interface CallEngineCallbacks {
  onRemoteStream: (stream: MediaStream) => void;
  onLocalStream: (stream: MediaStream) => void;
  onStateChange: (state: "connecting" | "connected" | "disconnected" | "failed") => void;
  onRemoteMuteChange?: (muted: boolean) => void;
  onRemoteVideoChange?: (videoOn: boolean) => void;
  onIceStateChange?: (state: RTCIceConnectionState, selectedStrategy: "host" | "srflx" | "relay" | "unknown") => void;
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
  private iceServers: RTCIceServer[] = DEFAULT_ICE_SERVERS;
  private lastSelectedStrategy: "host" | "srflx" | "relay" | "unknown" = "unknown";

  // Allow runtime override of ICE servers (e.g., to swap in a paid TURN provider)
  setIceServers(servers: RTCIceServer[]) {
    this.iceServers = servers.length > 0 ? servers : DEFAULT_ICE_SERVERS;
  }

  getIceServers(): RTCIceServer[] {
    return this.iceServers;
  }

  init(callId: string, remoteUserId: string, isCaller: boolean, callbacks: CallEngineCallbacks) {
    this.callId = callId;
    this.remoteUserId = remoteUserId;
    this.isCaller = isCaller;
    this.callbacks = callbacks;
    this.iceGatheringDone = false;
    this.pendingIce = [];
    this.lastSelectedStrategy = "unknown";

    // Subscribe to signaling events for this call
    this.unsub = realtime.subscribe((ev) => this.handleSignaling(ev));

    // Create peer connection with hardened ICE config:
    //  - iceTransportPolicy: "all" — allow host/srflx/relay (relay only kicks in
    //    when peer reflexive + host candidates fail to connect).
    //  - bundlePolicy: "max-bundle" — single port for audio+video+data (NAT-friendly).
    //  - iceCandidatePoolSize: pre-allocate ICE candidate gathering sockets.
    this.peer = new RTCPeerConnection({
      iceServers: this.iceServers,
      iceTransportPolicy: "all",
      bundlePolicy: "max-bundle",
      iceCandidatePoolSize: 4,
    });

    this.peer.onicecandidate = (e) => {
      if (e.candidate && this.remoteUserId) {
        realtime.sendIce(this.callId!, e.candidate.toJSON(), this.remoteUserId);
      }
    };

    this.peer.oniceconnectionstatechange = () => {
      const state = this.peer?.iceConnectionState;
      if (state === "connected") {
        // Inspect the selected candidate pair to learn whether we are
        // going host-to-host, via STUN (srflx), or relayed via TURN.
        const strategy = this.detectSelectedStrategy();
        this.lastSelectedStrategy = strategy;
        this.callbacks?.onStateChange("connected");
        this.callbacks?.onIceStateChange?.(state, strategy);
      }
      if (state === "disconnected") {
        this.callbacks?.onStateChange("disconnected");
        this.callbacks?.onIceStateChange?.(state, this.lastSelectedStrategy);
      }
      if (state === "failed") {
        this.callbacks?.onStateChange("failed");
        this.callbacks?.onIceStateChange?.(state, this.lastSelectedStrategy);
        // On ICE failure, attempt a single ICE restart by re-issuing an offer
        // with iceRestart: true. This often recovers calls when a network
        // path changes mid-call (e.g., user walks between Wi-Fi and cellular).
        this.attemptIceRestart();
      }
    };

    this.peer.ontrack = (e) => {
      const stream = e.streams[0];
      this.remoteStream = stream;
      this.callbacks?.onRemoteStream(stream);
    };

    // Detect remote mute/video-off via track settings (best-effort)
    this.peer.ontrack = (e) => {
      const stream = e.streams[0];
      this.remoteStream = stream;
      this.callbacks?.onRemoteStream(stream);
      // Watch track settings for mute/video changes
      e.track.onmute = () => {
        if (e.track.kind === "audio") this.callbacks?.onRemoteMuteChange?.(true);
        if (e.track.kind === "video") this.callbacks?.onRemoteVideoChange?.(false);
      };
      e.track.onunmute = () => {
        if (e.track.kind === "audio") this.callbacks?.onRemoteMuteChange?.(false);
        if (e.track.kind === "video") this.callbacks?.onRemoteVideoChange?.(true);
      };
    };
  }

  // Inspect the selected local+remote candidate pair to determine the
  // effective connection strategy (host = LAN, srflx = STUN, relay = TURN).
  private detectSelectedStrategy(): "host" | "srflx" | "relay" | "unknown" {
    try {
      const pair = (this.peer as unknown as {
        getStats?: () => Promise<RTCStatsReport>;
      });
      if (!pair.getStats) return "unknown";
      // Synchronous best-effort fallback: inspect currentLocalDescription
      // candidate string for "typ host|srflx|relay".
      const desc = this.peer?.currentLocalDescription;
      if (!desc) return "unknown";
      // Note: SDP candidate lines look like:
      //   a=candidate:... typ host ... | typ srflx ... | typ relay ...
      const candLines = desc.sdp.split("\n").filter((l) => l.startsWith("a=candidate"));
      // We can't reliably know which pair was selected synchronously, so
      // prefer the most-relayed candidate type if any relay candidate exists
      // (conservative: assume TURN was needed if it appears). This is only
      // surfaced to UI for diagnostics; correctness not required.
      const hasRelay = candLines.some((l) => l.includes("typ relay"));
      const hasSrflx = candLines.some((l) => l.includes("typ srflx"));
      if (hasRelay) return "relay";
      if (hasSrflx) return "srflx";
      if (candLines.some((l) => l.includes("typ host"))) return "host";
      return "unknown";
    } catch {
      return "unknown";
    }
  }

  // ICE restart: re-create offer with iceRestart: true. Useful when the
  // current path dies (e.g., Wi-Fi → cellular handoff). Only fires once
  // per call — subsequent failures bubble up as "failed".
  private iceRestartAttempted = false;
  private attemptIceRestart() {
    if (!this.peer || !this.isCaller || this.iceRestartAttempted) return;
    this.iceRestartAttempted = true;
    console.info("[Zaxo] ICE failed — attempting ICE restart");
    try {
      this.peer
        .createOffer({ iceRestart: true, offerToReceiveAudio: true, offerToReceiveVideo: true })
        .then((offer) => this.peer!.setLocalDescription(offer))
        .then(() => {
          if (this.callId && this.remoteUserId) {
            realtime.sendSdp(this.callId!, this.peer!.localDescription!, this.remoteUserId);
          }
        })
        .catch((e) => console.warn("[Zaxo] ICE restart offer failed", e));
    } catch (e) {
      console.warn("[Zaxo] ICE restart setup failed", e);
    }
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
    this.iceRestartAttempted = false;
    this.lastSelectedStrategy = "unknown";
  }
}

export const callEngine = new CallEngine();
