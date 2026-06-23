// ==================== NOTIFICATION SERVICE ====================
// Real browser notifications + in-app notification queue.
// Fires system notifications for: incoming messages, group messages,
// incoming calls, group calls, status updates, missed calls, reactions.
//
// Respects settings from settingsStore: quiet hours, hide content,
// per-category toggles. Also routes click actions back into the app
// (e.g., opening the relevant chat when a message notification is clicked).

"use client";

import { realtime } from "./realtime";
import type { Settings } from "@/types";

export type NotificationCategory =
  | "message"
  | "group_message"
  | "call_incoming"
  | "call_group"
  | "call_missed"
  | "status"
  | "reaction";

export interface NotificationConfig {
  settings: Settings;
  onChatClick?: (chatId: string) => void;
  onCallAnswer?: (callId: string) => void;
  onCallDecline?: (callId: string) => void;
  onStatusClick?: (userId: string) => void;
}

// NotificationAction type (not in all TS lib versions)
type NotifAction = { action: string; title: string; icon?: string };

class NotificationService {
  private permission: NotificationPermission = "default";
  private config: NotificationConfig | null = null;
  private activeNotifications = new Map<string, Notification>();
  private inAppQueue: Array<{ id: string; category: NotificationCategory; title: string; body: string; timestamp: number; chatId?: string }> = [];
  private inAppListeners = new Set<(queue: NotificationService["inAppQueue"]) => void>();
  private ringtoneAudio: HTMLAudioElement | null = null;
  private messageToneAudio: HTMLAudioElement | null = null;

  init() {
    if (typeof window === "undefined") return;
    if (!("Notification" in window)) {
      console.warn("[Zaxo] Notifications API not supported");
      return;
    }
    this.permission = Notification.permission;
  }

  async requestPermission(): Promise<NotificationPermission> {
    if (typeof window === "undefined" || !("Notification" in window)) return "denied";
    try {
      this.permission = await Notification.requestPermission();
    } catch {
      this.permission = "denied";
    }
    return this.permission;
  }

  getPermission(): NotificationPermission {
    return this.permission;
  }

  configure(config: NotificationConfig) {
    this.config = config;
  }

  // Quiet hours check
  private isInQuietHours(settings: Settings): boolean {
    if (!settings.quietHoursEnabled) return false;
    const now = new Date();
    const cur = now.getHours() * 60 + now.getMinutes();
    const [sh, sm] = settings.quietHoursStart.split(":").map(Number);
    const [eh, em] = settings.quietHoursEnd.split(":").map(Number);
    const start = sh * 60 + sm;
    const end = eh * 60 + em;
    if (start === end) return false;
    if (start < end) return cur >= start && cur < end;
    // wraps midnight
    return cur >= start || cur < end;
  }

  private categoryEnabled(category: NotificationCategory, settings: Settings): boolean {
    switch (category) {
      case "message": return settings.messageNotifications;
      case "group_message": return settings.groupNotifications;
      case "call_incoming":
      case "call_group":
      case "call_missed": return settings.callNotifications;
      case "status": return settings.statusNotifications;
      case "reaction": return settings.reactionNotifications;
      default: return true;
    }
  }

  // Build a body string respecting hideNotificationContent / showPreview
  private bodyFor(category: NotificationCategory, body: string, settings: Settings): string {
    if (settings.hideNotificationContent || !settings.showPreview) {
      if (category === "call_incoming" || category === "call_group") return "Incoming call";
      if (category === "call_missed") return "Missed call";
      if (category === "message" || category === "group_message") return "New message";
      if (category === "status") return "New status update";
      if (category === "reaction") return "New reaction";
      return "New activity";
    }
    return body;
  }

  // Play ringtone (for incoming calls)
  playRingtone() {
    if (typeof window === "undefined") return;
    try {
      // Synthesized ringtone via WebAudio (no asset needed)
      const ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
      const playTone = (freq: number, start: number, duration: number) => {
        const osc = ctx.createOscillator();
        const gain = ctx.createGain();
        osc.type = "sine";
        osc.frequency.value = freq;
        osc.connect(gain);
        gain.connect(ctx.destination);
        gain.gain.setValueAtTime(0, ctx.currentTime + start);
        gain.gain.linearRampToValueAtTime(0.3, ctx.currentTime + start + 0.05);
        gain.gain.linearRampToValueAtTime(0, ctx.currentTime + start + duration);
        osc.start(ctx.currentTime + start);
        osc.stop(ctx.currentTime + start + duration);
      };
      // Two-tone ring (440 / 620 Hz), 0.5s on / 0.3s off, repeating
      playTone(440, 0, 0.4);
      playTone(620, 0.45, 0.4);
      playTone(440, 1.0, 0.4);
      playTone(620, 1.45, 0.4);
      this.ringtoneAudio = { stop: () => ctx.close() } as any;
    } catch (e) {
      console.warn("[Zaxo] ringtone play failed", e);
    }
  }

  stopRingtone() {
    try { (this.ringtoneAudio as any)?.stop?.(); } catch {}
    this.ringtoneAudio = null;
  }

  // Play message tone (short beep)
  playMessageTone() {
    if (typeof window === "undefined") return;
    try {
      const ctx = new (window.AudioContext || (window as any).webkitAudioContext)();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();
      osc.type = "sine";
      osc.frequency.value = 880;
      osc.connect(gain);
      gain.connect(ctx.destination);
      gain.gain.setValueAtTime(0, ctx.currentTime);
      gain.gain.linearRampToValueAtTime(0.15, ctx.currentTime + 0.02);
      gain.gain.linearRampToValueAtTime(0, ctx.currentTime + 0.18);
      osc.start();
      osc.stop(ctx.currentTime + 0.2);
      setTimeout(() => ctx.close(), 300);
    } catch (e) {
      console.warn("[Zaxo] message tone failed", e);
    }
  }

  // Show a system notification
  notify(
    id: string,
    category: NotificationCategory,
    title: string,
    body: string,
    options: {
      chatId?: string;
      callId?: string;
      statusUserId?: string;
      tag?: string;
      requireInteraction?: boolean;
      actions?: NotifAction[];
    } = {},
  ) {
    const settings = this.config?.settings;
    if (!settings) return;

    // Quiet hours: only urgent calls bypass
    if (this.isInQuietHours(settings)) {
      if (category !== "call_incoming" && category !== "call_group") {
        return;
      }
    }
    if (!this.categoryEnabled(category, settings)) return;

    const finalBody = this.bodyFor(category, body, settings);
    const finalTitle = (settings.hideNotificationContent && category === "message")
      ? "Zaxo"
      : title;

    // Always queue in-app
    this.inAppQueue.unshift({
      id, category, title: finalTitle, body: finalBody,
      timestamp: Date.now(),
      chatId: options.chatId,
    });
    if (this.inAppQueue.length > 50) this.inAppQueue.length = 50;
    this.notifyInAppListeners();

    // Play sound (only if NOT focused or category is call)
    const isCall = category === "call_incoming" || category === "call_group";
    if (isCall) {
      this.playRingtone();
    } else if (document.visibilityState !== "visible" || category !== "message") {
      if (category === "message" || category === "group_message") {
        this.playMessageTone();
      }
    }

    // System notification
    if (this.permission !== "granted") return;
    if (typeof window === "undefined" || !("Notification" in window)) return;

    try {
      const notifOpts: NotificationOptions & { actions?: NotifAction[]; data?: unknown } = {
        body: finalBody,
        tag: options.tag || id,
        requireInteraction: options.requireInteraction ?? isCall,
        silent: isCall, // we play our own ringtone
        icon: "/zaxo-app-icon.png",
        badge: "/icon-192.png",
        data: {
          chatId: options.chatId,
          callId: options.callId,
          statusUserId: options.statusUserId,
          category,
        },
        actions: options.actions,
      };
      const notif = new Notification(finalTitle, notifOpts);
      this.activeNotifications.set(id, notif);
      notif.onclick = () => {
        window.focus();
        const data = notif.data as { chatId?: string; callId?: string; statusUserId?: string; category: NotificationCategory };
        if (data.category === "call_incoming" || data.category === "call_group") {
          if (data.callId && this.config?.onCallAnswer) this.config.onCallAnswer(data.callId);
        } else if (data.statusUserId && this.config?.onStatusClick) {
          this.config.onStatusClick(data.statusUserId);
        } else if (data.chatId && this.config?.onChatClick) {
          this.config.onChatClick(data.chatId);
        }
        notif.close();
      };
      notif.onclose = () => {
        this.activeNotifications.delete(id);
      };
      if (!options.requireInteraction && !isCall) {
        setTimeout(() => { try { notif.close(); } catch {} }, 5000);
      }
    } catch (e) {
      console.warn("[Zaxo] notification failed", e);
    }
  }

  cancel(id: string) {
    const n = this.activeNotifications.get(id);
    if (n) { try { n.close(); } catch {} this.activeNotifications.delete(id); }
  }

  // In-app queue for the in-app notification center
  subscribeInApp(fn: (queue: NotificationService["inAppQueue"]) => void): () => void {
    this.inAppListeners.add(fn);
    fn(this.inAppQueue);
    return () => { this.inAppListeners.delete(fn); };
  }
  private notifyInAppListeners() {
    const snapshot = [...this.inAppQueue];
    this.inAppListeners.forEach((fn) => fn(snapshot));
  }
  clearInApp() {
    this.inAppQueue = [];
    this.notifyInAppListeners();
  }
  dismissInApp(id: string) {
    this.inAppQueue = this.inAppQueue.filter((n) => n.id !== id);
    this.notifyInAppListeners();
  }
}

export const notifications = new NotificationService();
