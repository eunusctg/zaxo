// ==================== CONGRATULATION SCREEN ====================
"use client";

import { useEffect, useState, useMemo } from "react";
import { motion, AnimatePresence } from "framer-motion";
import { Copy, Check, Share2, Sparkles, ArrowRight } from "lucide-react";
import { ZaxoLogo } from "./ZaxoLogo";
import { NeuButton } from "@/components/neumorphic";
import { useAuthStore } from "@/store/authStore";
import { useUIStore } from "@/store/uiStore";

const CONFETTI_COLORS = [
  "#6C5CE7", "#00B894", "#FF6B6B", "#FECA57", "#74B9FF",
  "#A29BFE", "#55EFC4", "#FF7675", "#FDCB6E", "#E17055",
];

export function CongratulationScreen() {
  const { user, markFirstLoginComplete } = useAuthStore();
  const { setScreen } = useUIStore();
  const [displayed, setDisplayed] = useState("");
  const [copied, setCopied] = useState(false);
  const [showContinue, setShowContinue] = useState(false);

  const confettiPieces = useMemo(
    () =>
      Array.from({ length: 80 }).map((_, i) => ({
        id: i,
        left: Math.random() * 100,
        delay: Math.random() * 1.2,
        duration: 2.5 + Math.random() * 1.5,
        color: CONFETTI_COLORS[i % CONFETTI_COLORS.length],
        rotation: Math.random() * 360,
        size: 6 + Math.random() * 8,
      })),
    [],
  );

  // Typewriter reveal of Zaxo number
  useEffect(() => {
    if (!user?.zaxoNumber) return;
    const target = user.zaxoNumber;
    let idx = 0;
    const interval = setInterval(() => {
      idx++;
      setDisplayed(target.slice(0, idx));
      if (idx >= target.length) {
        clearInterval(interval);
        setTimeout(() => setShowContinue(true), 400);
      }
    }, 90);
    return () => clearInterval(interval);
  }, [user?.zaxoNumber]);

  function handleContinue() {
    markFirstLoginComplete();
    setScreen("main");
  }

  function handleCopy() {
    navigator.clipboard?.writeText(user?.zaxoNumber || "");
    setCopied(true);
    setTimeout(() => setCopied(false), 1800);
  }

  function handleShare() {
    if (navigator.share && user) {
      navigator.share({
        title: "My Zaxo Number",
        text: `Connect with me on Zaxo! My number is ${user.zaxoNumber}`,
      }).catch(() => {});
    } else {
      handleCopy();
    }
  }

  return (
    <div
      className="min-h-screen flex flex-col items-center justify-center px-6 py-10 relative overflow-hidden"
      style={{ background: "var(--neu-bg)" }}
    >
      {/* Confetti */}
      <div className="pointer-events-none fixed inset-0 z-0">
        {confettiPieces.map((p) => (
          <div
            key={p.id}
            className="confetti-piece"
            style={{
              left: `${p.left}%`,
              backgroundColor: p.color,
              animationDelay: `${p.delay}s`,
              animationDuration: `${p.duration}s`,
              transform: `rotate(${p.rotation}deg)`,
              width: p.size,
              height: p.size * 1.4,
              borderRadius: 2,
            }}
          />
        ))}
      </div>

      <motion.div
        initial={{ scale: 0.6, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
        className="relative z-10 flex flex-col items-center"
      >
        <div className="scale-pulse">
          <ZaxoLogo size={88} />
        </div>

        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          transition={{ delay: 0.4 }}
          className="flex items-center gap-1.5 mt-6 text-xs neu-text-accent"
        >
          <Sparkles size={14} />
          <span className="uppercase tracking-wider font-semibold">Account Created</span>
          <Sparkles size={14} />
        </motion.div>

        <h1 className="text-3xl font-bold neu-text mt-2 text-center">
          Congratulations!
        </h1>
        <p className="text-sm neu-text-muted mt-2 text-center max-w-xs">
          Welcome to Zaxo. Your permanent identity has been generated.
        </p>

        {/* Zaxo Number Card */}
        <motion.div
          initial={{ opacity: 0, scale: 0.9 }}
          animate={{ opacity: 1, scale: 1 }}
          transition={{ delay: 0.7, duration: 0.4 }}
          className="neu-raised-lg rounded-3xl px-8 py-7 mt-8 w-full max-w-sm"
        >
          <div className="text-xs uppercase tracking-wider neu-text-muted text-center">
            Your Zaxo Number
          </div>
          <div className="text-4xl font-bold neu-text-accent text-center mt-3 tracking-wider font-mono">
            {displayed}
            {displayed.length < (user?.zaxoNumber?.length || 0) && (
              <span className="typewriter-cursor" />
            )}
          </div>
          <div className="text-xs neu-text-muted text-center mt-3 leading-relaxed">
            This is your permanent identity on Zaxo.<br />
            Share it so others can find and connect with you.
          </div>

          <div className="flex gap-2 mt-5">
            <NeuButton
              variant="raised"
              size="md"
              rounded="xl"
              fullWidth
              icon={copied ? <Check size={16} /> : <Copy size={16} />}
              onClick={handleCopy}
            >
              {copied ? "Copied!" : "Copy"}
            </NeuButton>
            <NeuButton
              variant="raised"
              size="md"
              rounded="xl"
              fullWidth
              icon={<Share2 size={16} />}
              onClick={handleShare}
            >
              Share
            </NeuButton>
          </div>
        </motion.div>

        <AnimatePresence>
          {showContinue && (
            <motion.div
              initial={{ opacity: 0, y: 16 }}
              animate={{ opacity: 1, y: 0 }}
              className="mt-8 w-full max-w-sm"
            >
              <NeuButton
                variant="accent"
                size="lg"
                fullWidth
                rounded="xl"
                iconRight={<ArrowRight size={20} />}
                onClick={handleContinue}
              >
                Continue to Zaxo
              </NeuButton>
              <p className="text-[10px] neu-text-muted text-center mt-3">
                This screen won&apos;t appear again.
              </p>
            </motion.div>
          )}
        </AnimatePresence>
      </motion.div>
    </div>
  );
}
