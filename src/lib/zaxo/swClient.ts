// ==================== SERVICE WORKER CLIENT ====================
// Registers /sw.js, requests Notification permission, and bridges
// SW postMessage events (notification clicks) back into the React app
// via a tiny pub/sub.
//
// In production with a push provider (FCM, OneSignal, web-push), the SW
// receives real `push` events even when no Zaxo tab is open. Without a
// push provider, the SW still displays notifications queued from the app
// (so they survive tab close) and routes clicks even after a fresh
// page load.

"use client";

import { useEffect } from "react";

type SWAction =
  | { action: "answer" | "decline" | "open" | ""; category: string; chatId?: string; callId?: string; statusUserId?: string; url?: string };

type ActionListener = (action: SWAction) => void;
const listeners = new Set<ActionListener>();

let registered = false;

export function registerServiceWorker() {
  if (typeof window === "undefined") return;
  if (registered) return;
  if (!("serviceWorker" in navigator)) return;
  registered = true;

  // Register after window load to avoid competing with initial paint.
  const doRegister = () => {
    navigator.serviceWorker
      .register("/sw.js", { scope: "/" })
      .then((reg) => {
        // Ask for permission once SW is registered
        if ("Notification" in window && Notification.permission === "default") {
          // Don't auto-request here — let the app do it after authentication
          // to avoid the prompt firing before the user has context.
        }
        // Subscribe to push notifications via the SW's push manager
        if ("PushManager" in window) {
          reg.pushManager
            .subscribe({ userVisibleOnly: true, applicationServerKey: undefined })
            .catch((e) => {
              // No VAPID key configured — push subscription will fail.
              // The SW still handles local notifications + click routing.
              // To enable true server push, set a VAPID public key here.
              if (!String(e).includes("applicationServerKey")) {
                console.debug("[Zaxo SW] push subscribe skipped", e);
              }
            });
        }
      })
      .catch((e) => console.warn("[Zaxo SW] registration failed", e));

    // Bridge SW postMessage events to React listeners
    navigator.serviceWorker.addEventListener("message", (event) => {
      const data = event.data;
      if (!data || data.type !== "zaxo-sw-action") return;
      const action: SWAction = {
        action: data.action || "",
        category: data.category,
        chatId: data.chatId,
        callId: data.callId,
        statusUserId: data.statusUserId,
        url: data.url,
      };
      listeners.forEach((fn) => {
        try { fn(action); } catch (e) { console.error("[Zaxo SW] listener error", e); }
      });
    });
  };

  if (document.readyState === "complete") doRegister();
  else window.addEventListener("load", doRegister, { once: true });
}

/** Show a notification via the SW (survives tab close once displayed). */
export async function showNotificationViaSW(opts: {
  title: string;
  body: string;
  category: string;
  chatId?: string;
  callId?: string;
  statusUserId?: string;
  tag?: string;
  requireInteraction?: boolean;
}) {
  if (typeof navigator === "undefined" || !("serviceWorker" in navigator)) return;
  try {
    const reg = await navigator.serviceWorker.ready;
    reg.active?.postMessage({
      type: "zaxo-show-notification",
      ...opts,
    });
  } catch (e) {
    console.warn("[Zaxo SW] showNotification failed", e);
  }
}

/** Subscribe to SW notification actions (clicks). Returns unsubscribe fn. */
export function onSWAction(fn: ActionListener): () => void {
  listeners.add(fn);
  return () => { listeners.delete(fn); };
}
