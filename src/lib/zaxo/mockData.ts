// ==================== ZAXO MOCK DATA & HELPERS ====================
import type { Contact, Message, Chat, Call, StatusItem, Settings, User } from "@/types";

const now = Date.now();
const minutes = (n: number) => n * 60 * 1000;
const hours = (n: number) => n * 60 * 60 * 1000;
const days = (n: number) => n * 24 * 60 * 60 * 1000;

export const AVATAR_GRADIENTS = [
  "linear-gradient(135deg, #667eea 0%, #764ba2 100%)",
  "linear-gradient(135deg, #f093fb 0%, #f5576c 100%)",
  "linear-gradient(135deg, #4facfe 0%, #00f2fe 100%)",
  "linear-gradient(135deg, #43e97b 0%, #38f9d7 100%)",
  "linear-gradient(135deg, #fa709a 0%, #fee140 100%)",
  "linear-gradient(135deg, #30cfd0 0%, #330867 100%)",
  "linear-gradient(135deg, #a8edea 0%, #fed6e3 100%)",
  "linear-gradient(135deg, #ff9a9e 0%, #fecfef 100%)",
  "linear-gradient(135deg, #ffecd2 0%, #fcb69f 100%)",
  "linear-gradient(135deg, #84fab0 0%, #8fd3f4 100%)",
];

export const STATUS_COLORS = [
  "#6C5CE7", "#00B894", "#FF6B6B", "#FECA57",
  "#74B9FF", "#E17055", "#A29BFE", "#55EFC4",
];

export const DEFAULT_SETTINGS: Settings = {
  lastSeenVisibility: "contacts",
  profilePhotoVisibility: "everyone",
  aboutVisibility: "contacts",
  statusVisibility: "contacts",
  readReceipts: true,
  whoCanAddToGroups: "contacts",
  silenceUnknownCallers: false,
  fingerprintLock: false,
  fingerprintLockTimeout: "1min",
  hideNotificationContent: false,
  blockScreenshots: false,

  messageNotifications: true,
  messageTone: "default",
  messageVibrate: true,
  groupNotifications: true,
  callNotifications: true,
  callRingtone: "default",
  quietHoursEnabled: false,
  quietHoursStart: "22:00",
  quietHoursEnd: "07:00",
  showPreview: true,
  reactionNotifications: true,
  statusNotifications: true,

  chatWallpaper: "default",
  messageTextSize: "medium",
  autoDownloadMobile: false,
  autoDownloadWifi: true,
  autoDownloadRoaming: false,
  mediaQuality: "high",
  backupFrequency: "daily",
  backupIncludeVideos: true,
  defaultDisappearingTimer: "off",
  keepMessages: "forever",

  neumorphismIntensity: "normal",
  cornerRadius: 16,
  accentColor: "#6C5CE7",
  animationSpeed: "normal",
  compactMode: false,

  fontScaling: 1,
  highContrast: false,
  reduceMotion: false,

  twoStepVerificationEnabled: false,
  bioMetricLock: false,
};

// ==================== CONTACTS ====================
export const MOCK_CONTACTS: Contact[] = [
  {
    id: "u_sarah",
    zaxoNumber: "482-719-305",
    displayName: "Sarah Chen",
    avatarColor: AVATAR_GRADIENTS[0],
    avatarInitial: "S",
    about: "Designing the future ✨",
    online: true,
    lastSeen: now,
    isZaxoUser: true,
    blocked: false,
  },
  {
    id: "u_marcus",
    zaxoNumber: "917-304-628",
    displayName: "Marcus Reid",
    avatarColor: AVATAR_GRADIENTS[1],
    avatarInitial: "M",
    about: "Coffee. Code. Repeat.",
    online: false,
    lastSeen: now - minutes(23),
    isZaxoUser: true,
    blocked: false,
  },
  {
    id: "u_aisha",
    zaxoNumber: "256-841-790",
    displayName: "Aisha Patel",
    avatarColor: AVATAR_GRADIENTS[2],
    avatarInitial: "A",
    about: "Travel addict 🌍",
    online: true,
    lastSeen: now,
    isZaxoUser: true,
    blocked: false,
  },
  {
    id: "u_leo",
    zaxoNumber: "633-582-149",
    displayName: "Leo Martinez",
    avatarColor: AVATAR_GRADIENTS[3],
    avatarInitial: "L",
    about: "Music is life 🎸",
    online: false,
    lastSeen: now - hours(2),
    isZaxoUser: true,
    blocked: false,
  },
  {
    id: "u_emma",
    zaxoNumber: "794-216-583",
    displayName: "Emma Watson",
    avatarColor: AVATAR_GRADIENTS[4],
    avatarInitial: "E",
    about: "Bookworm 📚",
    online: false,
    lastSeen: now - hours(5),
    isZaxoUser: true,
    blocked: false,
  },
  {
    id: "u_kenji",
    zaxoNumber: "318-947-206",
    displayName: "Kenji Tanaka",
    avatarColor: AVATAR_GRADIENTS[5],
    avatarInitial: "K",
    about: "Photographer 📷",
    online: true,
    lastSeen: now,
    isZaxoUser: true,
    blocked: false,
  },
  {
    id: "u_nora",
    zaxoNumber: "572-638-419",
    displayName: "Nora Lindqvist",
    avatarColor: AVATAR_GRADIENTS[6],
    avatarInitial: "N",
    about: "Skiing every weekend ⛷️",
    online: false,
    lastSeen: now - days(1),
    isZaxoUser: true,
    blocked: false,
  },
  {
    id: "u_diego",
    zaxoNumber: "845-392-716",
    displayName: "Diego Santos",
    avatarColor: AVATAR_GRADIENTS[7],
    avatarInitial: "D",
    about: "Building cool things",
    online: false,
    lastSeen: now - hours(8),
    isZaxoUser: true,
    blocked: false,
  },
  {
    id: "u_priya",
    zaxoNumber: "129-784-503",
    displayName: "Priya Sharma",
    avatarColor: AVATAR_GRADIENTS[8],
    avatarInitial: "P",
    about: "Foodie. Coder. Dreamer.",
    online: true,
    lastSeen: now,
    isZaxoUser: true,
    blocked: false,
  },
  {
    id: "u_tom",
    zaxoNumber: "463-158-927",
    displayName: "Tom Walker",
    avatarColor: AVATAR_GRADIENTS[9],
    avatarInitial: "T",
    about: "Running marathons 🏃",
    online: false,
    lastSeen: now - hours(12),
    isZaxoUser: true,
    blocked: false,
  },
  // Non-Zaxo contacts (for invite flow)
  {
    id: "u_alex",
    zaxoNumber: "",
    displayName: "Alex Johnson",
    avatarColor: AVATAR_GRADIENTS[2],
    avatarInitial: "A",
    about: "",
    online: false,
    lastSeen: 0,
    isZaxoUser: false,
    blocked: false,
  },
  {
    id: "u_lisa",
    zaxoNumber: "",
    displayName: "Lisa Brown",
    avatarColor: AVATAR_GRADIENTS[7],
    avatarInitial: "L",
    about: "",
    online: false,
    lastSeen: 0,
    isZaxoUser: false,
    blocked: false,
  },
];

// ==================== MESSAGES ====================
function msg(
  chatId: string,
  senderId: string,
  text: string,
  minutesAgo: number,
  status: Message["status"] = "read",
  extra: Partial<Message> = {},
): Message {
  return {
    id: `m_${chatId}_${Math.random().toString(36).slice(2, 9)}`,
    chatId,
    senderId,
    type: "text",
    text,
    timestamp: now - minutes(minutesAgo),
    status,
    reactions: {},
    disappearing: "off",
    ...extra,
  };
}

// ==================== CHATS ====================
export const MOCK_CHATS: Chat[] = [
  {
    id: "c_sarah",
    type: "individual",
    participantIds: ["u_sarah"],
    lastMessage: msg("c_sarah", "u_sarah", "Hey! Are we still on for dinner tonight? 🍝", 5, "delivered"),
    unreadCount: 2,
    isArchived: false,
    isPinned: true,
    isMuted: false,
    typingUserIds: [],
    disappearing: "off",
    createdAt: now - days(30),
    updatedAt: now - minutes(5),
  },
  {
    id: "c_marcus",
    type: "individual",
    participantIds: ["u_marcus"],
    lastMessage: msg("c_marcus", "me", "Got it, see you at 3pm 👍", 23, "read"),
    unreadCount: 0,
    isArchived: false,
    isPinned: false,
    isMuted: false,
    typingUserIds: [],
    disappearing: "off",
    createdAt: now - days(14),
    updatedAt: now - minutes(23),
  },
  {
    id: "c_aisha",
    type: "individual",
    participantIds: ["u_aisha"],
    lastMessage: msg("c_aisha", "u_aisha", "Just landed in Tokyo! The flight was amazing ✈️", 47, "delivered"),
    unreadCount: 1,
    isArchived: false,
    isPinned: false,
    isMuted: false,
    typingUserIds: ["u_aisha"],
    disappearing: "off",
    createdAt: now - days(60),
    updatedAt: now - minutes(47),
  },
  {
    id: "c_design_team",
    type: "group",
    participantIds: ["u_sarah", "u_leo", "u_priya", "u_diego"],
    name: "Design Team",
    avatarColor: AVATAR_GRADIENTS[4],
    avatarInitial: "DT",
    description: "Where pixels come to life",
    adminIds: ["u_sarah"],
    lastMessage: msg("c_design_team", "u_priya", "Pushed the new mockups to Figma — feedback welcome!", 92, "read"),
    unreadCount: 0,
    isArchived: false,
    isPinned: true,
    isMuted: true,
    typingUserIds: [],
    disappearing: "off",
    createdAt: now - days(90),
    updatedAt: now - minutes(92),
  },
  {
    id: "c_leo",
    type: "individual",
    participantIds: ["u_leo"],
    lastMessage: msg("c_leo", "u_leo", "🎤 Voice message (0:34)", 180, "read", {
      type: "voice",
      text: undefined,
      duration: 34,
    }),
    unreadCount: 0,
    isArchived: false,
    isPinned: false,
    isMuted: false,
    typingUserIds: [],
    disappearing: "off",
    createdAt: now - days(45),
    updatedAt: now - minutes(180),
  },
  {
    id: "c_emma",
    type: "individual",
    participantIds: ["u_emma"],
    lastMessage: msg("c_emma", "u_emma", "You have to read this book! 📖", 320, "read"),
    unreadCount: 0,
    isArchived: false,
    isPinned: false,
    isMuted: false,
    typingUserIds: [],
    disappearing: "7d",
    createdAt: now - days(120),
    updatedAt: now - minutes(320),
  },
  {
    id: "c_family",
    type: "group",
    participantIds: ["u_emma", "u_tom", "u_nora"],
    name: "Family 💛",
    avatarColor: AVATAR_GRADIENTS[3],
    avatarInitial: "F",
    description: "Home is where the heart is",
    adminIds: ["me"],
    lastMessage: msg("c_family", "u_tom", "Mom's birthday cake is sorted! 🎂", 480, "read"),
    unreadCount: 0,
    isArchived: false,
    isPinned: false,
    isMuted: false,
    typingUserIds: [],
    disappearing: "off",
    createdAt: now - days(365),
    updatedAt: now - minutes(480),
  },
  {
    id: "c_kenji",
    type: "individual",
    participantIds: ["u_kenji"],
    lastMessage: msg("c_kenji", "me", "Those sunset photos are stunning 🔥", 1440, "read"),
    unreadCount: 0,
    isArchived: false,
    isPinned: false,
    isMuted: false,
    typingUserIds: [],
    disappearing: "off",
    createdAt: now - days(200),
    updatedAt: now - days(1),
  },
  {
    id: "c_nora",
    type: "individual",
    participantIds: ["u_nora"],
    lastMessage: msg("c_nora", "u_nora", "Missed call", 2880, "read", {
      type: "system",
      text: "Missed voice call",
    }),
    unreadCount: 0,
    isArchived: true,
    isPinned: false,
    isMuted: false,
    typingUserIds: [],
    disappearing: "off",
    createdAt: now - days(80),
    updatedAt: now - days(2),
  },
  {
    id: "c_weekend",
    type: "group",
    participantIds: ["u_marcus", "u_diego", "u_aisha"],
    name: "Weekend Hikers 🥾",
    avatarColor: AVATAR_GRADIENTS[5],
    avatarInitial: "WH",
    description: "Sunday hikes, rain or shine",
    adminIds: ["u_marcus", "me"],
    lastMessage: msg("c_weekend", "u_diego", "Trail map: https://maps.example.com/trail", 4320, "read"),
    unreadCount: 0,
    isArchived: false,
    isPinned: false,
    isMuted: true,
    typingUserIds: [],
    disappearing: "off",
    createdAt: now - days(60),
    updatedAt: now - days(3),
  },
];

// ==================== MESSAGE HISTORY ====================
export const MOCK_MESSAGES: { [chatId: string]: Message[] } = {
  c_sarah: [
    msg("c_sarah", "u_sarah", "Hey! How's your day going?", 240, "read"),
    msg("c_sarah", "me", "Pretty good! Just wrapped up a big project 🎉", 235, "read"),
    msg("c_sarah", "u_sarah", "Congrats! That deserves a celebration", 230, "read"),
    msg("c_sarah", "me", "Haha right? Maybe dinner tonight?", 225, "read"),
    msg("c_sarah", "u_sarah", "Yes! That new Italian place on 5th?", 8, "delivered"),
    msg("c_sarah", "u_sarah", "Hey! Are we still on for dinner tonight? 🍝", 5, "delivered"),
  ],
  c_marcus: [
    msg("c_marcus", "u_marcus", "Did you get the meeting invite?", 60, "read"),
    msg("c_marcus", "me", "Yeah, just accepted it", 55, "read"),
    msg("c_marcus", "u_marcus", "Cool. I'll swing by your desk around 2:45?", 30, "read"),
    msg("c_marcus", "me", "Got it, see you at 3pm 👍", 23, "read"),
  ],
  c_aisha: [
    msg("c_aisha", "u_aisha", "Boarding now! ✈️", 90, "read"),
    msg("c_aisha", "me", "Safe flight! Text me when you land", 88, "read"),
    msg("c_aisha", "u_aisha", "Just landed in Tokyo! The flight was amazing ✈️", 47, "delivered"),
  ],
  c_design_team: [
    msg("c_design_team", "u_sarah", "Morning team! Sprint planning at 10am", 240, "read"),
    msg("c_design_team", "u_leo", "I'll be 5 min late, sorry", 235, "read"),
    msg("c_design_team", "u_priya", "Pushed the new mockups to Figma — feedback welcome!", 92, "read", {
      reactions: { me: "🔥", u_diego: "👍", u_leo: "❤️" },
    }),
  ],
  c_leo: [
    msg("c_leo", "u_leo", "🎤 Voice message (0:34)", 180, "read", {
      type: "voice",
      text: undefined,
      duration: 34,
    }),
    msg("c_leo", "me", "Haha that riff was sick!", 170, "read"),
  ],
  c_emma: [
    msg("c_emma", "u_emma", "You have to read this book! 📖", 320, "read"),
    msg("c_emma", "u_emma", "It's called 'The Midnight Library'", 318, "read"),
    msg("c_emma", "me", "Adding it to my list right now", 315, "read"),
  ],
  c_family: [
    msg("c_family", "u_emma", "Who's hosting Sunday dinner?", 500, "read"),
    msg("c_family", "me", "I can! I'll make the lasagna", 490, "read"),
    msg("c_family", "u_tom", "Mom's birthday cake is sorted! 🎂", 480, "read", {
      reactions: { me: "❤️", u_emma: "❤️", u_nora: "🎉" },
    }),
  ],
  c_kenji: [
    msg("c_kenji", "u_kenji", "Just got back from Hokkaido 📷", 1450, "read"),
    msg("c_kenji", "u_kenji", "📸 Photo", 1445, "read", {
      type: "image",
      text: undefined,
      mediaName: "sunset_hokkaido.jpg",
    }),
    msg("c_kenji", "me", "Those sunset photos are stunning 🔥", 1440, "read"),
  ],
  c_nora: [
    msg("c_nora", "u_nora", "Missed call", 2880, "read", {
      type: "system",
      text: "Missed voice call",
    }),
  ],
  c_weekend: [
    msg("c_weekend", "u_marcus", "Who's in for Sunday's hike?", 4350, "read"),
    msg("c_weekend", "u_diego", "Me! Mount Falcon trail?", 4340, "read"),
    msg("c_weekend", "u_aisha", "I'm in", 4330, "read"),
    msg("c_weekend", "u_diego", "Trail map: https://maps.example.com/trail", 4320, "read"),
  ],
};

// ==================== CALLS ====================
export const MOCK_CALLS: Call[] = [
  {
    id: "call_1",
    otherUserId: "u_sarah",
    type: "video",
    direction: "outgoing",
    timestamp: now - minutes(35),
    duration: 1245, // 20:45
  },
  {
    id: "call_2",
    otherUserId: "u_nora",
    type: "voice",
    direction: "missed",
    timestamp: now - days(2),
    duration: 0,
  },
  {
    id: "call_3",
    otherUserId: "u_marcus",
    type: "voice",
    direction: "incoming",
    timestamp: now - hours(5),
    duration: 184,
  },
  {
    id: "call_4",
    otherUserId: "u_aisha",
    type: "video",
    direction: "outgoing",
    timestamp: now - hours(18),
    duration: 542,
  },
  {
    id: "call_5",
    otherUserId: "u_leo",
    type: "voice",
    direction: "missed",
    timestamp: now - days(1),
    duration: 0,
  },
  {
    id: "call_6",
    otherUserId: "u_priya",
    type: "video",
    direction: "incoming",
    timestamp: now - days(3),
    duration: 723,
  },
  {
    id: "call_7",
    otherUserId: "u_kenji",
    type: "voice",
    direction: "outgoing",
    timestamp: now - days(5),
    duration: 95,
  },
];

// ==================== STATUS / STORIES ====================
export const MOCK_STATUSES: StatusItem[] = [
  {
    id: "s_sarah_1",
    userId: "u_sarah",
    type: "image",
    mediaUrl: "",
    caption: "Studio day 🎨",
    createdAt: now - hours(2),
    expiresAt: now - hours(2) + days(1),
    viewers: [],
    privacy: "contacts",
  },
  {
    id: "s_sarah_2",
    userId: "u_sarah",
    type: "text",
    text: "New project dropping soon 👀",
    backgroundColor: STATUS_COLORS[0],
    createdAt: now - hours(1),
    expiresAt: now - hours(1) + days(1),
    viewers: [],
    privacy: "contacts",
  },
  {
    id: "s_marcus_1",
    userId: "u_marcus",
    type: "image",
    mediaUrl: "",
    caption: "Morning brew ☕",
    createdAt: now - hours(4),
    expiresAt: now - hours(4) + days(1),
    viewers: ["me"],
    privacy: "contacts",
  },
  {
    id: "s_aisha_1",
    userId: "u_aisha",
    type: "text",
    text: "Tokyo is unreal 🗼",
    backgroundColor: STATUS_COLORS[1],
    createdAt: now - hours(3),
    expiresAt: now - hours(3) + days(1),
    viewers: [],
    privacy: "contacts",
  },
  {
    id: "s_leo_1",
    userId: "u_leo",
    type: "image",
    mediaUrl: "",
    caption: "New track dropping 🎸",
    createdAt: now - hours(6),
    expiresAt: now - hours(6) + days(1),
    viewers: ["me"],
    privacy: "contacts",
  },
  {
    id: "s_priya_1",
    userId: "u_priya",
    type: "text",
    text: "Shipping day energy 🚀",
    backgroundColor: STATUS_COLORS[3],
    createdAt: now - hours(8),
    expiresAt: now - hours(8) + days(1),
    viewers: [],
    privacy: "contacts",
  },
  {
    id: "s_kenji_1",
    userId: "u_kenji",
    type: "image",
    mediaUrl: "",
    caption: "Hokkaido sunsets hit different 🌅",
    createdAt: now - hours(12),
    expiresAt: now - hours(12) + days(1),
    viewers: ["me"],
    privacy: "contacts",
  },
];

// ==================== HELPERS ====================
export function getContactById(id: string, contacts: Contact[]): Contact | undefined {
  if (id === "me") return undefined;
  return contacts.find((c) => c.id === id);
}

export function relativeTime(timestamp: number): string {
  const diff = Date.now() - timestamp;
  if (diff < minutes(1)) return "just now";
  if (diff < hours(1)) return `${Math.floor(diff / minutes(1))} min ago`;
  if (diff < days(1)) return `${Math.floor(diff / hours(1))} hr ago`;
  if (diff < days(7)) return `${Math.floor(diff / days(1))} d ago`;
  const d = new Date(timestamp);
  return d.toLocaleDateString();
}

export function formatTime(timestamp: number): string {
  const d = new Date(timestamp);
  let h = d.getHours();
  const m = d.getMinutes();
  const ampm = h >= 12 ? "PM" : "AM";
  h = h % 12 || 12;
  return `${h}:${m.toString().padStart(2, "0")} ${ampm}`;
}

export function formatDuration(seconds: number): string {
  if (seconds === 0) return "Missed";
  const m = Math.floor(seconds / 60);
  const s = seconds % 60;
  if (m >= 60) {
    const h = Math.floor(m / 60);
    return `${h}h ${m % 60}m`;
  }
  return `${m}m ${s.toString().padStart(2, "0")}s`;
}

export function formatDateSeparator(timestamp: number): string {
  const d = new Date(timestamp);
  const today = new Date();
  const yesterday = new Date();
  yesterday.setDate(today.getDate() - 1);
  if (d.toDateString() === today.toDateString()) return "Today";
  if (d.toDateString() === yesterday.toDateString()) return "Yesterday";
  return d.toLocaleDateString(undefined, { month: "long", day: "numeric", year: "numeric" });
}

export function initialFromName(name: string): string {
  return name.trim().charAt(0).toUpperCase();
}
