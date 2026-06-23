// ==================== SECURITY / APP-LOCK STORE ====================
"use client";

import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";

interface SecurityState {
  // App lock
  appLockEnabled: boolean;
  appLockMethod: "biometric" | "passcode" | "both";
  passcodeHash: string | null; // SHA-256 hash of 6-digit pin
  biometricCredentialId: string | null;
  lockTimeoutSeconds: number; // 0 = immediate, 60 = 1min, 300 = 5min, 1800 = 30min
  lastUnlockedAt: number;
  isLocked: boolean;

  // Recovery
  recoveryEmail: string | null;

  // Actions
  enableAppLock: (method: "biometric" | "passcode" | "both") => void;
  disableAppLock: () => void;
  setPasscode: (pin: string) => Promise<void>;
  verifyPasscode: (pin: string) => Promise<boolean>;
  enrollBiometric: () => Promise<boolean>;
  verifyBiometric: () => Promise<boolean>;
  lockNow: () => void;
  unlock: () => void;
  setLockTimeout: (seconds: number) => void;
  setRecoveryEmail: (email: string) => void;
}

// SHA-256 hash helper (uses Web Crypto API)
async function hashPin(pin: string): Promise<string> {
  const encoder = new TextEncoder();
  const data = encoder.encode(`zaxo-salt::${pin}`);
  const hashBuffer = await crypto.subtle.digest("SHA-256", data);
  const hashArray = Array.from(new Uint8Array(hashBuffer));
  return hashArray.map((b) => b.toString(16).padStart(2, "0")).join("");
}

// WebAuthn helpers
async function webAuthnCreate(): Promise<string | null> {
  if (typeof window === "undefined" || !window.PublicKeyCredential) return null;
  try {
    const challenge = new Uint8Array(32);
    crypto.getRandomValues(challenge);
    const userId = new Uint8Array(16);
    crypto.getRandomValues(userId);

    const credential = (await navigator.credentials.create({
      publicKey: {
        challenge,
        rp: { name: "Zaxo" },
        user: {
          id: userId,
          name: "Zaxo User",
          displayName: "Zaxo User",
        },
        pubKeyCredParams: [
          { type: "public-key", alg: -7 }, // ES256
          { type: "public-key", alg: -257 }, // RS256
        ],
        authenticatorSelection: {
          authenticatorAttachment: "platform",
          userVerification: "required",
          residentKey: "preferred",
        },
        timeout: 60000,
        attestation: "none",
      },
    })) as PublicKeyCredential | null;

    if (!credential) return null;
    // Encode credential ID as base64url
    const idBuf = new Uint8Array(credential.rawId);
    return btoa(String.fromCharCode(...Array.from(idBuf)));
  } catch (e) {
    console.warn("[Zaxo] WebAuthn create failed:", e);
    return null;
  }
}

async function webAuthnGet(credentialId: string): Promise<boolean> {
  if (typeof window === "undefined" || !window.PublicKeyCredential) return false;
  try {
    const challenge = new Uint8Array(32);
    crypto.getRandomValues(challenge);

    const idBuf = new Uint8Array(
      atob(credentialId)
        .split("")
        .map((c) => c.charCodeAt(0)),
    );

    const assertion = await navigator.credentials.get({
      publicKey: {
        challenge,
        timeout: 60000,
        userVerification: "required",
        allowCredentials: [
          {
            id: idBuf,
            type: "public-key",
            transports: ["internal"],
          },
        ],
      },
    });
    return !!assertion;
  } catch (e) {
    console.warn("[Zaxo] WebAuthn get failed:", e);
    return false;
  }
}

export const isBiometricSupported = (): boolean => {
  if (typeof window === "undefined") return false;
  return (
    !!window.PublicKeyCredential &&
    typeof window.PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable === "function"
  );
};

export async function isBiometricAvailable(): Promise<boolean> {
  if (!isBiometricSupported()) return false;
  try {
    return await window.PublicKeyCredential.isUserVerifyingPlatformAuthenticatorAvailable();
  } catch {
    return false;
  }
}

export const useSecurityStore = create<SecurityState>()(
  persist(
    (set, get) => ({
      appLockEnabled: false,
      appLockMethod: "passcode",
      passcodeHash: null,
      biometricCredentialId: null,
      lockTimeoutSeconds: 0,
      lastUnlockedAt: Date.now(),
      isLocked: false,
      recoveryEmail: null,

      enableAppLock: (method) => set({ appLockEnabled: true, appLockMethod: method, isLocked: false, lastUnlockedAt: Date.now() }),
      disableAppLock: () => set({
        appLockEnabled: false,
        passcodeHash: null,
        biometricCredentialId: null,
        isLocked: false,
      }),
      setPasscode: async (pin) => {
        const hash = await hashPin(pin);
        set({ passcodeHash: hash });
      },
      verifyPasscode: async (pin) => {
        const hash = await hashPin(pin);
        return hash === get().passcodeHash;
      },
      enrollBiometric: async () => {
        const id = await webAuthnCreate();
        if (id) {
          set({ biometricCredentialId: id });
          return true;
        }
        return false;
      },
      verifyBiometric: async () => {
        const id = get().biometricCredentialId;
        if (!id) return false;
        return webAuthnGet(id);
      },
      lockNow: () => set({ isLocked: true }),
      unlock: () => set({ isLocked: false, lastUnlockedAt: Date.now() }),
      setLockTimeout: (seconds) => set({ lockTimeoutSeconds: seconds }),
      setRecoveryEmail: (email) => set({ recoveryEmail: email }),
    }),
    {
      name: "zaxo-security",
      storage: createJSONStorage(() => localStorage),
    },
  ),
);
