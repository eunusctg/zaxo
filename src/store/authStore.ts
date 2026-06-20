// ==================== AUTH STORE ====================
"use client";

import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import type { User, AuthMethod } from "@/types";
import { generateUniqueZaxoNumber } from "@/lib/zaxo/number";
import { AVATAR_GRADIENTS } from "@/lib/zaxo/mockData";

const CURRENT_USER_ID = "me";

interface AuthState {
  user: User | null;
  isAuthenticated: boolean;
  authMethod: AuthMethod | null;
  // Actions
  signInWithGoogle: (displayName: string, email: string) => User;
  signInWithEmail: (displayName: string, email: string) => User;
  signOut: () => void;
  updateProfile: (updates: Partial<User>) => void;
  markFirstLoginComplete: () => void;
  updateUserStatus: (online: boolean) => void;
}

export const useAuthStore = create<AuthState>()(
  persist(
    (set, get) => ({
      user: null,
      isAuthenticated: false,
      authMethod: null,

      signInWithGoogle: (displayName, email) => {
        const zaxoNumber = generateUniqueZaxoNumber(`google-${email}`);
        const user: User = {
          id: CURRENT_USER_ID,
          zaxoNumber,
          displayName,
          email,
          avatarColor: AVATAR_GRADIENTS[Math.floor(Math.random() * AVATAR_GRADIENTS.length)],
          avatarInitial: displayName.charAt(0).toUpperCase(),
          about: "Hey there! I'm using Zaxo.",
          isFirstLogin: true,
          createdAt: Date.now(),
          lastSeen: Date.now(),
          online: true,
        };
        set({ user, isAuthenticated: true, authMethod: "google" });
        return user;
      },

      signInWithEmail: (displayName, email) => {
        const zaxoNumber = generateUniqueZaxoNumber(`email-${email}`);
        const user: User = {
          id: CURRENT_USER_ID,
          zaxoNumber,
          displayName,
          email,
          avatarColor: AVATAR_GRADIENTS[Math.floor(Math.random() * AVATAR_GRADIENTS.length)],
          avatarInitial: displayName.charAt(0).toUpperCase(),
          about: "Hey there! I'm using Zaxo.",
          isFirstLogin: true,
          createdAt: Date.now(),
          lastSeen: Date.now(),
          online: true,
        };
        set({ user, isAuthenticated: true, authMethod: "email" });
        return user;
      },

      signOut: () => {
        set({ user: null, isAuthenticated: false, authMethod: null });
      },

      updateProfile: (updates) => {
        const current = get().user;
        if (!current) return;
        const next = { ...current, ...updates };
        if (updates.displayName) {
          next.avatarInitial = updates.displayName.charAt(0).toUpperCase();
        }
        set({ user: next });
      },

      markFirstLoginComplete: () => {
        const current = get().user;
        if (!current) return;
        set({ user: { ...current, isFirstLogin: false } });
      },

      updateUserStatus: (online) => {
        const current = get().user;
        if (!current) return;
        set({ user: { ...current, online, lastSeen: Date.now() } });
      },
    }),
    {
      name: "zaxo-auth",
      storage: createJSONStorage(() => localStorage),
    },
  ),
);
