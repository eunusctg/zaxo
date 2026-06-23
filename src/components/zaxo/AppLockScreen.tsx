// ==================== APP LOCK SCREEN ====================
"use client";

import { useEffect, useState } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Fingerprint, Lock, ShieldCheck, X, ChevronRight } from "lucide-react";
import { ZaxoLogo } from "./ZaxoLogo";
import { NeuButton } from "@/components/neumorphic/NeuButton";
import { useSecurityStore, isBiometricAvailable } from "@/store/securityStore";
import { useUIStore } from "@/store/uiStore";

export function AppLockScreen() {
  const { verifyPasscode, verifyBiometric, unlock, appLockMethod, biometricCredentialId } = useSecurityStore();
  const { setScreen } = useUIStore();
  const [pin, setPin] = useState("");
  const [error, setError] = useState("");
  const [attempts, setAttempts] = useState(0);
  const [bioAvailable, setBioAvailable] = useState(false);
  const [verifying, setVerifying] = useState(false);

  useEffect(() => {
    isBiometricAvailable().then(setBioAvailable);
  }, []);

  // Auto-prompt biometric on mount if available
  useEffect(() => {
    if (appLockMethod === "biometric" || appLockMethod === "both") {
      if (biometricCredentialId && bioAvailable) {
        tryBiometric();
      }
    }
    // eslint-disable-next-line react-hooks/exhaustive-deps
  }, []);

  async function tryBiometric() {
    setVerifying(true);
    setError("");
    const ok = await verifyBiometric();
    setVerifying(false);
    if (ok) {
      unlock();
      setScreen("main");
    } else {
      setError("Biometric verification failed. Try again or use passcode.");
    }
  }

  async function handleSubmit() {
    if (pin.length !== 6) return;
    setVerifying(true);
    setError("");
    const ok = await verifyPasscode(pin);
    setVerifying(false);
    if (ok) {
      unlock();
      setScreen("main");
    } else {
      setAttempts((a) => a + 1);
      setError(`Incorrect passcode. ${attempts + 1 >= 3 ? "Try biometric or reset." : `${3 - attempts - 1} attempt${2 - attempts === 1 ? "" : "s"} left.`}`);
      setPin("");
      // Auto-fallback to biometric after 3 failed attempts
      if (attempts + 1 >= 3 && biometricCredentialId && bioAvailable) {
        setTimeout(() => tryBiometric(), 500);
      }
    }
  }

  function handleDigit(d: string) {
    if (pin.length >= 6) return;
    const next = pin + d;
    setPin(next);
    setError("");
    if (next.length === 6) {
      setTimeout(() => handleSubmit(), 100); // submit when complete
    }
  }

  function handleBackspace() {
    setPin(pin.slice(0, -1));
    setError("");
  }

  const showBiometricButton = (appLockMethod === "biometric" || appLockMethod === "both") && biometricCredentialId && bioAvailable;

  return (
    <div
      className="min-h-screen flex flex-col items-center justify-center px-6 py-8"
      style={{ background: "var(--neu-bg)" }}
    >
      <motion.div
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.5 }}
        className="flex flex-col items-center"
      >
        <ZaxoLogo size={64} />
        <h1 className="text-xl font-bold neu-text mt-5">Zaxo is locked</h1>
        <p className="text-sm neu-text-muted mt-1 text-center max-w-xs">
          {appLockMethod === "biometric"
            ? "Use biometric to unlock."
            : appLockMethod === "both"
              ? "Use biometric or your 6-digit passcode."
              : "Enter your 6-digit passcode to continue."}
        </p>
      </motion.div>

      {/* PIN dots */}
      {appLockMethod !== "biometric" && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.2 }}
          className="mt-8 flex gap-3"
        >
          {Array.from({ length: 6 }).map((_, i) => (
            <motion.div
              key={i}
              animate={error && i === pin.length ? { x: [0, -4, 4, -4, 4, 0] } : { x: 0 }}
              transition={{ duration: 0.3 }}
              className={`w-3.5 h-3.5 rounded-full transition-all ${
                i < pin.length
                  ? "neu-accent"
                  : error
                    ? "neu-text-danger"
                    : "neu-raised-sm"
              }`}
              style={i < pin.length ? { background: "var(--neu-accent)" } : {}}
            />
          ))}
        </motion.div>
      )}

      {/* Error */}
      <AnimatePresence>
        {error && (
          <motion.div
            initial={{ opacity: 0, height: 0 }}
            animate={{ opacity: 1, height: "auto" }}
            exit={{ opacity: 0, height: 0 }}
            className="mt-3 text-xs neu-text-danger text-center"
          >
            {error}
          </motion.div>
        )}
      </AnimatePresence>

      {/* Biometric button */}
      {showBiometricButton && (
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.3 }}
          className="mt-6"
        >
          <NeuButton
            variant="accent"
            size="lg"
            rounded="xl"
            icon={<Fingerprint size={20} />}
            loading={verifying}
            onClick={tryBiometric}
          >
            Use biometric
          </NeuButton>
        </motion.div>
      )}

      {/* Keypad */}
      {appLockMethod !== "biometric" && (
        <motion.div
          initial={{ opacity: 0, y: 20 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="mt-8 grid grid-cols-3 gap-3 sm:gap-4"
        >
          {["1", "2", "3", "4", "5", "6", "7", "8", "9", "", "0", "back"].map((k, i) => (
            <div key={i} className="w-16 h-16 sm:w-18 sm:h-18">
              {k === "" ? (
                <div />
              ) : k === "back" ? (
                <button
                  onClick={handleBackspace}
                  className="w-full h-full neu-pressable rounded-2xl flex items-center justify-center neu-text-muted active:scale-95 transition-transform"
                  aria-label="Backspace"
                >
                  <X size={22} />
                </button>
              ) : (
                <button
                  onClick={() => handleDigit(k)}
                  className="w-full h-full neu-pressable rounded-2xl flex items-center justify-center text-xl font-semibold neu-text active:scale-95 transition-transform"
                >
                  {k}
                </button>
              )}
            </div>
          ))}
        </motion.div>
      )}

      <div className="absolute bottom-8 flex items-center gap-1.5 text-xs neu-text-muted">
        <Lock size={12} />
        <span>Protected by Zaxo App Lock</span>
      </div>
    </div>
  );
}
