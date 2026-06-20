// ==================== AUTH SCREEN ====================
"use client";

import { useState } from "react";
import { motion } from "framer-motion";
import { Mail, Chrome, ChevronLeft, Shield, Zap, Globe } from "lucide-react";
import { ZaxoLogo } from "./ZaxoLogo";
import { NeuButton, NeuInput } from "@/components/neumorphic";
import { useAuthStore } from "@/store/authStore";
import { useUIStore } from "@/store/uiStore";

export function AuthScreen() {
  const { setScreen } = useUIStore();
  return (
    <div
      className="min-h-screen flex flex-col px-6 py-10"
      style={{ background: "var(--neu-bg)" }}
    >
      <motion.div
        initial={{ scale: 0.9, opacity: 0 }}
        animate={{ scale: 1, opacity: 1 }}
        transition={{ duration: 0.5, ease: [0.16, 1, 0.3, 1] }}
        className="flex flex-col items-center mt-8"
      >
        <ZaxoLogo size={80} animated />
        <h1 className="text-3xl font-bold neu-text mt-6">Welcome to Zaxo</h1>
        <p className="text-sm neu-text-muted mt-2 text-center max-w-xs">
          Your permanent 9-digit Zaxo number connects you with anyone, anywhere.
        </p>
      </motion.div>

      <motion.div
        initial={{ opacity: 0, y: 20 }}
        animate={{ opacity: 1, y: 0 }}
        transition={{ delay: 0.3, duration: 0.5 }}
        className="flex-1 flex flex-col justify-end gap-4 pb-8"
      >
        <FeatureRow icon={<Shield size={18} />} text="End-to-end encrypted by default" />
        <FeatureRow icon={<Zap size={18} />} text="Crystal-clear voice & video calls" />
        <FeatureRow icon={<Globe size={18} />} text="Find anyone by their Zaxo number" />

        <div className="mt-6 space-y-4">
          <NeuButton
            variant="accent"
            size="lg"
            fullWidth
            rounded="xl"
            icon={<Chrome size={20} />}
            onClick={() => simulateGoogleSignIn()}
          >
            Continue with Google
          </NeuButton>

          <div className="flex items-center gap-3 my-2">
            <div className="flex-1 h-px neu-text-muted opacity-30" />
            <span className="text-xs neu-text-muted">or</span>
            <div className="flex-1 h-px neu-text-muted opacity-30" />
          </div>

          <NeuButton
            variant="raised"
            size="lg"
            fullWidth
            rounded="xl"
            icon={<Mail size={20} />}
            onClick={() => setScreen("email_auth")}
          >
            Login with Email
          </NeuButton>
        </div>

        <p className="text-[10px] neu-text-muted text-center mt-2 leading-relaxed">
          By continuing, you agree to Zaxo&apos;s Terms of Service and acknowledge our Privacy Policy.
        </p>
      </motion.div>
    </div>
  );
}

function FeatureRow({ icon, text }: { icon: React.ReactNode; text: string }) {
  return (
    <div className="flex items-center gap-3 neu-raised-sm rounded-2xl px-4 py-3">
      <div className="neu-text-accent">{icon}</div>
      <div className="text-sm neu-text">{text}</div>
    </div>
  );
}

// Mock Google Sign-In (would integrate Firebase Auth in production)
function simulateGoogleSignIn() {
  const names = ["Alex Rivera", "Jordan Kim", "Sam Patel", "Riley Cohen"];
  const name = names[Math.floor(Math.random() * names.length)];
  const email = `${name.toLowerCase().replace(/\s/g, ".")}@gmail.com`;
  const { signInWithGoogle } = useAuthStore.getState();
  const user = signInWithGoogle(name, email);
  const { setScreen } = useUIStore.getState();
  if (user.isFirstLogin) {
    setScreen("congratulations");
  } else {
    setScreen("main");
  }
}

// ==================== EMAIL AUTH SCREEN ====================
export function EmailAuthScreen() {
  const { setScreen } = useUIStore();
  const { signInWithEmail } = useAuthStore();
  const [mode, setMode] = useState<"login" | "signup">("signup");
  const [name, setName] = useState("");
  const [email, setEmail] = useState("");
  const [password, setPassword] = useState("");
  const [confirmPassword, setConfirmPassword] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);

  function validate(): boolean {
    setError("");
    if (mode === "signup") {
      if (!name.trim()) {
        setError("Please enter your name");
        return false;
      }
    }
    if (!/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(email)) {
      setError("Please enter a valid email address");
      return false;
    }
    if (password.length < 8) {
      setError("Password must be at least 8 characters");
      return false;
    }
    if (!/[A-Z]/.test(password)) {
      setError("Password must contain at least one uppercase letter");
      return false;
    }
    if (!/[0-9]/.test(password)) {
      setError("Password must contain at least one number");
      return false;
    }
    if (!/[^A-Za-z0-9]/.test(password)) {
      setError("Password must contain at least one special character");
      return false;
    }
    if (mode === "signup" && password !== confirmPassword) {
      setError("Passwords do not match");
      return false;
    }
    return true;
  }

  function handleSubmit() {
    if (!validate()) return;
    setLoading(true);
    setTimeout(() => {
      const displayName = mode === "signup" ? name : email.split("@")[0];
      const user = signInWithEmail(displayName, email);
      setLoading(false);
      if (user.isFirstLogin) {
        setScreen("congratulations");
      } else {
        setScreen("main");
      }
    }, 900);
  }

  return (
    <div
      className="min-h-screen flex flex-col px-6 py-8"
      style={{ background: "var(--neu-bg)" }}
    >
      <button
        onClick={() => setScreen("auth")}
        className="flex items-center gap-1 neu-text-muted hover:neu-text transition-colors mb-6 w-fit"
      >
        <ChevronLeft size={20} /> Back
      </button>

      <motion.div
        initial={{ opacity: 0, x: 30 }}
        animate={{ opacity: 1, x: 0 }}
        transition={{ duration: 0.35 }}
        className="flex-1"
      >
        <h1 className="text-2xl font-bold neu-text">
          {mode === "signup" ? "Create account" : "Welcome back"}
        </h1>
        <p className="text-sm neu-text-muted mt-1">
          {mode === "signup"
            ? "Get your permanent Zaxo number in seconds."
            : "Sign in to continue to Zaxo."}
        </p>

        <div className="flex gap-2 mt-6 p-1.5 neu-well rounded-2xl">
          <button
            onClick={() => setMode("signup")}
            className={`flex-1 py-2.5 rounded-xl text-sm font-medium transition-all ${
              mode === "signup" ? "neu-raised-sm neu-text" : "neu-text-muted"
            }`}
          >
            Sign Up
          </button>
          <button
            onClick={() => setMode("login")}
            className={`flex-1 py-2.5 rounded-xl text-sm font-medium transition-all ${
              mode === "login" ? "neu-raised-sm neu-text" : "neu-text-muted"
            }`}
          >
            Login
          </button>
        </div>

        <div className="space-y-3 mt-6">
          {mode === "signup" && (
            <NeuInput
              placeholder="Full name"
              value={name}
              onChange={(e) => setName(e.target.value)}
            />
          )}
          <NeuInput
            type="email"
            placeholder="Email address"
            value={email}
            onChange={(e) => setEmail(e.target.value)}
          />
          <NeuInput
            type="password"
            placeholder="Password"
            value={password}
            onChange={(e) => setPassword(e.target.value)}
          />
          {mode === "signup" && (
            <NeuInput
              type="password"
              placeholder="Confirm password"
              value={confirmPassword}
              onChange={(e) => setConfirmPassword(e.target.value)}
            />
          )}

          {mode === "login" && (
            <div className="text-right">
              <button className="text-xs neu-text-accent hover:underline">
                Forgot password?
              </button>
            </div>
          )}

          {error && (
            <div className="neu-inset rounded-xl px-4 py-2.5 text-xs neu-text-danger">
              {error}
            </div>
          )}

          <NeuButton
            variant="accent"
            size="lg"
            fullWidth
            rounded="xl"
            loading={loading}
            onClick={handleSubmit}
          >
            {mode === "signup" ? "Create account" : "Sign in"}
          </NeuButton>

          {mode === "signup" && (
            <p className="text-[10px] neu-text-muted text-center leading-relaxed mt-2">
              Password: 8+ chars, 1 uppercase, 1 number, 1 special character
            </p>
          )}
        </div>
      </motion.div>
    </div>
  );
}
