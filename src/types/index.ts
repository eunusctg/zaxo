// ==================== ZAXO TYPE DEFINITIONS ====================

export type Theme = "light" | "dark";
export type AuthMethod = "google" | "email";
export type ChatType = "individual" | "group";
export type MessageStatus = "sending" | "sent" | "delivered" | "read";
export type MessageType =
  | "text"
  | "image"
  | "video"
  | "voice"
  | "document"
  | "location"
  | "contact"
  | "sticker"
  | "system";
export type CallType = "voice" | "video";
export type CallDirection = "incoming" | "outgoing" | "missed";
export type StatusPrivacy = "contacts" | "contacts_except" | "only_share_with";
export type DisappearingTimer = "off" | "24h" | "7d" | "90d";

export interface User {
  id: string;
  zaxoNumber: string; // XXX-XXX-XXX
  displayName: string;
  email: string;
  avatarColor: string;
  avatarInitial: string;
  about: string;
  phone?: string;
  isFirstLogin: boolean;
  createdAt: number;
  lastSeen: number;
  online: boolean;
}

export interface Contact {
  id: string;
  zaxoNumber: string;
  displayName: string;
  avatarColor: string;
  avatarInitial: string;
  about: string;
  online: boolean;
  lastSeen: number;
  isZaxoUser: boolean;
  blocked: boolean;
}

export interface Message {
  id: string;
  chatId: string;
  senderId: string;
  type: MessageType;
  text?: string;
  mediaUrl?: string;
  mediaName?: string;
  mediaSize?: number;
  duration?: number;
  location?: { lat: number; lng: number; label?: string };
  contactCard?: { name: string; zaxoNumber: string };
  timestamp: number;
  status: MessageStatus;
  replyTo?: string;
  starred?: boolean;
  deletedForEveryone?: boolean;
  edited?: boolean;
  reactions: { [userId: string]: string };
  disappearing: DisappearingTimer;
}

export interface Chat {
  id: string;
  type: ChatType;
  participantIds: string[];
  name?: string;
  avatarColor?: string;
  avatarInitial?: string;
  description?: string;
  adminIds?: string[];
  lastMessage?: Message;
  unreadCount: number;
  isArchived: boolean;
  isPinned: boolean;
  isMuted: boolean;
  typingUserIds: string[];
  wallpaper?: string;
  disappearing: DisappearingTimer;
  createdAt: number;
  updatedAt: number;
}

export interface Call {
  id: string;
  otherUserId: string;
  type: CallType;
  direction: CallDirection;
  timestamp: number;
  duration: number;
}

export interface StatusItem {
  id: string;
  userId: string;
  type: "image" | "video" | "text";
  mediaUrl?: string;
  text?: string;
  backgroundColor?: string;
  caption?: string;
  createdAt: number;
  expiresAt: number;
  viewers: string[];
  privacy: StatusPrivacy;
  audience?: string[];
}

export interface StatusGroup {
  userId: string;
  items: StatusItem[];
  allViewed: boolean;
}

export interface Settings {
  lastSeenVisibility: "everyone" | "contacts" | "nobody";
  profilePhotoVisibility: "everyone" | "contacts" | "nobody";
  aboutVisibility: "everyone" | "contacts" | "nobody";
  statusVisibility: "everyone" | "contacts" | "nobody";
  readReceipts: boolean;
  whoCanAddToGroups: "everyone" | "contacts";
  silenceUnknownCallers: boolean;
  fingerprintLock: boolean;
  fingerprintLockTimeout: "immediate" | "1min" | "5min" | "30min";
  hideNotificationContent: boolean;
  blockScreenshots: boolean;

  messageNotifications: boolean;
  messageTone: string;
  messageVibrate: boolean;
  groupNotifications: boolean;
  callNotifications: boolean;
  callRingtone: string;
  quietHoursEnabled: boolean;
  quietHoursStart: string;
  quietHoursEnd: string;
  showPreview: boolean;
  reactionNotifications: boolean;
  statusNotifications: boolean;

  chatWallpaper: string;
  messageTextSize: "small" | "medium" | "large";
  autoDownloadMobile: boolean;
  autoDownloadWifi: boolean;
  autoDownloadRoaming: boolean;
  mediaQuality: "standard" | "high";
  backupFrequency: "never" | "daily" | "weekly" | "monthly";
  backupIncludeVideos: boolean;
  defaultDisappearingTimer: DisappearingTimer;
  keepMessages: "forever" | "30d" | "90d";

  neumorphismIntensity: "subtle" | "normal" | "strong";
  cornerRadius: number;
  accentColor: string;
  animationSpeed: "normal" | "reduced";
  compactMode: boolean;

  fontScaling: number;
  highContrast: boolean;
  reduceMotion: boolean;

  twoStepVerificationEnabled: boolean;
  bioMetricLock: boolean;
}
