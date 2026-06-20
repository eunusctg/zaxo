// ==================== NEUMORPHIC BOTTOM NAV ====================
"use client";

import { motion } from "framer-motion";
import { MessageCircle, Phone, Circle, User } from "lucide-react";
import { useAppStore } from "@/store/appStore";
import { useUIStore, type MainTab } from "@/store/uiStore";

interface NavItem {
  tab: MainTab;
  icon: React.ComponentType<{ size?: number }>;
  label: string;
  badge?: number;
}

export function BottomNav() {
  const { activeTab, setActiveTab } = useUIStore();
  const { chats, calls } = useAppStore();

  const totalUnread = chats
    .filter((c) => !c.isArchived)
    .reduce((sum, c) => sum + (c.unreadCount > 0 ? 1 : 0), 0);
  const missedCalls = calls.filter((c) => c.direction === "missed").length;

  const items: NavItem[] = [
    { tab: "chats", icon: MessageCircle, label: "Chats", badge: totalUnread },
    { tab: "calls", icon: Phone, label: "Calls", badge: missedCalls },
    { tab: "status", icon: Circle, label: "Status" },
    { tab: "you", icon: User, label: "You" },
  ];

  return (
    <div className="px-4 pb-4 pt-2" style={{ background: "var(--neu-bg)" }}>
      <div className="neu-raised rounded-3xl px-2 py-2 flex justify-around items-center">
        {items.map((item) => {
          const Icon = item.icon;
          const isActive = activeTab === item.tab;
          return (
            <button
              key={item.tab}
              onClick={() => setActiveTab(item.tab)}
              className="relative flex flex-col items-center justify-center transition-all focus-ring rounded-2xl px-4 py-2"
              style={{
                flex: 1,
                background: isActive ? "var(--neu-surface)" : "transparent",
                boxShadow: isActive
                  ? "inset 3px 3px 7px var(--neu-shadow-dark), inset -3px -3px 7px var(--neu-shadow-light)"
                  : "none",
              }}
              aria-label={item.label}
              aria-current={isActive ? "page" : undefined}
            >
              <div className="relative">
                <Icon size={22} />
                {item.badge && item.badge > 0 ? (
                  <motion.div
                    initial={{ scale: 0 }}
                    animate={{ scale: 1 }}
                    className="absolute -top-1.5 -right-2 min-w-[16px] h-[16px] px-1 rounded-full flex items-center justify-center text-[10px] font-bold text-white"
                    style={{ background: "var(--neu-danger)" }}
                  >
                    {item.badge > 9 ? "9+" : item.badge}
                  </motion.div>
                ) : null}
              </div>
              <span
                className="text-[10px] mt-0.5 font-medium"
                style={{
                  color: isActive ? "var(--neu-accent)" : "var(--neu-text-muted)",
                }}
              >
                {item.label}
              </span>
            </button>
          );
        })}
      </div>
    </div>
  );
}
