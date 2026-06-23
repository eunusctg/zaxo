// ==================== PROFILE / YOU SCREEN ====================
"use client";

import { motion } from "framer-motion";
import {
  QrCode, Share2, ChevronRight, Settings, User, Lock, Bell,
  MessageSquare, Database, Palette, Accessibility, HelpCircle,
  LogOut, Users, Shield, Key, Smartphone, Star, Moon, Sun, Fingerprint,
} from "lucide-react";
import { NeuAvatar } from "@/components/neumorphic/NeuAvatar";
import { NeuButton } from "@/components/neumorphic/NeuButton";
import { NeuSettingRow } from "@/components/neumorphic/NeuToggle";
import { useAuthStore } from "@/store/authStore";
import { useUIStore } from "@/store/uiStore";
import { useSettingsStore } from "@/store/settingsStore";
import { useSecurityStore } from "@/store/securityStore";

export function YouScreen() {
  const { user, signOut } = useAuthStore();
  const { setSubPanel } = useUIStore();
  const { theme, toggleTheme } = useSettingsStore();
  const { appLockEnabled, appLockMethod } = useSecurityStore();

  if (!user) return null;

  return (
    <div className="flex flex-col h-full w-full" style={{ background: "var(--neu-bg)" }}>
      <header className="px-3 sm:px-4 pt-4 pb-2 flex items-center justify-between">
        <h1 className="text-xl sm:text-2xl font-bold neu-text">You</h1>
        <button
          onClick={() => toggleTheme()}
          className="neu-pressable rounded-full w-10 h-10 flex items-center justify-center neu-text"
          aria-label="Toggle theme"
        >
          {theme === "light" ? <Moon size={18} /> : <Sun size={18} />}
        </button>
      </header>

      <div className="flex-1 overflow-y-auto neu-scroll px-3 sm:px-4 pb-4">
        {/* Profile header */}
        <motion.div
          initial={{ opacity: 0, y: 10 }}
          animate={{ opacity: 1, y: 0 }}
          className="neu-raised rounded-3xl p-4 sm:p-5 mb-3 mt-2"
        >
          <div className="flex items-center gap-3 sm:gap-4">
            <NeuAvatar initial={user.avatarInitial} gradient={user.avatarColor} size={64} online />
            <div className="flex-1 min-w-0">
              <div className="font-bold text-base sm:text-lg neu-text truncate">{user.displayName}</div>
              <div className="text-xs sm:text-sm neu-text-muted truncate">{user.about}</div>
              <div className="text-xs neu-text-accent font-mono mt-1">{user.zaxoNumber}</div>
            </div>
            <button
              onClick={() => setSubPanel({ type: "settings_account" })}
              className="neu-pressable rounded-xl w-9 h-9 flex items-center justify-center neu-text-muted shrink-0"
              aria-label="Edit profile"
            >
              <User size={16} />
            </button>
          </div>

          <div className="flex gap-2 mt-4">
            <NeuButton
              variant="raised"
              size="sm"
              rounded="xl"
              fullWidth
              icon={<QrCode size={14} />}
              onClick={() => setSubPanel({ type: "share_zaxo" })}
            >
              QR Code
            </NeuButton>
            <NeuButton
              variant="raised"
              size="sm"
              rounded="xl"
              fullWidth
              icon={<Share2 size={14} />}
              onClick={() => setSubPanel({ type: "share_zaxo" })}
            >
              Share
            </NeuButton>
          </div>
        </motion.div>

        {/* Account section */}
        <Section title="Account">
          <NeuSettingRow
            icon={<Key size={18} />}
            label="Account"
            description="Zaxo number, email, security"
            showChevron
            onClick={() => setSubPanel({ type: "settings_account" })}
          />
          <NeuSettingRow
            icon={<Shield size={18} />}
            label="Privacy"
            description="Last seen, blocked contacts"
            showChevron
            onClick={() => setSubPanel({ type: "settings_privacy" })}
          />
          <NeuSettingRow
            icon={<Lock size={18} />}
            label="Two-step verification"
            description={user ? "Not enabled" : "Disabled"}
            showChevron
            onClick={() => setSubPanel({ type: "settings_two_step" })}
          />
          <NeuSettingRow
            icon={<Fingerprint size={18} />}
            label="App lock"
            description={appLockEnabled ? `Enabled · ${appLockMethod}` : "Biometric + passcode"}
            showChevron
            onClick={() => setSubPanel({ type: "settings_app_lock" })}
          />
          <NeuSettingRow
            icon={<Smartphone size={18} />}
            label="Linked devices"
            description="1 active session"
            showChevron
            onClick={() => setSubPanel({ type: "settings_linked_devices" })}
          />
        </Section>

        {/* Preferences */}
        <Section title="Preferences">
          <NeuSettingRow
            icon={<Bell size={18} />}
            label="Notifications"
            description="Tones, vibration, quiet hours"
            showChevron
            onClick={() => setSubPanel({ type: "settings_notifications" })}
          />
          <NeuSettingRow
            icon={<MessageSquare size={18} />}
            label="Chats"
            description="Wallpaper, font size, backup"
            showChevron
            onClick={() => setSubPanel({ type: "settings_chats" })}
          />
          <NeuSettingRow
            icon={<Palette size={18} />}
            label="Appearance"
            description="Neumorphism, theme, accent"
            showChevron
            onClick={() => setSubPanel({ type: "settings_appearance" })}
          />
          <NeuSettingRow
            icon={<Accessibility size={18} />}
            label="Accessibility"
            description="Font scaling, motion, contrast"
            showChevron
            onClick={() => setSubPanel({ type: "settings_accessibility" })}
          />
          <NeuSettingRow
            icon={<Database size={18} />}
            label="Data & Storage"
            description="Network usage, cache"
            showChevron
            onClick={() => setSubPanel({ type: "settings_storage" })}
          />
        </Section>

        {/* More */}
        <Section title="More">
          <NeuSettingRow
            icon={<Users size={18} />}
            label="Invite friends"
            description="Bring people to Zaxo"
            showChevron
            onClick={() => {}}
          />
          <NeuSettingRow
            icon={<Star size={18} />}
            label="Starred messages"
            description="View your saved messages"
            showChevron
            onClick={() => {}}
          />
          <NeuSettingRow
            icon={<HelpCircle size={18} />}
            label="Help & About"
            description="FAQ, contact support, version"
            showChevron
            onClick={() => setSubPanel({ type: "settings_help" })}
          />
        </Section>

        {/* Logout */}
        <div className="mt-3 mb-4">
          <NeuButton
            variant="danger"
            size="md"
            rounded="xl"
            fullWidth
            icon={<LogOut size={16} />}
            onClick={() => {
              if (confirm("Log out of Zaxo?")) {
                signOut();
                window.location.reload();
              }
            }}
          >
            Log out
          </NeuButton>
        </div>

        <div className="text-center text-[10px] neu-text-muted py-3">
          Zaxo v1.0.0 · Made with care
        </div>
      </div>
    </div>
  );
}

function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="mb-3">
      <div className="px-4 py-2 text-xs font-semibold neu-text-muted uppercase tracking-wider">{title}</div>
      <div className="neu-raised rounded-2xl overflow-hidden divide-y divide-[color:var(--neu-shadow-dark)]/10">
        {children}
      </div>
    </div>
  );
}
