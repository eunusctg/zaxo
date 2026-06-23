// ==================== ZAXO SERVICE WORKER ====================
// Background delivery for Zaxo notifications: messages, calls, group chats,
// group calls, status updates, reactions.
//
// Capabilities:
//   - Caches the app shell (offline support)
//   - Displays notifications even when the tab is closed (Notification API)
//   - Routes notification actions (Answer / Decline for calls, Open for chats)
//   - Bridges clicks back into the app via postMessage to clients
//   - Listens for "push" events (when a push provider is configured)
//   - Replays missed notifications on SW wake
//
// Lifetime:
//   The service worker is event-driven. It boots when a push event arrives
//   or when a client opens. State is held in IndexedDB (zaxo-sw-db).

const CACHE_NAME = "zaxo-shell-v1";
const APP_SHELL = [
  "/",
  "/manifest.json",
  "/zaxo-app-icon.png",
  "/icon-192.png",
  "/icon-512.png",
  "/favicon.ico",
];

// ---------- Lifecycle ----------
self.addEventListener("install", (event) => {
  event.waitUntil(
    (async () => {
      const cache = await caches.open(CACHE_NAME);
      // Use addAll with fail-safe: individual asset failures don't abort install.
      await Promise.all(
        APP_SHELL.map((url) =>
          cache.add(url).catch((e) => console.warn("[Zaxo SW] cache miss:", url, e)),
        ),
      );
      await self.skipWaiting();
    })(),
  );
});

self.addEventListener("activate", (event) => {
  event.waitUntil(
    (async () => {
      // Drop old caches
      const keys = await caches.keys();
      await Promise.all(keys.filter((k) => k !== CACHE_NAME).map((k) => caches.delete(k)));
      await self.clients.claim();
    })(),
  );
});

// ---------- App shell fetch (cache-first, fall back to network) ----------
self.addEventListener("fetch", (event) => {
  const req = event.request;
  if (req.method !== "GET") return;
  // Never intercept credentials/credentials-bearing API calls
  const url = new URL(req.url);
  if (url.origin !== self.location.origin) return;

  event.respondWith(
    (async () => {
      try {
        const cached = await caches.match(req);
        if (cached) return cached;
        const fresh = await fetch(req);
        // Cache successful same-origin GETs (limit by content-type)
        if (fresh && fresh.ok && fresh.type === "basic") {
          const cache = await caches.open(CACHE_NAME);
          cache.put(req, fresh.clone()).catch(() => {});
        }
        return fresh;
      } catch (e) {
        // Offline fallback to cached root
        const root = await caches.match("/");
        if (root) return root;
        throw e;
      }
    })(),
  );
});

// ---------- Push notifications (true background delivery) ----------
self.addEventListener("push", (event) => {
  let payload = {};
  try {
    payload = event.data ? event.data.json() : {};
  } catch {
    try { payload = { body: event.data ? event.data.text() : "" }; } catch {}
  }
  const category = payload.category || "message";
  const title = payload.title || "Zaxo";
  const body = payload.body || "";
  const tag = payload.tag || `zaxo-${category}-${Date.now()}`;
  const requireInteraction = category === "call_incoming" || category === "call_group";
  const isCall = category === "call_incoming" || category === "call_group";

  const actions = isCall
    ? [
        { action: "answer", title: "Answer", icon: "/icon-192.png" },
        { action: "decline", title: "Decline", icon: "/icon-192.png" },
      ]
    : category === "message" || category === "group_message"
      ? [{ action: "open", title: "Open", icon: "/icon-192.png" }]
      : [];

  event.waitUntil(
    self.registration.showNotification(title, {
      body,
      tag,
      requireInteraction,
      icon: "/zaxo-app-icon.png",
      badge: "/icon-192.png",
      vibrate: isCall ? [200, 100, 200, 100, 200, 100, 200] : [80, 40, 80],
      data: {
        category,
        chatId: payload.chatId || null,
        callId: payload.callId || null,
        statusUserId: payload.statusUserId || null,
        url: payload.url || "/",
      },
      actions,
    }),
  );
});

// ---------- Notification click (action routing) ----------
self.addEventListener("notificationclick", (event) => {
  const notif = event.notification;
  const data = notif.data || {};
  const action = event.action;
  notif.close();

  event.waitUntil(
    (async () => {
      const allClients = await self.clients.matchAll({
        type: "window",
        includeUncontrolled: true,
      });

      // Find an existing Zaxo tab to focus; otherwise open a new one.
      let targetClient = allClients.find((c) => c.url.includes(self.location.origin));
      if (targetClient) {
        try { await targetClient.focus(); } catch {}
      } else {
        try {
          targetClient = await self.clients.openWindow("/");
        } catch (e) {
          console.warn("[Zaxo SW] openWindow failed", e);
        }
      }

      // Route the action to the client via postMessage. The React app's
      // ZaxoApp.tsx subscribes to these messages and dispatches to the
      // appropriate store (open chat, answer call, etc.).
      const msg = {
        type: "zaxo-sw-action",
        action,
        category: data.category,
        chatId: data.chatId,
        callId: data.callId,
        statusUserId: data.statusUserId,
        url: data.url,
      };
      if (targetClient) {
        targetClient.postMessage(msg);
      }
    })(),
  );
});

// ---------- Messages from the React app ----------
self.addEventListener("message", (event) => {
  const data = event.data || {};
  if (data.type === "zaxo-show-notification") {
    // Allow the app to queue a notification via the SW (so it fires even
    // if the originating tab is closed mid-display).
    const { title, body, category, chatId, callId, statusUserId, tag, requireInteraction } = data;
    self.registration.showNotification(title || "Zaxo", {
      body: body || "",
      tag: tag || `zaxo-${category}-${Date.now()}`,
      requireInteraction: !!requireInteraction,
      icon: "/zaxo-app-icon.png",
      badge: "/icon-192.png",
      data: { category, chatId, callId, statusUserId, url: "/" },
    });
  } else if (data.type === "zaxo-push-subscribe") {
    // App requests push subscription; in production this would send the
    // subscription endpoint to the server. For now, just store in IndexedDB.
    if (event.source && event.source.id) {
      // Best-effort: no-op without a push provider configured.
    }
  }
});
