// ==================== UI NAVIGATION STORE ====================
"use client";

import { create } from "zustand";

export type Screen =
  | "splash"
  | "auth"
  | "email_auth"
  | "congratulations"
  | "main";

export type MainTab = "chats" | "calls" | "status" | "you";

export type SubPanel =
  | { type: "none" }
  | { type: "chat_room"; chatId: string }
  | { type: "chat_info"; chatId: string }
  | { type: "new_chat" }
  | { type: "new_group" }
  | { type: "group_info"; chatId: string }
  | { type: "status_viewer"; userId: string }
  | { type: "status_create" }
  | { type: "call_screen"; otherUserId: string; callType: "voice" | "video" }
  | { type: "settings_main" }
  | { type: "settings_account" }
  | { type: "settings_privacy" }
  | { type: "settings_notifications" }
  | { type: "settings_chats" }
  | { type: "settings_storage" }
  | { type: "settings_appearance" }
  | { type: "settings_accessibility" }
  | { type: "settings_help" }
  | { type: "settings_linked_devices" }
  | { type: "settings_blocked" }
  | { type: "settings_two_step" }
  | { type: "new_call" }
  | { type: "share_zaxo" }
  | { type: "qr_scanner" };

interface UIState {
  screen: Screen;
  activeTab: MainTab;
  subPanel: SubPanel;
  searchQuery: string;
  showSearch: boolean;
  showProfileEdit: boolean;
  toast: { message: string; type: "default" | "success" | "error" } | null;

  setScreen: (screen: Screen) => void;
  setActiveTab: (tab: MainTab) => void;
  setSubPanel: (panel: SubPanel) => void;
  setSearchQuery: (q: string) => void;
  setShowSearch: (show: boolean) => void;
  setShowProfileEdit: (show: boolean) => void;
  showToast: (message: string, type?: "default" | "success" | "error") => void;
  clearToast: () => void;
}

export const useUIStore = create<UIState>((set) => ({
  screen: "splash",
  activeTab: "chats",
  subPanel: { type: "none" },
  searchQuery: "",
  showSearch: false,
  showProfileEdit: false,
  toast: null,

  setScreen: (screen) => set({ screen }),
  setActiveTab: (tab) => set({ activeTab: tab, subPanel: { type: "none" } }),
  setSubPanel: (panel) => set({ subPanel: panel }),
  setSearchQuery: (q) => set({ searchQuery: q }),
  setShowSearch: (show) => set({ showSearch: show, searchQuery: show ? "" : "" }),
  setShowProfileEdit: (show) => set({ showProfileEdit: show }),
  showToast: (message, type = "default") =>
    set({ toast: { message, type } }),
  clearToast: () => set({ toast: null }),
}));
