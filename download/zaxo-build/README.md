# Zaxo — Production Build

Standalone production build of Zaxo, the neumorphic social messenger.
Runs on any machine with Node.js 18+ (or Bun). No build step required.

## Run

```bash
cd zaxo-build
PORT=3000 node server.js
# or with Bun (faster cold start):
PORT=3000 bun server.js
```

Then open http://localhost:3000.

## Features in this build

### Calls (real WebRTC, peer-to-peer)
- STUN: Google public STUN (4 endpoints)
- TURN: OpenRelay by Metered (UDP + TCP relay) for cross-network / symmetric-NAT
- ICE restart on connection failure (Wi-Fi → cellular handoff recovery)
- Connection strategy surfaced to UI (host / srflx / relay)

### Cross-tab call history sync
- localStorage + BroadcastChannel dual-channel pub/sub
- Calls placed in tab A appear in tab B's history within ~50ms
- Survives tab close — history persists across sessions

### Real-time messaging (cross-tab)
- BroadcastChannel signaling: messages, typing, presence, read receipts, reactions
- Optimistic UI: instant send → 50ms delivery → 300ms read receipt

### QR codes
- Real QR generation via `qrcode` library (`zaxo://contact?number=…` URI)
- Real camera-based scanner via `jsqr` (auto-adds contact + opens chat)

### Notifications (browser Notifications API)
- Categories: message, group_message, call_incoming, call_group, call_missed, status, reaction
- Quiet hours, per-category toggles, hide-content + show-preview enforcement
- WebAudio ringtone + message tone (no asset files needed)
- In-app notification center (bell icon + dropdown panel)

### Security
- Real WebAuthn biometric enrollment + verification
- SHA-256 hashed 6-digit passcode (Web Crypto API, never plaintext)
- Auto-lock on tab visibility change (immediate / 1 / 5 / 30 min)
- 3-attempt lockout with biometric fallback

### Chat features
- Reply, forward, archive, delete-for-me, delete-for-everyone
- Info, copy, edit, pin, animated reactions
- Disappearing messages, starred messages
- Group chats + group calls (multi-participant)
- Typing indicators (single + group), last seen, online presence

### Status (stories)
- Image / video / text statuses with 24h expiry
- Viewers list, replies, progress bars, multi-item viewers

### UI
- Responsive neumorphic (soft-UI) across phone / tablet / foldable
- Light + dark themes (auto-detect + manual toggle)
- Stunning app icon (1024×1024 purple Z gradient)

## Architecture

- Frontend: Next.js 16 + React 19 + TypeScript + Tailwind v4 + Zustand + framer-motion
- Realtime: BroadcastChannel (cross-tab, same-origin)
- Calls: WebRTC (browser-native P2P) + STUN/TURN relay
- Persistence: localStorage (Zustand persist) + cross-tab sync
- Notifications: Browser Notifications API + WebAudio tones

## Deploy to a VPS

```bash
scp -r zaxo-build user@your-vps:/opt/zaxo
ssh user@your-vps 'cd /opt/zaxo && PORT=80 node server.js'
```

Or run behind Caddy / Nginx reverse proxy to localhost:3000.
