// ==================== CHAT / MESSAGES STORE ====================
"use client";

import { create } from "zustand";
import { persist, createJSONStorage } from "zustand/middleware";
import type { Chat, Message, Contact, Call, StatusItem } from "@/types";
import {
  MOCK_CHATS,
  MOCK_MESSAGES,
  MOCK_CONTACTS,
  MOCK_CALLS,
  MOCK_STATUSES,
} from "@/lib/zaxo/mockData";

interface AppState {
  contacts: Contact[];
  chats: Chat[];
  messages: { [chatId: string]: Message[] };
  calls: Call[];
  statuses: StatusItem[];
  blockedIds: string[];

  // Chat actions
  sendMessage: (chatId: string, text: string, type?: Message["type"], extra?: Partial<Message>) => void;
  deleteMessage: (chatId: string, messageId: string, forEveryone: boolean) => void;
  editMessage: (chatId: string, messageId: string, newText: string) => void;
  toggleStarMessage: (chatId: string, messageId: string) => void;
  toggleReaction: (chatId: string, messageId: string, emoji: string, userId: string) => void;
  markChatRead: (chatId: string) => void;
  setTyping: (chatId: string, userIds: string[]) => void;
  togglePinChat: (chatId: string) => void;
  toggleArchiveChat: (chatId: string) => void;
  toggleMuteChat: (chatId: string) => void;
  deleteChat: (chatId: string) => void;
  clearChatMessages: (chatId: string) => void;
  startChatWithContact: (contactId: string) => string; // returns chatId
  createGroup: (name: string, participantIds: string[], description?: string) => string;

  // Call actions
  addCall: (call: Call) => void;
  clearCallHistory: () => void;

  // Status actions
  addStatus: (status: StatusItem) => void;
  viewStatus: (statusId: string, userId: string) => void;
  deleteStatus: (statusId: string) => void;

  // Contact actions
  blockContact: (contactId: string) => void;
  unblockContact: (contactId: string) => void;
  inviteContact: (contactId: string) => void;
}

export const useAppStore = create<AppState>()(
  persist(
    (set, get) => ({
      contacts: MOCK_CONTACTS,
      chats: MOCK_CHATS,
      messages: MOCK_MESSAGES,
      calls: MOCK_CALLS,
      statuses: MOCK_STATUSES,
      blockedIds: [],

      sendMessage: (chatId, text, type = "text", extra) => {
        const newMsg: Message = {
          id: `m_${Date.now()}_${Math.random().toString(36).slice(2, 7)}`,
          chatId,
          senderId: "me",
          type,
          text: type === "text" ? text : extra?.text,
          timestamp: Date.now(),
          status: "sending",
          reactions: {},
          disappearing: "off",
          ...extra,
        };
        set((state) => ({
          messages: {
            ...state.messages,
            [chatId]: [...(state.messages[chatId] || []), newMsg],
          },
          chats: state.chats.map((c) =>
            c.id === chatId
              ? { ...c, lastMessage: newMsg, updatedAt: newMsg.timestamp }
              : c,
          ),
        }));
        // Simulate delivery → read
        setTimeout(() => {
          set((state) => ({
            messages: {
              ...state.messages,
              [chatId]: (state.messages[chatId] || []).map((m) =>
                m.id === newMsg.id ? { ...m, status: "sent" as const } : m,
              ),
            },
          }));
        }, 400);
        setTimeout(() => {
          set((state) => ({
            messages: {
              ...state.messages,
              [chatId]: (state.messages[chatId] || []).map((m) =>
                m.id === newMsg.id ? { ...m, status: "delivered" as const } : m,
              ),
            },
          }));
        }, 900);
        setTimeout(() => {
          set((state) => ({
            messages: {
              ...state.messages,
              [chatId]: (state.messages[chatId] || []).map((m) =>
                m.id === newMsg.id ? { ...m, status: "read" as const } : m,
              ),
            },
          }));
        }, 1800);
      },

      deleteMessage: (chatId, messageId, forEveryone) => {
        set((state) => ({
          messages: {
            ...state.messages,
            [chatId]: (state.messages[chatId] || []).map((m) =>
              m.id === messageId
                ? forEveryone
                  ? { ...m, deletedForEveryone: true, text: undefined, type: "system" as const }
                  : m
                : m,
            ).filter((m) => forEveryone || m.id !== messageId),
          },
        }));
      },

      editMessage: (chatId, messageId, newText) => {
        set((state) => ({
          messages: {
            ...state.messages,
            [chatId]: (state.messages[chatId] || []).map((m) =>
              m.id === messageId ? { ...m, text: newText, edited: true } : m,
            ),
          },
        }));
      },

      toggleStarMessage: (chatId, messageId) => {
        set((state) => ({
          messages: {
            ...state.messages,
            [chatId]: (state.messages[chatId] || []).map((m) =>
              m.id === messageId ? { ...m, starred: !m.starred } : m,
            ),
          },
        }));
      },

      toggleReaction: (chatId, messageId, emoji, userId) => {
        set((state) => ({
          messages: {
            ...state.messages,
            [chatId]: (state.messages[chatId] || []).map((m) => {
              if (m.id !== messageId) return m;
              const reactions = { ...m.reactions };
              if (reactions[userId] === emoji) {
                delete reactions[userId];
              } else {
                reactions[userId] = emoji;
              }
              return { ...m, reactions };
            }),
          },
        }));
      },

      markChatRead: (chatId) => {
        set((state) => ({
          chats: state.chats.map((c) =>
            c.id === chatId ? { ...c, unreadCount: 0 } : c,
          ),
        }));
      },

      setTyping: (chatId, userIds) => {
        set((state) => ({
          chats: state.chats.map((c) =>
            c.id === chatId ? { ...c, typingUserIds: userIds } : c,
          ),
        }));
      },

      togglePinChat: (chatId) => {
        set((state) => ({
          chats: state.chats.map((c) =>
            c.id === chatId ? { ...c, isPinned: !c.isPinned } : c,
          ),
        }));
      },

      toggleArchiveChat: (chatId) => {
        set((state) => ({
          chats: state.chats.map((c) =>
            c.id === chatId ? { ...c, isArchived: !c.isArchived } : c,
          ),
        }));
      },

      toggleMuteChat: (chatId) => {
        set((state) => ({
          chats: state.chats.map((c) =>
            c.id === chatId ? { ...c, isMuted: !c.isMuted } : c,
          ),
        }));
      },

      deleteChat: (chatId) => {
        set((state) => {
          const messages = { ...state.messages };
          delete messages[chatId];
          return {
            chats: state.chats.filter((c) => c.id !== chatId),
            messages,
          };
        });
      },

      clearChatMessages: (chatId) => {
        set((state) => ({
          messages: { ...state.messages, [chatId]: [] },
        }));
      },

      startChatWithContact: (contactId) => {
        const existing = get().chats.find(
          (c) => c.type === "individual" && c.participantIds[0] === contactId,
        );
        if (existing) return existing.id;
        const chatId = `c_${contactId}_${Date.now()}`;
        const newChat: Chat = {
          id: chatId,
          type: "individual",
          participantIds: [contactId],
          unreadCount: 0,
          isArchived: false,
          isPinned: false,
          isMuted: false,
          typingUserIds: [],
          disappearing: "off",
          createdAt: Date.now(),
          updatedAt: Date.now(),
        };
        set((state) => ({
          chats: [newChat, ...state.chats],
          messages: { ...state.messages, [chatId]: [] },
        }));
        return chatId;
      },

      createGroup: (name, participantIds, description) => {
        const chatId = `c_group_${Date.now()}`;
        const newChat: Chat = {
          id: chatId,
          type: "group",
          participantIds,
          name,
          avatarColor: "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
          avatarInitial: name.charAt(0).toUpperCase(),
          description: description || "",
          adminIds: ["me"],
          unreadCount: 0,
          isArchived: false,
          isPinned: false,
          isMuted: false,
          typingUserIds: [],
          disappearing: "off",
          createdAt: Date.now(),
          updatedAt: Date.now(),
        };
        set((state) => ({
          chats: [newChat, ...state.chats],
          messages: { ...state.messages, [chatId]: [] },
        }));
        return chatId;
      },

      addCall: (call) => {
        set((state) => ({ calls: [call, ...state.calls] }));
      },

      clearCallHistory: () => set({ calls: [] }),

      addStatus: (status) => {
        set((state) => ({ statuses: [status, ...state.statuses] }));
      },

      viewStatus: (statusId, userId) => {
        set((state) => ({
          statuses: state.statuses.map((s) =>
            s.id === statusId && !s.viewers.includes(userId)
              ? { ...s, viewers: [...s.viewers, userId] }
              : s,
          ),
        }));
      },

      deleteStatus: (statusId) => {
        set((state) => ({
          statuses: state.statuses.filter((s) => s.id !== statusId),
        }));
      },

      blockContact: (contactId) => {
        set((state) => ({
          blockedIds: [...state.blockedIds, contactId],
          contacts: state.contacts.map((c) =>
            c.id === contactId ? { ...c, blocked: true } : c,
          ),
        }));
      },

      unblockContact: (contactId) => {
        set((state) => ({
          blockedIds: state.blockedIds.filter((id) => id !== contactId),
          contacts: state.contacts.map((c) =>
            c.id === contactId ? { ...c, blocked: false } : c,
          ),
        }));
      },

      inviteContact: (contactId) => {
        // mock: would send SMS/email in production
        console.log(`[Zaxo] Invite sent to contact ${contactId}`);
      },
    }),
    {
      name: "zaxo-app",
      storage: createJSONStorage(() => localStorage),
    },
  ),
);
