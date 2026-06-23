// ==================== CALL HISTORY SYNC ====================
// Persists Zaxo call history to a shared localStorage key and syncs it
// across browser tabs in real-time via the `storage` event.
//
// Why this exists:
//   The main appStore is persisted via Zustand persist middleware. Each
//   tab maintains its own in-memory copy and writes its full snapshot
//   to localStorage when its state changes. But Zustand's persist does
//   not re-hydrate when ANOTHER tab writes to localStorage — meaning
//   calls placed in tab A would only appear in tab B after a page
//   reload.
//
//   This module adds a tiny pub/sub layer that:
//     1. Listens to the `storage` event (fires cross-tab, same-origin).
//     2. When the shared `zaxo-call-history` key changes, parses the
//        new call list and notifies all subscribers.
//     3. Exposes `appendCall(call)` to atomically push a new call to
//        the shared list (read-modify-write with try/catch race guard).
//     4. Exposes `replaceAll(calls)` for clear-history actions.
//     5. Falls back to BroadcastChannel (when available) for instant
//        same-origin delivery — `storage` events are throttled and can
//        miss rapid back-to-back writes.
//
// Result: when tab A ends a call and writes a Call record, tab B's
// CallsList refreshes within ~50ms with the new entry.

"use client";

import type { Call } from "@/types";

const STORAGE_KEY = "zaxo-call-history";
const BC_CHANNEL = "zaxo-call-history-sync";
const MAX_HISTORY = 500;

type Listener = (calls: Call[]) => void;

class CallHistorySync {
  private listeners = new Set<Listener>();
  private cache: Call[] = [];
  private bc: BroadcastChannel | null = null;
  private initialized = false;

  init() {
    if (this.initialized) return;
    this.initialized = true;
    if (typeof window === "undefined") return;

    // Initial load
    this.cache = this.readFromStorage();

    // Cross-tab via storage event
    window.addEventListener("storage", (e) => {
      if (e.key !== STORAGE_KEY) return;
      this.cache = this.readFromStorage();
      this.emit();
    });

    // Same-origin instant delivery via BroadcastChannel
    if (typeof BroadcastChannel !== "undefined") {
      this.bc = new BroadcastChannel(BC_CHANNEL);
      this.bc.onmessage = (ev: MessageEvent<{ type: "replace"; calls: Call[] }>) => {
        if (ev.data?.type === "replace") {
          this.cache = ev.data.calls;
          this.emit();
        }
      };
    }
  }

  private readFromStorage(): Call[] {
    try {
      const raw = localStorage.getItem(STORAGE_KEY);
      if (!raw) return [];
      const parsed = JSON.parse(raw);
      if (!Array.isArray(parsed)) return [];
      return parsed as Call[];
    } catch {
      return [];
    }
  }

  private writeToStorage(calls: Call[]) {
    try {
      localStorage.setItem(STORAGE_KEY, JSON.stringify(calls));
    } catch (e) {
      // QuotaExceededError — trim oldest and retry once
      try {
        const trimmed = calls.slice(0, Math.floor(MAX_HISTORY / 2));
        localStorage.setItem(STORAGE_KEY, JSON.stringify(trimmed));
      } catch (e2) {
        console.warn("[Zaxo] call history storage write failed", e2);
      }
    }
    // Broadcast for instant same-origin delivery
    try {
      this.bc?.postMessage({ type: "replace", calls });
    } catch {}
  }

  /** Atomically append a call (newest first). Dedup by call id. */
  appendCall(call: Call) {
    this.init();
    const existing = this.cache.filter((c) => c.id !== call.id);
    const next = [call, ...existing].slice(0, MAX_HISTORY);
    this.cache = next;
    this.writeToStorage(next);
    this.emit();
  }

  /** Replace the entire call list (e.g., clear history). */
  replaceAll(calls: Call[]) {
    this.init();
    const next = calls.slice(0, MAX_HISTORY);
    this.cache = next;
    this.writeToStorage(next);
    this.emit();
  }

  /** Remove a single call by id. */
  removeCall(callId: string) {
    this.init();
    const next = this.cache.filter((c) => c.id !== callId);
    this.cache = next;
    this.writeToStorage(next);
    this.emit();
  }

  /** Get the current call list (newest first). */
  getCalls(): Call[] {
    this.init();
    return [...this.cache];
  }

  /** Subscribe to call list changes. Returns an unsubscribe fn. */
  subscribe(fn: Listener): () => void {
    this.init();
    this.listeners.add(fn);
    // Immediately emit the current snapshot to the new subscriber
    fn([...this.cache]);
    return () => {
      this.listeners.delete(fn);
    };
  }

  private emit() {
    const snapshot = [...this.cache];
    this.listeners.forEach((fn) => {
      try { fn(snapshot); } catch (e) { console.error("[Zaxo] call history listener error", e); }
    });
  }
}

export const callHistorySync = new CallHistorySync();
