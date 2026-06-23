// ==================== SETTINGS PANELS ====================
"use client";

import { useState, useEffect } from "react";
import { motion } from "framer-motion";
import { ChevronLeft, Check, Trash2, Plus, Bell, User as UserIcon, Shield, Fingerprint, Lock, Info, AlertCircle } from "lucide-react";
import { NeuButton } from "@/components/neumorphic/NeuButton";
import { NeuInput } from "@/components/neumorphic/NeuInput";
import { NeuToggle, NeuSettingRow } from "@/components/neumorphic/NeuToggle";
import { NeuAvatar } from "@/components/neumorphic/NeuAvatar";
import { useAuthStore } from "@/store/authStore";
import { useSettingsStore } from "@/store/settingsStore";
import { useAppStore } from "@/store/appStore";
import { useUIStore } from "@/store/uiStore";
import { useSecurityStore, isBiometricAvailable } from "@/store/securityStore";

export function SettingsPanel({ panelType }: { panelType: string }) {
  const { setSubPanel } = useUIStore();

  return (
    <motion.div
      initial={{ x: "100%" }}
      animate={{ x: 0 }}
      exit={{ x: "100%" }}
      transition={{ type: "spring", damping: 30, stiffness: 280 }}
      className="absolute inset-0 z-30 flex flex-col"
      style={{ background: "var(--neu-bg)" }}
    >
      <SettingsContent panelType={panelType} onClose={() => setSubPanel({ type: "none" })} />
    </motion.div>
  );
}

function SettingsHeader({ title, onClose }: { title: string; onClose: () => void }) {
  return (
    <header className="px-3 pt-4 pb-3 flex items-center gap-2">
      <button onClick={onClose} className="neu-text p-1" aria-label="Back">
        <ChevronLeft size={24} />
      </button>
      <h1 className="text-xl font-bold neu-text">{title}</h1>
    </header>
  );
}

// Helper: intro/explainer banner at the top of settings sections
function IntroBanner({ icon, text }: { icon?: React.ReactNode; text: string }) {
  return (
    <div className="neu-inset rounded-2xl px-3 py-2.5 mb-4 flex items-start gap-2.5">
      {icon ? <div className="shrink-0 mt-0.5 neu-text-accent">{icon}</div> : <Info size={14} className="shrink-0 mt-0.5 neu-text-accent" />}
      <div className="text-xs neu-text-muted leading-relaxed">{text}</div>
    </div>
  );
}

function SettingsContent({ panelType, onClose }: { panelType: string; onClose: () => void }) {
  switch (panelType) {
    case "settings_account": return <AccountSettings onClose={onClose} />;
    case "settings_privacy": return <PrivacySettings onClose={onClose} />;
    case "settings_notifications": return <NotificationsSettings onClose={onClose} />;
    case "settings_chats": return <ChatsSettings onClose={onClose} />;
    case "settings_storage": return <StorageSettings onClose={onClose} />;
    case "settings_appearance": return <AppearanceSettings onClose={onClose} />;
    case "settings_accessibility": return <AccessibilitySettings onClose={onClose} />;
    case "settings_help": return <HelpSettings onClose={onClose} />;
    case "settings_linked_devices": return <LinkedDevicesSettings onClose={onClose} />;
    case "settings_blocked": return <BlockedSettings onClose={onClose} />;
    case "settings_two_step": return <TwoStepSettings onClose={onClose} />;
    case "settings_app_lock": return <AppLockSettings onClose={onClose} />;
    default: return null;
  }
}

// ==================== ACCOUNT SETTINGS ====================
function AccountSettings({ onClose }: { onClose: () => void }) {
  const { user, updateProfile } = useAuthStore();
  const [editing, setEditing] = useState(false);
  const [name, setName] = useState(user?.displayName || "");
  const [about, setAbout] = useState(user?.about || "");

  function save() {
    updateProfile({ displayName: name, about });
    setEditing(false);
  }

  if (!user) return null;

  return (
    <>
      <SettingsHeader title="Account" onClose={onClose} />
      <div className="flex-1 overflow-y-auto neu-scroll px-4 pb-6">
        <IntroBanner text="Your Zaxo number is permanent and unique. Update your display name, about, and manage your account security here." />
        {/* Profile card */}
        <div className="neu-raised rounded-3xl p-5 mb-4">
          <div className="flex items-center gap-4">
            <NeuAvatar initial={user.avatarInitial} gradient={user.avatarColor} size={72} />
            <div className="flex-1">
              <div className="text-xs neu-text-muted">Display name</div>
              {editing ? (
                <NeuInput value={name} onChange={(e) => setName(e.target.value)} containerClassName="mt-1" />
              ) : (
                <div className="font-semibold neu-text">{user.displayName}</div>
              )}
            </div>
            <button onClick={() => editing ? save() : setEditing(true)} className="neu-accent rounded-xl px-3 py-2 text-xs text-white">
              {editing ? "Save" : "Edit"}
            </button>
          </div>
        </div>

        {/* Zaxo Number */}
        <Section title="Zaxo Number">
          <div className="neu-raised rounded-2xl p-4 mb-3">
            <div className="text-xs neu-text-muted uppercase tracking-wider">Your permanent Zaxo number</div>
            <div className="text-3xl font-bold neu-text-accent font-mono mt-2 tracking-wider">{user.zaxoNumber}</div>
            <div className="text-xs neu-text-muted mt-2">
              This is your permanent identity on Zaxo. It cannot be changed.
            </div>
          </div>
          <NeuSettingRow icon={<UserIcon size={18} />} label="Copy Zaxo number" onClick={() => navigator.clipboard?.writeText(user.zaxoNumber)} />
        </Section>

        {/* About */}
        <Section title="About">
          <div className="neu-raised rounded-2xl p-4 mb-3">
            <div className="text-xs neu-text-muted mb-2">About</div>
            {editing ? (
              <NeuInput value={about} onChange={(e) => setAbout(e.target.value)} />
            ) : (
              <div className="text-sm neu-text">{user.about}</div>
            )}
            <div className="text-xs neu-text-muted mt-3">Email: {user.email}</div>
          </div>
        </Section>

        <Section title="Account Actions">
          <NeuSettingRow icon={<Shield size={18} />} label="Request account info" description="Download your data" showChevron />
          <NeuSettingRow icon={<Trash2 size={18} />} label="Delete account" description="Permanently delete (30-day grace)" danger showChevron onClick={() => {
            if (confirm("Delete account? This starts a 30-day grace period.")) {
              useAuthStore.getState().signOut();
              window.location.reload();
            }
          }} />
        </Section>
      </div>
    </>
  );
}

// ==================== PRIVACY ====================
function PrivacySettings({ onClose }: { onClose: () => void }) {
  const { settings, updateSettings } = useSettingsStore();
  const { setSubPanel } = useUIStore();

  return (
    <>
      <SettingsHeader title="Privacy" onClose={onClose} />
      <div className="flex-1 overflow-y-auto neu-scroll px-4 pb-6">
        <IntroBanner text="Control who can see your personal info and how you appear to others. Changes apply to new chats and status updates." />
        <Section title="Who can see my info">
          <NeuSettingRow label="Last seen & online" description={cap(settings.lastSeenVisibility)} showChevron onClick={() => updateSettings({ lastSeenVisibility: nextVisibility(settings.lastSeenVisibility) })} />
          <NeuSettingRow label="Profile photo" description={cap(settings.profilePhotoVisibility)} showChevron onClick={() => updateSettings({ profilePhotoVisibility: nextVisibility(settings.profilePhotoVisibility) })} />
          <NeuSettingRow label="About" description={cap(settings.aboutVisibility)} showChevron onClick={() => updateSettings({ aboutVisibility: nextVisibility(settings.aboutVisibility) })} />
          <NeuSettingRow label="Status" description={cap(settings.statusVisibility)} showChevron onClick={() => updateSettings({ statusVisibility: nextVisibility(settings.statusVisibility) })} />
        </Section>

        <Section title="Read receipts">
          <ToggleRow
            icon={<Check size={18} />}
            label="Read receipts"
            description="Show blue ticks when messages are read"
            checked={settings.readReceipts}
            onChange={(v) => updateSettings({ readReceipts: v })}
          />
        </Section>

        <Section title="Groups & Calls">
          <NeuSettingRow label="Who can add me to groups" description={cap(settings.whoCanAddToGroups)} showChevron onClick={() => updateSettings({ whoCanAddToGroups: settings.whoCanAddToGroups === "everyone" ? "contacts" : "everyone" })} />
          <ToggleRow
            icon={<Bell size={18} />}
            label="Silence unknown callers"
            description="Calls from unknown numbers won't ring"
            checked={settings.silenceUnknownCallers}
            onChange={(v) => updateSettings({ silenceUnknownCallers: v })}
          />
        </Section>

        <Section title="Security">
          <ToggleRow
            label="Fingerprint lock"
            description="Require biometric to open Zaxo"
            checked={settings.fingerprintLock}
            onChange={(v) => updateSettings({ fingerprintLock: v })}
          />
          <NeuSettingRow
            label="Fingerprint lock timeout"
            description={cap(settings.fingerprintLockTimeout).replace("_", " ")}
            showChevron
            onClick={() => {
              const timeouts = ["immediate", "1min", "5min", "30min"] as const;
              const i = timeouts.indexOf(settings.fingerprintLockTimeout);
              updateSettings({ fingerprintLockTimeout: timeouts[(i + 1) % timeouts.length] });
            }}
          />
          <ToggleRow
            label="Hide notification content"
            description="Hide message text in notifications"
            checked={settings.hideNotificationContent}
            onChange={(v) => updateSettings({ hideNotificationContent: v })}
          />
          <ToggleRow
            label="Block screenshots"
            description="Prevent screenshots in chat"
            checked={settings.blockScreenshots}
            onChange={(v) => updateSettings({ blockScreenshots: v })}
          />
        </Section>

        <Section title="Blocked">
          <NeuSettingRow
            icon={<Shield size={18} />}
            label="Blocked contacts"
            description="Manage blocked users"
            showChevron
            onClick={() => setSubPanel({ type: "settings_blocked" })}
          />
        </Section>
      </div>
    </>
  );
}

// ==================== NOTIFICATIONS ====================
function NotificationsSettings({ onClose }: { onClose: () => void }) {
  const { settings, updateSettings } = useSettingsStore();
  return (
    <>
      <SettingsHeader title="Notifications" onClose={onClose} />
      <div className="flex-1 overflow-y-auto neu-scroll px-4 pb-6">
        <IntroBanner text="Choose how and when you're notified about messages, calls, and status updates. Quiet hours mute all non-critical alerts." />
        <Section title="Message notifications">
          <ToggleRow icon={<Bell size={18} />} label="Show notifications" checked={settings.messageNotifications} onChange={(v) => updateSettings({ messageNotifications: v })} />
          <NeuSettingRow label="Notification tone" description={settings.messageTone} showChevron onClick={() => updateSettings({ messageTone: settings.messageTone === "default" ? "chime" : "default" })} />
          <ToggleRow label="Vibrate" checked={settings.messageVibrate} onChange={(v) => updateSettings({ messageVibrate: v })} />
          <ToggleRow label="Show preview" description="Show sender & message in notification" checked={settings.showPreview} onChange={(v) => updateSettings({ showPreview: v })} />
        </Section>

        <Section title="Group & call notifications">
          <ToggleRow label="Group notifications" checked={settings.groupNotifications} onChange={(v) => updateSettings({ groupNotifications: v })} />
          <ToggleRow label="Call notifications" checked={settings.callNotifications} onChange={(v) => updateSettings({ callNotifications: v })} />
          <NeuSettingRow label="Call ringtone" description={settings.callRingtone} showChevron onClick={() => updateSettings({ callRingtone: settings.callRingtone === "default" ? "cosmic" : "default" })} />
        </Section>

        <Section title="Reaction & status">
          <ToggleRow label="Reaction notifications" checked={settings.reactionNotifications} onChange={(v) => updateSettings({ reactionNotifications: v })} />
          <ToggleRow label="Status notifications" checked={settings.statusNotifications} onChange={(v) => updateSettings({ statusNotifications: v })} />
        </Section>

        <Section title="Quiet hours">
          <ToggleRow label="Enable quiet hours" description="Mute notifications during set hours" checked={settings.quietHoursEnabled} onChange={(v) => updateSettings({ quietHoursEnabled: v })} />
          {settings.quietHoursEnabled && (
            <>
              <NeuSettingRow label="Start time" description={settings.quietHoursStart} showChevron />
              <NeuSettingRow label="End time" description={settings.quietHoursEnd} showChevron />
            </>
          )}
        </Section>
      </div>
    </>
  );
}

// ==================== CHATS SETTINGS ====================
function ChatsSettings({ onClose }: { onClose: () => void }) {
  const { settings, updateSettings } = useSettingsStore();
  return (
    <>
      <SettingsHeader title="Chats" onClose={onClose} />
      <div className="flex-1 overflow-y-auto neu-scroll px-4 pb-6">
        <IntroBanner text="Personalize chat appearance, manage media auto-download rules, and configure automatic chat backups to keep your conversations safe." />
        <Section title="Display">
          <NeuSettingRow label="Chat wallpaper" description={settings.chatWallpaper} showChevron />
          <NeuSettingRow label="Message text size" description={cap(settings.messageTextSize)} showChevron onClick={() => {
            const sizes = ["small", "medium", "large"] as const;
            const i = sizes.indexOf(settings.messageTextSize);
            updateSettings({ messageTextSize: sizes[(i + 1) % sizes.length] });
          }} />
        </Section>

        <Section title="Media auto-download">
          <ToggleRow label="When using mobile data" checked={settings.autoDownloadMobile} onChange={(v) => updateSettings({ autoDownloadMobile: v })} />
          <ToggleRow label="When using Wi-Fi" checked={settings.autoDownloadWifi} onChange={(v) => updateSettings({ autoDownloadWifi: v })} />
          <ToggleRow label="When roaming" checked={settings.autoDownloadRoaming} onChange={(v) => updateSettings({ autoDownloadRoaming: v })} />
          <NeuSettingRow label="Media quality" description={cap(settings.mediaQuality)} showChevron onClick={() => updateSettings({ mediaQuality: settings.mediaQuality === "standard" ? "high" : "standard" })} />
        </Section>

        <Section title="Chat backup">
          <NeuSettingRow label="Backup frequency" description={cap(settings.backupFrequency)} showChevron onClick={() => {
            const opts = ["never", "daily", "weekly", "monthly"] as const;
            const i = opts.indexOf(settings.backupFrequency);
            updateSettings({ backupFrequency: opts[(i + 1) % opts.length] });
          }} />
          <ToggleRow label="Include videos" checked={settings.backupIncludeVideos} onChange={(v) => updateSettings({ backupIncludeVideos: v })} />
          <NeuSettingRow label="Last backup" description="Yesterday, 23:00" showChevron />
        </Section>

        <Section title="Message retention">
          <NeuSettingRow label="Default disappearing timer" description={settings.defaultDisappearingTimer === "off" ? "Off" : settings.defaultDisappearingTimer.toUpperCase()} showChevron onClick={() => {
            const opts = ["off", "24h", "7d", "90d"] as const;
            const i = opts.indexOf(settings.defaultDisappearingTimer);
            updateSettings({ defaultDisappearingTimer: opts[(i + 1) % opts.length] });
          }} />
          <NeuSettingRow label="Keep messages" description={settings.keepMessages === "forever" ? "Forever" : `${settings.keepMessages}`} showChevron onClick={() => {
            const opts = ["forever", "30d", "90d"] as const;
            const i = opts.indexOf(settings.keepMessages);
            updateSettings({ keepMessages: opts[(i + 1) % opts.length] });
          }} />
        </Section>
      </div>
    </>
  );
}

// ==================== STORAGE ====================
function StorageSettings({ onClose }: { onClose: () => void }) {
  const { settings, updateSettings } = useSettingsStore();
  return (
    <>
      <SettingsHeader title="Data & Storage" onClose={onClose} />
      <div className="flex-1 overflow-y-auto neu-scroll px-4 pb-6">
        <IntroBanner text="Monitor storage used by media, documents, and voice messages. Clearing cache frees space without deleting your messages." />
        <Section title="Storage usage">
          <div className="neu-raised rounded-2xl p-4 mb-3">
            <div className="text-xs neu-text-muted mb-2">Total storage used</div>
            <div className="text-3xl font-bold neu-text">2.4 GB</div>
            <div className="mt-3 h-3 rounded-full neu-well overflow-hidden">
              <div className="h-full flex">
                <div style={{ width: "45%", background: "var(--neu-accent)" }} />
                <div style={{ width: "30%", background: "var(--neu-success)" }} />
                <div style={{ width: "15%", background: "var(--neu-warning)" }} />
                <div style={{ width: "10%", background: "var(--neu-danger)" }} />
              </div>
            </div>
            <div className="mt-2 grid grid-cols-2 gap-2 text-xs">
              <div className="flex items-center gap-2"><span className="w-2 h-2 rounded-full" style={{ background: "var(--neu-accent)" }} /> Media 1.08 GB</div>
              <div className="flex items-center gap-2"><span className="w-2 h-2 rounded-full" style={{ background: "var(--neu-success)" }} /> Documents 720 MB</div>
              <div className="flex items-center gap-2"><span className="w-2 h-2 rounded-full" style={{ background: "var(--neu-warning)" }} /> Voice 360 MB</div>
              <div className="flex items-center gap-2"><span className="w-2 h-2 rounded-full" style={{ background: "var(--neu-danger)" }} />Other 240 MB</div>
            </div>
          </div>
          <NeuSettingRow icon={<Trash2 size={18} />} label="Clear cache" description="Free up 240 MB" showChevron onClick={() => alert("Cache cleared")} />
          <NeuSettingRow icon={<Trash2 size={18} />} label="Find large files" description="Files larger than 5 MB" showChevron />
        </Section>

        <Section title="Network usage">
          <div className="neu-raised rounded-2xl p-4 mb-3">
            <div className="grid grid-cols-2 gap-3">
              <div>
                <div className="text-xs neu-text-muted">Sent</div>
                <div className="text-lg font-bold neu-text">1.2 GB</div>
              </div>
              <div>
                <div className="text-xs neu-text-muted">Received</div>
                <div className="text-lg font-bold neu-text">3.8 GB</div>
              </div>
              <div>
                <div className="text-xs neu-text-muted">Calls data</div>
                <div className="text-lg font-bold neu-text">580 MB</div>
              </div>
              <div>
                <div className="text-xs neu-text-muted">Total</div>
                <div className="text-lg font-bold neu-text-accent">5.6 GB</div>
              </div>
            </div>
          </div>
          <ToggleRow label="Low data mode for calls" checked={false} onChange={() => {}} />
        </Section>
      </div>
    </>
  );
}

// ==================== APPEARANCE ====================
function AppearanceSettings({ onClose }: { onClose: () => void }) {
  const { theme, setTheme, settings, updateSettings } = useSettingsStore();
  return (
    <>
      <SettingsHeader title="Appearance" onClose={onClose} />
      <div className="flex-1 overflow-y-auto neu-scroll px-4 pb-6">
        <IntroBanner text="Customize the visual style of Zaxo. Neumorphism intensity controls how soft or strong the surface shadows look across the app." />
        <Section title="Theme">
          <div className="neu-raised rounded-2xl p-3 mb-3 flex gap-2">
            {(["light", "dark"] as const).map((t) => (
              <button
                key={t}
                onClick={() => setTheme(t)}
                className={`flex-1 py-3 rounded-xl text-sm font-medium capitalize transition-all ${theme === t ? "neu-inset neu-text-accent" : "neu-text-muted"}`}
              >
                {t}
              </button>
            ))}
          </div>
          <div className="text-xs neu-text-muted px-1">Follows system by default. Tap to override.</div>
        </Section>

        <Section title="Neumorphism">
          <div className="neu-raised rounded-2xl p-4 mb-3">
            <div className="text-xs neu-text-muted mb-2">Intensity</div>
            <div className="flex gap-2 mb-3">
              {(["subtle", "normal", "strong"] as const).map((i) => (
                <button
                  key={i}
                  onClick={() => updateSettings({ neumorphismIntensity: i })}
                  className={`flex-1 py-2 rounded-xl text-xs font-medium capitalize transition-all ${settings.neumorphismIntensity === i ? "neu-accent text-white" : "neu-raised-sm neu-text-muted"}`}
                >
                  {i}
                </button>
              ))}
            </div>
            <div className="text-xs neu-text-muted mb-2">Corner radius: {settings.cornerRadius}px</div>
            <input
              type="range"
              min={8}
              max={32}
              value={settings.cornerRadius}
              onChange={(e) => updateSettings({ cornerRadius: +e.target.value })}
              className="neu-range"
            />
          </div>
        </Section>

        <Section title="Accent color">
          <div className="neu-raised rounded-2xl p-4 mb-3 flex gap-3 overflow-x-auto no-scrollbar">
            {["#6C5CE7", "#00B894", "#FF6B6B", "#FECA57", "#74B9FF", "#E17055", "#A29BFE"].map((c) => (
              <button
                key={c}
                onClick={() => updateSettings({ accentColor: c })}
                className={`w-10 h-10 rounded-full shrink-0 transition-all ${settings.accentColor === c ? "ring-2 ring-offset-2 ring-offset-[var(--neu-bg)]" : ""}`}
                style={{ background: c, boxShadow: settings.accentColor === c ? `0 0 0 2px ${c}` : "none" }}
              />
            ))}
          </div>
        </Section>

        <Section title="Motion">
          <div className="neu-raised rounded-2xl p-3 mb-3 flex gap-2">
            {(["normal", "reduced"] as const).map((s) => (
              <button
                key={s}
                onClick={() => updateSettings({ animationSpeed: s })}
                className={`flex-1 py-2 rounded-xl text-sm font-medium capitalize transition-all ${settings.animationSpeed === s ? "neu-inset neu-text-accent" : "neu-text-muted"}`}
              >
                {s}
              </button>
            ))}
          </div>
          <ToggleRow label="Compact mode" description="Reduce padding for more density" checked={settings.compactMode} onChange={(v) => updateSettings({ compactMode: v })} />
        </Section>
      </div>
    </>
  );
}

// ==================== ACCESSIBILITY ====================
function AccessibilitySettings({ onClose }: { onClose: () => void }) {
  const { settings, updateSettings } = useSettingsStore();
  return (
    <>
      <SettingsHeader title="Accessibility" onClose={onClose} />
      <div className="flex-1 overflow-y-auto neu-scroll px-4 pb-6">
        <IntroBanner text="Make Zaxo work better for you. Adjust font scaling, enable high contrast, or reduce motion if you prefer fewer animations." />
        <Section title="Text & contrast">
          <div className="neu-raised rounded-2xl p-4 mb-3">
            <div className="text-xs neu-text-muted mb-2">Font scaling: {Math.round(settings.fontScaling * 100)}%</div>
            <input
              type="range"
              min={85}
              max={140}
              value={Math.round(settings.fontScaling * 100)}
              onChange={(e) => updateSettings({ fontScaling: +e.target.value / 100 })}
              className="neu-range"
            />
            <div className="mt-3 text-sm neu-text" style={{ fontSize: `${settings.fontScaling}rem` }}>
              The quick brown fox jumps over the lazy dog
            </div>
          </div>
          <ToggleRow label="High contrast" checked={settings.highContrast} onChange={(v) => updateSettings({ highContrast: v })} />
          <ToggleRow label="Reduce motion" checked={settings.reduceMotion} onChange={(v) => updateSettings({ reduceMotion: v })} />
        </Section>

        <Section title="Screen reader">
          <div className="neu-raised rounded-2xl p-4 mb-3 text-sm neu-text">
            Zaxo supports TalkBack and VoiceOver. Enable screen reader from your device settings to hear chat content spoken aloud.
          </div>
        </Section>
      </div>
    </>
  );
}

// ==================== HELP ====================
function HelpSettings({ onClose }: { onClose: () => void }) {
  return (
    <>
      <SettingsHeader title="Help & About" onClose={onClose} />
      <div className="flex-1 overflow-y-auto neu-scroll px-4 pb-6">
        <IntroBanner text="Find answers, contact support, or read about how Zaxo protects your privacy. We're here to help whenever you need us." />
        <div className="neu-raised rounded-3xl p-6 mb-4 text-center">
          <div className="neu-floating w-20 h-20 rounded-3xl mx-auto flex items-center justify-center mb-3">
            <span className="text-3xl font-bold neu-text-accent">Z</span>
          </div>
          <div className="text-xl font-bold neu-text">Zaxo</div>
          <div className="text-xs neu-text-muted">Version 1.0.0 · Build 1</div>
        </div>

        <Section title="Help">
          <NeuSettingRow label="FAQ" description="Common questions and answers" showChevron />
          <NeuSettingRow label="Contact support" description="Chat with our team" showChevron />
          <NeuSettingRow label="Terms of service" showChevron />
          <NeuSettingRow label="Privacy policy" showChevron />
        </Section>

        <Section title="About">
          <div className="neu-raised rounded-2xl p-4 mb-3 text-sm neu-text leading-relaxed">
            Zaxo is a modern social messenger that connects you with anyone, anywhere using a permanent 9-digit Zaxo number. Built with neumorphic design and end-to-end encryption.
          </div>
          <NeuSettingRow label="Open source licenses" showChevron />
        </Section>
      </div>
    </>
  );
}

// ==================== LINKED DEVICES ====================
function LinkedDevicesSettings({ onClose }: { onClose: () => void }) {
  return (
    <>
      <SettingsHeader title="Linked Devices" onClose={onClose} />
      <div className="flex-1 overflow-y-auto neu-scroll px-4 pb-6">
        <IntroBanner text="Use Zaxo on multiple devices without keeping your phone online. Linked devices mirror your chats securely with end-to-end encryption." />
        <Section title="Active sessions">
          <NeuSettingRow
            icon={<Bell size={18} />}
            label="Zaxo Web (Chrome)"
            description="Last active 2 minutes ago · Kuala Lumpur"
            showChevron
          />
          <NeuSettingRow
            icon={<Bell size={18} />}
            label="Zaxo Desktop (macOS)"
            description="Last active 3 hours ago · Singapore"
            showChevron
          />
        </Section>

        <NeuButton variant="accent" fullWidth rounded="xl" icon={<Plus size={16} />}>Link a new device</NeuButton>
        <p className="text-xs neu-text-muted text-center mt-2">
          Scan QR code from the device you want to link
        </p>
      </div>
    </>
  );
}

// ==================== BLOCKED ====================
function BlockedSettings({ onClose }: { onClose: () => void }) {
  const { contacts, blockedIds, unblockContact } = useAppStore();
  const blocked = contacts.filter((c) => blockedIds.includes(c.id));

  return (
    <>
      <SettingsHeader title="Blocked Contacts" onClose={onClose} />
      <div className="flex-1 overflow-y-auto neu-scroll px-4 pb-6">
        <IntroBanner text="Blocked contacts can't send you messages or call you. They won't be notified that they're blocked, and you can unblock them anytime." />
        {blocked.length === 0 ? (
          <div className="flex flex-col items-center justify-center h-full px-8 text-center py-20">
            <div className="neu-raised-lg rounded-3xl w-24 h-24 flex items-center justify-center mb-4">
              <Shield size={36} className="neu-text-muted" />
            </div>
            <h3 className="text-base font-semibold neu-text">No blocked contacts</h3>
            <p className="text-xs neu-text-muted mt-2 max-w-xs">Blocked contacts can&apos;t call you or send you messages.</p>
          </div>
        ) : (
          blocked.map((c) => (
            <div key={c.id} className="flex items-center gap-3 px-3 py-3 rounded-2xl">
              <NeuAvatar initial={c.avatarInitial} gradient={c.avatarColor} size={44} />
              <div className="flex-1 min-w-0">
                <div className="font-semibold text-sm neu-text truncate">{c.displayName}</div>
                <div className="text-xs neu-text-muted font-mono">{c.zaxoNumber || "No Zaxo number"}</div>
              </div>
              <NeuButton variant="raised" size="sm" rounded="xl" onClick={() => unblockContact(c.id)}>Unblock</NeuButton>
            </div>
          ))
        )}
      </div>
    </>
  );
}

// ==================== TWO STEP VERIFICATION (real passcode) ====================
function TwoStepSettings({ onClose }: { onClose: () => void }) {
  const { settings, updateSettings } = useSettingsStore();
  const { setPasscode, verifyPasscode, disableAppLock } = useSecurityStore();
  const [pin, setPin] = useState("");
  const [confirmPin, setConfirmPin] = useState("");
  const [step, setStep] = useState<"enter" | "confirm" | "verify">("enter");
  const [verifyPin, setVerifyPin] = useState("");
  const [error, setError] = useState("");
  const [enabled, setEnabled] = useState(settings.twoStepVerificationEnabled);
  const [loading, setLoading] = useState(false);

  async function handleSetPin() {
    setError("");
    if (pin.length !== 6) {
      setError("PIN must be exactly 6 digits");
      return;
    }
    if (step === "enter") {
      setStep("confirm");
      return;
    }
    if (step === "confirm") {
      if (pin !== confirmPin) {
        setError("PINs do not match. Try again.");
        setConfirmPin("");
        return;
      }
      setLoading(true);
      await setPasscode(pin);
      updateSettings({ twoStepVerificationEnabled: true });
      setEnabled(true);
      setLoading(false);
      setPin("");
      setConfirmPin("");
      setStep("enter");
    }
  }

  async function handleVerify() {
    setLoading(true);
    setError("");
    const ok = await verifyPasscode(verifyPin);
    setLoading(false);
    if (ok) {
      // Verified — allow disable
      handleDisable();
    } else {
      setError("Incorrect PIN. Please try again.");
      setVerifyPin("");
    }
  }

  function handleDisable() {
    disableAppLock();
    updateSettings({ twoStepVerificationEnabled: false });
    setEnabled(false);
    setPin("");
    setConfirmPin("");
    setVerifyPin("");
    setStep("enter");
  }

  return (
    <>
      <SettingsHeader title="Two-Step Verification" onClose={onClose} />
      <div className="flex-1 overflow-y-auto neu-scroll px-4 pb-6">
        <IntroBanner icon={<Shield size={14} />} text="Two-step verification adds a 6-digit PIN as an extra layer of security. You'll be asked for this PIN when registering your Zaxo number on a new device." />
        <Section title="Status">
          <div className="neu-raised rounded-2xl p-4 mb-3">
            <div className="text-xs neu-text-muted">Two-step verification</div>
            <div className="text-base font-semibold neu-text mt-1">{enabled ? "Enabled" : "Disabled"}</div>
            <div className="text-xs neu-text-muted mt-2">
              {enabled
                ? "Your account is protected with a 6-digit PIN stored securely (SHA-256 hashed)."
                : "Add an extra layer of security. You'll need a PIN to register your Zaxo number on new devices."}
            </div>
          </div>
        </Section>

        {!enabled ? (
          <Section title={step === "enter" ? "Set up PIN" : "Confirm PIN"}>
            {error && (
              <div className="neu-inset rounded-xl px-3 py-2 mb-3 text-xs neu-text-danger flex items-center gap-2">
                <AlertCircle size={14} /> {error}
              </div>
            )}
            <div className="neu-raised rounded-2xl p-4 mb-3">
              <div className="text-xs neu-text-muted mb-2">
                {step === "enter" ? "Enter a 6-digit PIN" : "Re-enter your PIN to confirm"}
              </div>
              <input
                type="tel"
                inputMode="numeric"
                autoFocus
                value={step === "enter" ? pin : confirmPin}
                onChange={(e) => {
                  const v = e.target.value.replace(/\D/g, "").slice(0, 6);
                  if (step === "enter") setPin(v);
                  else setConfirmPin(v);
                }}
                placeholder="••••••"
                className="neu-well rounded-2xl px-4 py-3 text-2xl tracking-[0.5em] neu-text outline-none text-center w-full"
                maxLength={6}
              />
              <div className="flex gap-1.5 justify-center mt-3">
                {Array.from({ length: 6 }).map((_, i) => (
                  <div
                    key={i}
                    className={`w-2.5 h-2.5 rounded-full ${i < (step === "enter" ? pin : confirmPin).length ? "neu-accent" : "neu-raised-sm"}`}
                  />
                ))}
              </div>
            </div>
            <div className="flex gap-2">
              {step === "confirm" && (
                <NeuButton variant="raised" fullWidth rounded="xl" onClick={() => { setStep("enter"); setConfirmPin(""); setError(""); }}>Back</NeuButton>
              )}
              <NeuButton
                variant="accent"
                fullWidth
                rounded="xl"
                loading={loading}
                disabled={(step === "enter" ? pin : confirmPin).length !== 6}
                onClick={handleSetPin}
              >
                {step === "enter" ? "Next" : "Enable"}
              </NeuButton>
            </div>
          </Section>
        ) : (
          <>
            <Section title="PIN management">
              <NeuSettingRow
                label="Change PIN"
                description="Update your 6-digit PIN"
                showChevron
                onClick={() => {
                  setEnabled(false);
                  updateSettings({ twoStepVerificationEnabled: false });
                  setStep("enter");
                }}
              />
              <NeuSettingRow label="Recovery email" description="Not set" showChevron />
            </Section>

            <Section title="Disable">
              <div className="neu-raised rounded-2xl p-4 mb-3">
                <div className="text-xs neu-text-muted mb-2">Verify your PIN to disable</div>
                <input
                  type="tel"
                  inputMode="numeric"
                  value={verifyPin}
                  onChange={(e) => setVerifyPin(e.target.value.replace(/\D/g, "").slice(0, 6))}
                  placeholder="Enter PIN"
                  className="neu-well rounded-2xl px-4 py-3 text-xl tracking-[0.5em] neu-text outline-none text-center w-full"
                  maxLength={6}
                />
                {error && (
                  <div className="mt-2 text-xs neu-text-danger flex items-center gap-2">
                    <AlertCircle size={12} /> {error}
                  </div>
                )}
              </div>
              <NeuButton
                variant="danger"
                fullWidth
                rounded="xl"
                icon={<Trash2 size={16} />}
                loading={loading}
                disabled={verifyPin.length !== 6}
                onClick={handleVerify}
              >
                Disable two-step verification
              </NeuButton>
            </Section>
          </>
        )}
      </div>
    </>
  );
}

// ==================== APP LOCK (real biometric + passcode) ====================
function AppLockSettings({ onClose }: { onClose: () => void }) {
  const {
    appLockEnabled, appLockMethod, biometricCredentialId,
    lockTimeoutSeconds, enableAppLock, disableAppLock,
    setPasscode, enrollBiometric, setLockTimeout, setRecoveryEmail, recoveryEmail, lockNow,
  } = useSecurityStore();

  const [bioAvailable, setBioAvailable] = useState(false);
  const [step, setStep] = useState<"setup-method" | "setup-pin" | "setup-bio" | "confirm-pin">("setup-method");
  const [chosenMethod, setChosenMethod] = useState<"biometric" | "passcode" | "both">("passcode");
  const [pin, setPin] = useState("");
  const [confirmPin, setConfirmPin] = useState("");
  const [error, setError] = useState("");
  const [loading, setLoading] = useState(false);
  const [verifyPin, setVerifyPin] = useState("");
  const [disableStep, setDisableStep] = useState<"confirm" | "verify">("confirm");
  const [email, setEmail] = useState(recoveryEmail || "");

  useEffect(() => {
    isBiometricAvailable().then(setBioAvailable);
  }, []);

  async function handleEnable() {
    setError("");
    setLoading(true);
    try {
      if (chosenMethod === "biometric" || chosenMethod === "both") {
        const ok = await enrollBiometric();
        if (!ok) {
          setError("Biometric enrollment failed. Your device may not support platform biometrics, or permission was denied.");
          setLoading(false);
          return;
        }
      }
      if (chosenMethod === "passcode" || chosenMethod === "both") {
        if (pin.length !== 6) {
          setError("PIN must be exactly 6 digits");
          setLoading(false);
          return;
        }
        if (step === "setup-pin") {
          setStep("confirm-pin");
          setLoading(false);
          return;
        }
        if (step === "confirm-pin") {
          if (pin !== confirmPin) {
            setError("PINs do not match.");
            setConfirmPin("");
            setLoading(false);
            return;
          }
          await setPasscode(pin);
        }
      }
      enableAppLock(chosenMethod);
      setStep("setup-method");
      setPin("");
      setConfirmPin("");
    } finally {
      setLoading(false);
    }
  }

  function handleDisable() {
    disableAppLock();
    setDisableStep("confirm");
    setVerifyPin("");
  }

  const timeouts = [
    { label: "Immediately", value: 0 },
    { label: "After 1 minute", value: 60 },
    { label: "After 5 minutes", value: 300 },
    { label: "After 30 minutes", value: 1800 },
  ];

  return (
    <>
      <SettingsHeader title="App Lock" onClose={onClose} />
      <div className="flex-1 overflow-y-auto neu-scroll px-4 pb-6">
        <IntroBanner icon={<Fingerprint size={14} />} text="App Lock requires biometric authentication (fingerprint / Face ID) or a 6-digit passcode to open Zaxo. Your data stays encrypted and locked when the app is in the background." />

        {!bioAvailable && (
          <div className="neu-inset rounded-2xl px-3 py-2.5 mb-4 flex items-start gap-2.5">
            <AlertCircle size={14} className="shrink-0 mt-0.5 neu-text-warning" />
            <div className="text-xs neu-text-muted leading-relaxed">
              Biometric authentication isn't available on this device/browser. You can still use a 6-digit passcode.
            </div>
          </div>
        )}

        {/* Status */}
        <Section title="Status">
          <div className="neu-raised rounded-2xl p-4 mb-3">
            <div className="flex items-center justify-between">
              <div>
                <div className="text-xs neu-text-muted">App lock</div>
                <div className="text-base font-semibold neu-text mt-1">{appLockEnabled ? "Enabled" : "Disabled"}</div>
              </div>
              <NeuToggle checked={appLockEnabled} onChange={(v) => v ? setStep("setup-method") : setDisableStep("verify")} />
            </div>
            {appLockEnabled && (
              <div className="text-xs neu-text-muted mt-2">
                Method: <span className="neu-text-accent capitalize">{appLockMethod}</span>
                {biometricCredentialId && " · Biometric enrolled ✓"}
              </div>
            )}
          </div>
        </Section>

        {/* Enable flow */}
        {appLockEnabled === false && step === "setup-method" && (
          <Section title="Choose method">
            <button
              onClick={() => { setChosenMethod("biometric"); setStep("setup-bio"); }}
              disabled={!bioAvailable}
              className={`w-full neu-raised-sm rounded-2xl px-4 py-3 mb-2 flex items-center gap-3 text-left ${!bioAvailable ? "opacity-50" : ""}`}
            >
              <div className="neu-inset rounded-xl w-9 h-9 flex items-center justify-center neu-text-accent">
                <Fingerprint size={18} />
              </div>
              <div className="flex-1">
                <div className="text-sm font-medium neu-text">Biometric only</div>
                <div className="text-xs neu-text-muted">Use fingerprint or face recognition</div>
              </div>
            </button>
            <button
              onClick={() => { setChosenMethod("passcode"); setStep("setup-pin"); }}
              className="w-full neu-raised-sm rounded-2xl px-4 py-3 mb-2 flex items-center gap-3 text-left"
            >
              <div className="neu-inset rounded-xl w-9 h-9 flex items-center justify-center neu-text-accent">
                <Lock size={18} />
              </div>
              <div className="flex-1">
                <div className="text-sm font-medium neu-text">Passcode only</div>
                <div className="text-xs neu-text-muted">6-digit numeric PIN (SHA-256 hashed)</div>
              </div>
            </button>
            <button
              onClick={() => { setChosenMethod("both"); setStep("setup-pin"); }}
              disabled={!bioAvailable}
              className={`w-full neu-raised-sm rounded-2xl px-4 py-3 mb-2 flex items-center gap-3 text-left ${!bioAvailable ? "opacity-50" : ""}`}
            >
              <div className="neu-inset rounded-xl w-9 h-9 flex items-center justify-center neu-text-accent">
                <Shield size={18} />
              </div>
              <div className="flex-1">
                <div className="text-sm font-medium neu-text">Both (recommended)</div>
                <div className="text-xs neu-text-muted">Biometric primary, passcode as backup</div>
              </div>
            </button>
          </Section>
        )}

        {/* Setup PIN flow */}
        {(step === "setup-pin" || step === "confirm-pin") && (
          <Section title={step === "setup-pin" ? "Set up 6-digit passcode" : "Confirm passcode"}>
            {error && (
              <div className="neu-inset rounded-xl px-3 py-2 mb-3 text-xs neu-text-danger flex items-center gap-2">
                <AlertCircle size={14} /> {error}
              </div>
            )}
            <div className="neu-raised rounded-2xl p-4 mb-3">
              <div className="text-xs neu-text-muted mb-2">
                {step === "setup-pin" ? "Enter a 6-digit PIN" : "Re-enter to confirm"}
              </div>
              <input
                type="tel"
                inputMode="numeric"
                autoFocus
                value={step === "setup-pin" ? pin : confirmPin}
                onChange={(e) => {
                  const v = e.target.value.replace(/\D/g, "").slice(0, 6);
                  if (step === "setup-pin") setPin(v);
                  else setConfirmPin(v);
                }}
                placeholder="••••••"
                className="neu-well rounded-2xl px-4 py-3 text-2xl tracking-[0.5em] neu-text outline-none text-center w-full"
                maxLength={6}
              />
              <div className="flex gap-1.5 justify-center mt-3">
                {Array.from({ length: 6 }).map((_, i) => (
                  <div
                    key={i}
                    className={`w-2.5 h-2.5 rounded-full ${i < (step === "setup-pin" ? pin : confirmPin).length ? "neu-accent" : "neu-raised-sm"}`}
                  />
                ))}
              </div>
            </div>
            <div className="flex gap-2">
              <NeuButton variant="raised" fullWidth rounded="xl" onClick={() => { setStep("setup-method"); setPin(""); setConfirmPin(""); setError(""); }}>Back</NeuButton>
              <NeuButton
                variant="accent"
                fullWidth
                rounded="xl"
                loading={loading}
                disabled={(step === "setup-pin" ? pin : confirmPin).length !== 6}
                onClick={handleEnable}
              >
                {step === "setup-pin" ? "Next" : "Enable app lock"}
              </NeuButton>
            </div>
          </Section>
        )}

        {/* Setup biometric */}
        {step === "setup-bio" && (
          <Section title="Enroll biometric">
            <div className="neu-raised rounded-2xl p-4 mb-3 text-center">
              <Fingerprint size={48} className="mx-auto neu-text-accent mb-2" />
              <div className="text-sm neu-text">Touch your sensor or look at the camera when prompted by your browser.</div>
            </div>
            <div className="flex gap-2">
              <NeuButton variant="raised" fullWidth rounded="xl" onClick={() => setStep("setup-method")}>Back</NeuButton>
              <NeuButton variant="accent" fullWidth rounded="xl" loading={loading} onClick={handleEnable}>Enroll & enable</NeuButton>
            </div>
          </Section>
        )}

        {/* When enabled: show options */}
        {appLockEnabled && (
          <>
            <Section title="Auto-lock">
              <div className="neu-raised rounded-2xl p-2 mb-3">
                {timeouts.map((t) => (
                  <button
                    key={t.value}
                    onClick={() => setLockTimeout(t.value)}
                    className={`w-full px-3 py-2.5 rounded-xl text-sm flex items-center justify-between transition-all ${lockTimeoutSeconds === t.value ? "neu-inset neu-text-accent font-medium" : "neu-text"}`}
                  >
                    {t.label}
                    {lockTimeoutSeconds === t.value && <Check size={16} />}
                  </button>
                ))}
              </div>
              <div className="text-xs neu-text-muted px-1">
                Zaxo will lock automatically when you switch away and return after the selected time.
              </div>
            </Section>

            <Section title="Recovery">
              <div className="neu-raised rounded-2xl p-4 mb-3">
                <div className="text-xs neu-text-muted mb-1">Recovery email (optional)</div>
                <input
                  type="email"
                  value={email}
                  onChange={(e) => setEmail(e.target.value)}
                  placeholder="you@example.com"
                  className="neu-well rounded-xl px-3 py-2 text-sm neu-text outline-none w-full mt-1"
                />
                <div className="text-[10px] neu-text-muted mt-2">
                  Used to reset your passcode if you forget it. We never share this email.
                </div>
              </div>
              <NeuButton variant="raised" fullWidth rounded="xl" onClick={() => { setRecoveryEmail(email); }}>Save recovery email</NeuButton>
            </Section>

            <Section title="Test">
              <NeuButton variant="raised" fullWidth rounded="xl" icon={<Lock size={16} />} onClick={() => lockNow()}>
                Lock now
              </NeuButton>
              <div className="text-xs neu-text-muted px-1 mt-2">
                Locks Zaxo immediately to verify your settings.
              </div>
            </Section>

            <Section title="Disable">
              {disableStep === "confirm" ? (
                <NeuButton variant="danger" fullWidth rounded="xl" icon={<Trash2 size={16} />} onClick={() => setDisableStep("verify")}>
                  Disable app lock
                </NeuButton>
              ) : (
                <div className="neu-raised rounded-2xl p-4 mb-3">
                  <div className="text-xs neu-text-muted mb-2">Verify passcode to disable</div>
                  <input
                    type="tel"
                    inputMode="numeric"
                    value={verifyPin}
                    onChange={(e) => setVerifyPin(e.target.value.replace(/\D/g, "").slice(0, 6))}
                    placeholder="Enter PIN"
                    className="neu-well rounded-2xl px-4 py-3 text-xl tracking-[0.5em] neu-text outline-none text-center w-full"
                    maxLength={6}
                  />
                  <div className="flex gap-2 mt-3">
                    <NeuButton variant="raised" fullWidth rounded="xl" onClick={() => { setDisableStep("confirm"); setVerifyPin(""); }}>Cancel</NeuButton>
                    <NeuButton
                      variant="danger"
                      fullWidth
                      rounded="xl"
                      disabled={verifyPin.length !== 6}
                      onClick={async () => {
                        const ok = await useSecurityStore.getState().verifyPasscode(verifyPin);
                        if (ok) handleDisable();
                        else alert("Incorrect PIN");
                      }}
                    >
                      Confirm disable
                    </NeuButton>
                  </div>
                </div>
              )}
            </Section>
          </>
        )}
      </div>
    </>
  );
}

// ==================== HELPERS ====================
function Section({ title, children }: { title: string; children: React.ReactNode }) {
  return (
    <div className="mb-4">
      <div className="px-1 py-2 text-xs font-semibold neu-text-muted uppercase tracking-wider">{title}</div>
      {children}
    </div>
  );
}

function ToggleRow({ icon, label, description, checked, onChange }: {
  icon?: React.ReactNode;
  label: string;
  description?: string;
  checked: boolean;
  onChange: (v: boolean) => void;
}) {
  return (
    <div className="neu-raised rounded-2xl px-4 py-3 mb-2 flex items-center gap-3">
      {icon && (
        <div className="neu-inset rounded-xl w-9 h-9 flex items-center justify-center neu-text-muted">
          {icon}
        </div>
      )}
      <div className="flex-1 min-w-0">
        <div className="text-sm font-medium neu-text">{label}</div>
        {description && <div className="text-xs neu-text-muted mt-0.5">{description}</div>}
      </div>
      <NeuToggle checked={checked} onChange={onChange} />
    </div>
  );
}

function cap(s: string): string {
  return s.charAt(0).toUpperCase() + s.slice(1);
}

function nextVisibility(current: "everyone" | "contacts" | "nobody"): "everyone" | "contacts" | "nobody" {
  if (current === "everyone") return "contacts";
  if (current === "contacts") return "nobody";
  return "everyone";
}
