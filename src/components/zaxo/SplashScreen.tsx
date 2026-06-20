// ==================== SPLASH SCREEN ====================
"use client";

import { useEffect, useState } from "react";
import { motion } from "framer-motion";
import { ZaxoLogo } from "./ZaxoLogo";
import { useAuthStore } from "@/store/authStore";
import { useUIStore } from "@/store/uiStore";

export function SplashScreen() {
  const { user } = useAuthStore();
  const { setScreen } = useUIStore();
  const [progress, setProgress] = useState(0);

  useEffect(() => {
    const interval = setInterval(() => {
      setProgress((p) => {
        if (p >= 100) {
          clearInterval(interval);
          setTimeout(() => {
            if (user && user.isFirstLogin) {
              setScreen("congratulations");
            } else if (user) {
              setScreen("main");
            } else {
              setScreen("auth");
            }
          }, 200);
          return 100;
        }
        return p + 4;
      });
    }, 35);
    return () => clearInterval(interval);
  }, [user, setScreen]);

  return (
    <div
      className="min-h-screen flex flex-col items-center justify-center px-8"
      style={{ background: "var(--neu-bg)" }}
    >
      <motion.div
        initial={{ scale: 0.85, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.6, ease: [0.16, 1, 0.3, 1] }}
      >
        <ZaxoLogo size={108} animated showText />
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.5, duration: 0.5 }}
        className="mt-16 w-44"
      >
        <div
          className="neu-well rounded-full h-2 overflow-hidden"
        >
          <motion.div
            className="h-full rounded-full"
            style={{ background: "linear-gradient(90deg, var(--neu-accent), var(--neu-accent-hover))" }}
            animate={{ width: `${progress}%` }}
            transition={{ duration: 0.1 }}
          />
        </div>
        <div className="text-center mt-3 text-xs neu-text-muted">
          {progress < 100 ? "Securing your connection…" : "Ready"}
        </div>
      </motion.div>

      <motion.div
        initial={{ opacity: 0 }}
        animate={{ opacity: 1 }}
        transition={{ delay: 1.2, duration: 0.5 }}
        className="absolute bottom-8 text-xs neu-text-muted"
      >
        v1.0.0 · End-to-end encrypted
      </motion.div>
    </div>
  );
}
