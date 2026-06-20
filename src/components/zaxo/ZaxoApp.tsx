// ==================== ZAXO MAIN APP ====================
"use client";

import { useEffect } from "react";
import { AnimatePresence, motion } from "framer-motion";
import { useUIStore } from "@/store/uiStore";
import { useAuthStore } from "@/store/authStore";
import { useSettingsStore } from "@/store/settingsStore";

import { SplashScreen } from "./SplashScreen";
import { AuthScreen, EmailAuthScreen } from "./AuthScreens";
import { CongratulationScreen } from "./CongratulationScreen";
import { BottomNav } from "./BottomNav";
import { ChatList } from "./ChatList";
import { ChatRoom } from "./ChatRoom";
import { CallsList } from "./CallsList";
import { CallScreen } from "./CallScreen";
import { StatusScreen, StatusViewer, StatusCreator } from "./StatusScreen";
import { YouScreen } from "./YouScreen";
import { SettingsPanel } from "./SettingsPanels";
import { ShareZaxoScreen, QRScannerScreen, NewChatScreen, NewGroupScreen } from "./NewChatScreens";

export function ZaxoApp() {
  const { screen, activeTab, subPanel, setScreen } = useUIStore();
  const { user, isAuthenticated } = useAuthStore();
  const { theme } = useSettingsStore();

  // Apply theme to <html>
  useEffect(() => {
    if (typeof document !== "undefined") {
      if (theme === "dark") document.documentElement.classList.add("dark");
      else document.documentElement.classList.remove("dark");
    }
  }, [theme]);

  // Auto-route based on auth state on first mount
  useEffect(() => {
    if (screen === "splash") {
      // Splash screen will redirect after animation
    } else if (!isAuthenticated && screen !== "auth" && screen !== "email_auth") {
      setScreen("auth");
    }
  }, [isAuthenticated, screen, setScreen]);

  return (
    <div className="mobile-frame relative overflow-hidden flex flex-col" style={{ height: "100vh", background: "var(--neu-bg)" }}>
      <AnimatePresence mode="wait">
        {screen === "splash" && (
          <motion.div key="splash" exit={{ opacity: 0 }} className="absolute inset-0">
            <SplashScreen />
          </motion.div>
        )}

        {screen === "auth" && (
          <motion.div key="auth" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="absolute inset-0">
            <AuthScreen />
          </motion.div>
        )}

        {screen === "email_auth" && (
          <motion.div key="email_auth" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="absolute inset-0">
            <EmailAuthScreen />
          </motion.div>
        )}

        {screen === "congratulations" && (
          <motion.div key="congrats" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="absolute inset-0">
            <CongratulationScreen />
          </motion.div>
        )}

        {screen === "main" && user && (
          <motion.div key="main" initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} className="absolute inset-0 flex flex-col">
            {/* Main content */}
            <div className="flex-1 overflow-hidden relative">
              {activeTab === "chats" && <ChatList />}
              {activeTab === "calls" && <CallsList />}
              {activeTab === "status" && <StatusScreen />}
              {activeTab === "you" && <YouScreen />}

              {/* Sub-panel overlay (chat room, settings, etc) */}
              <AnimatePresence>
                {subPanel.type !== "none" && (
                  <motion.div
                    key={subPanel.type + (subPanel.type === "chat_room" ? subPanel.chatId : subPanel.type === "call_screen" ? subPanel.otherUserId : subPanel.type === "status_viewer" ? subPanel.userId : "")}
                    initial={{ x: "100%" }}
                    animate={{ x: 0 }}
                    exit={{ x: "100%" }}
                    transition={{ type: "spring", damping: 32, stiffness: 320 }}
                    className="absolute inset-0 z-30 flex flex-col"
                    style={{ background: "var(--neu-bg)" }}
                  >
                    <SubPanelContent panel={subPanel} />
                  </motion.div>
                )}
              </AnimatePresence>
            </div>

            {/* Bottom navigation */}
            {subPanel.type === "none" && <BottomNav />}
          </motion.div>
        )}
      </AnimatePresence>
    </div>
  );
}

function SubPanelContent({ panel }: { panel: ReturnType<typeof useUIStore.getState>["subPanel"] }) {
  switch (panel.type) {
    case "chat_room":
      return <ChatRoom chatId={panel.chatId} />;
    case "status_viewer":
      return <StatusViewer userId={panel.userId} />;
    case "status_create":
      return <StatusCreator />;
    case "call_screen":
      return <CallScreen otherUserId={panel.otherUserId} callType={panel.callType} />;
    case "new_chat":
      return <NewChatScreen />;
    case "new_group":
      return <NewGroupScreen />;
    case "new_call":
      return <NewChatScreen />;
    case "share_zaxo":
      return <ShareZaxoScreen />;
    case "qr_scanner":
      return <QRScannerScreen />;
    case "settings_account":
    case "settings_privacy":
    case "settings_notifications":
    case "settings_chats":
    case "settings_storage":
    case "settings_appearance":
    case "settings_accessibility":
    case "settings_help":
    case "settings_linked_devices":
    case "settings_blocked":
    case "settings_two_step":
      return <SettingsPanel panelType={panel.type} />;
    default:
      return null;
  }
}
