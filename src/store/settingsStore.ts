// ==================== THEME & SETTINGS STORE ====================
"use client";

import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import type { Theme, Settings } from "@/types";
import { DEFAULT_SETTINGS } from "@/lib/zaxo/mockData";

interface SettingsState {
  theme: Theme;
  settings: Settings;
  setTheme: (theme: Theme) => void;
  toggleTheme: () => void;
  updateSettings: (updates: Partial<Settings>) => void;
  resetSettings: () => void;
}

export const useSettingsStore = create<SettingsState>()(
  persist(
    (set, get) => ({
      theme: "light",
      settings: { ...DEFAULT_SETTINGS },
      setTheme: (theme) => {
        set({ theme });
        if (typeof document !== "undefined") {
          if (theme === "dark") {
            document.documentElement.classList.add("dark");
          } else {
            document.documentElement.classList.remove("dark");
          }
        }
      },
      toggleTheme: () => {
        const next = get().theme === "light" ? "dark" : "light";
        get().setTheme(next);
      },
      updateSettings: (updates) => {
        set({ settings: { ...get().settings, ...updates } });
      },
      resetSettings: () => {
        set({ settings: { ...DEFAULT_SETTINGS } });
      },
    }),
    {
      name: "zaxo-settings",
      storage: createJSONStorage(() => localStorage),
      onRehydrateStorage: () => (state) => {
        // Apply theme class on rehydration
        if (state && typeof document !== "undefined") {
          if (state.theme === "dark") {
            document.documentElement.classList.add("dark");
          } else {
            document.documentElement.classList.remove("dark");
          }
        }
      },
    },
  ),
);
