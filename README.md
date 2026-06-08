# ZAXO - WhatsApp Clone 🚀

**"Message & Call Freely. 100% Free Forever."**

A production-ready WhatsApp clone built with Flutter, featuring glassmorphism/neumorphism dark theme design, Firebase real-time backend, Cloudflare R2 storage, FCM push notifications, and AI-powered chat.

## 📱 Screens

| Screen | Description |
|--------|-------------|
| Splash | Animated logo with gradient mesh + auth check |
| Onboarding | 3-page intro with floating elements |
| Sign In | Email/Password, Google, Phone OTP auth |
| Sign Up | Full registration with form validation |
| Home | Bottom navigation (Chats, Status, Calls, Settings) |
| Chat List | Real-time chat list from Firebase RTDB |
| Chat Screen | Real-time messages, typing indicator, AI chat, encryption banner |
| Audio Call | Pulsing avatar, call controls, duration timer |
| Video Call | Full-screen video with controls overlay |
| Status | Status list, viewer with auto-advance, create text/image status |
| Call History | Real-time call history with filters |
| Settings | User info, account, notifications, privacy, sign out |
| Profile | Edit name/about/avatar with R2 upload |
| Contacts | Search users from Firebase, start new chats |

## 🏗 Architecture

```
Clean Architecture + BLoC Pattern
├── core/          → Theme, Constants, Extensions, Utils
├── data/          → Models, DataSources, Services, Repositories
├── domain/        → Entities, Repository interfaces
├── presentation/  → BLoCs, Screens, Widgets
├── routes/        → GoRouter configuration
└── di/            → GetIt dependency injection
```

## 🛠 Tech Stack

- **Flutter 3.44+** (Dart 3.12+)
- **State Management**: flutter_bloc + Equatable
- **Navigation**: GoRouter with slide-fade transitions
- **Animations**: flutter_animate
- **Backend**: Firebase (Auth, Realtime Database, Cloud Messaging, Crashlytics, Analytics)
- **Storage**: Cloudflare R2 (S3-compatible) for media uploads
- **Local Storage**: Hive + SharedPreferences
- **AI Chat**: z-ai-web-dev-sdk via Next.js backend
- **Encryption UI**: PointyCastle + Cryptography (Signal Protocol inspired)
- **DI**: GetIt
- **Push Notifications**: FCM with local notification channels

## 🚀 Getting Started

### Prerequisites

1. **Flutter SDK** 3.44+ ([Install](https://flutter.dev/docs/get-started/install))
2. **Android Studio** with Android SDK 34+
3. **JDK 17+**

### Quick Start

```bash
# 1. Clone the project
git clone https://github.com/eunusctg/zaxo.git
cd zaxo

# 2. Install dependencies
flutter pub get

# 3. Build debug APK
flutter build apk --debug

# 4. Or run directly on device/emulator
flutter run
```

### Firebase Setup

The project already includes `google-services.json` configured for the Zaxo Firebase project. To use your own Firebase project:

1. Create a Firebase project at [console.firebase.google.com](https://console.firebase.google.com)
2. Add an Android app with package name: `com.zaxo.app`
3. Download `google-services.json` → replace `android/app/google-services.json`
4. Update `lib/firebase_options.dart` with your Firebase config
5. Enable these Firebase services:
   - **Authentication**: Email/Password, Google, Phone
   - **Realtime Database**: Create database with rules
   - **Cloud Messaging**: Enable FCM
   - **Analytics**: Enable Google Analytics
   - **Crashlytics**: Enable Crashlytics

### Firebase Realtime Database Rules

```json
{
  "rules": {
    "users": {
      "$uid": {
        ".read": true,
        ".write": "auth != null && auth.uid == $uid"
      }
    },
    "chats": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "messages": {
      "$chatId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "statuses": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "calls": {
      ".read": "auth != null",
      ".write": "auth != null"
    },
    "typing": {
      "$chatId": {
        ".read": "auth != null",
        ".write": "auth != null"
      }
    },
    "notifications": {
      ".read": "auth != null",
      ".write": "auth != null"
    }
  }
}
```

### Cloudflare R2 Storage (Optional)

To configure your own R2 storage for media uploads, update the constants in `lib/data/services/r2_storage_service.dart`:

- `_accountId`: Your Cloudflare account ID
- `_bucket`: R2 bucket name
- `_accessKeyId`: R2 access key ID
- `_secretAccessKey`: R2 secret access key
- `_customDomain`: Your R2 custom domain for serving files

### AI Chat (Optional)

The AI chat feature uses the Next.js backend's `/api/zaxo/ai-chat` endpoint. To configure:

1. Set up the Next.js backend (from the web app project)
2. Update `lib/data/services/ai_chat_service.dart`:
   - `_baseUrl`: Change from `http://10.0.2.2:3000` to your server URL
   - For Android emulator: `http://10.0.2.2:3000` (maps to host localhost)
   - For physical device: Use your server's public URL

### Build Release APK

```bash
# Generate signing key (first time only)
keytool -genkey -v -keystore ~/zaxo-key.jks -keyalg RSA -keysize 2048 -validity 10000 -alias zaxo

# Create android/key.properties
storePassword=YOUR_PASSWORD
keyPassword=YOUR_PASSWORD
keyAlias=zaxo
storeFile=/path/to/zaxo-key.jks

# Build release APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

## 🎨 Design System

| Token | Color | Usage |
|-------|-------|-------|
| Primary | #7C3AED | Deep Purple - CTAs, active states |
| Secondary | #06D6A0 | Mint Green - read receipts, online |
| Tertiary | #F72585 | Hot Pink - AI badge, accents |
| Background | #0F0F1A | Deep Navy - main background |
| Surface | #1A1A2E | Card Background - cards, sheets |
| Surface Variant | #252540 | Input Background - text fields |
| Error | #EF4444 | Red - errors, failed messages |
| Font Heading | Outfit | Bold headings |
| Font Body | Inter | Body text, messages |

## 📂 Project Structure

```
zaxo_app/
├── android/                    → Android native config
│   ├── app/
│   │   ├── google-services.json   → Firebase config (included)
│   │   ├── build.gradle.kts       → App-level Gradle config
│   │   └── src/main/
│   │       ├── AndroidManifest.xml → Permissions, FCM service
│   │       └── kotlin/com/zaxo/app/MainActivity.kt
│   ├── build.gradle.kts           → Root Gradle config
│   └── settings.gradle.kts        → Plugin versions
├── lib/
│   ├── main.dart              → App entry (Firebase + Hive + DI init)
│   ├── app.dart               → MaterialApp with BLoC providers
│   ├── firebase_options.dart  → Firebase platform config
│   ├── core/
│   │   ├── constants/         → Colors, Dimensions, Animations, Typography
│   │   ├── theme/             → AppTheme (light + dark)
│   │   ├── extensions/        → BuildContext extensions
│   │   └── utils/             → DateFormatter
│   ├── data/
│   │   ├── models/            → Chat, Message, User, Call, Status models
│   │   ├── datasources/       → Hive (local), Firebase, API (remote)
│   │   ├── services/          → Firebase Auth, DB, FCM, R2, AI Chat
│   │   └── repositories/      → Repository implementations
│   ├── domain/
│   │   ├── entities/          → Chat, Message, User, Call, Status entities
│   │   └── repositories/      → Repository interfaces
│   ├── presentation/
│   │   ├── blocs/             → Auth, Chat, Message, Call, Status BLoCs
│   │   ├── screens/           → All app screens
│   │   └── widgets/           → Reusable UI components
│   ├── routes/                → GoRouter with slide-fade transitions
│   └── di/                    → GetIt service locator
└── pubspec.yaml               → Dependencies
```

## 🔒 Security Features

- **End-to-End Encryption UI**: Lock icon + "Messages are end-to-end encrypted" banner
- **Signal Protocol Inspired**: PointyCastle + Cryptography libraries included
- **Firebase Security Rules**: Role-based access control in RTDB
- **AWS SigV4**: R2 storage uploads signed with AWS Signature Version 4
- **Android Keystore**: Secure key storage on device

## 🔔 Push Notifications

- FCM token management with auto-refresh
- Foreground message handling with local notifications
- Background message handler for terminated state
- Multiple notification channels: Messages, Calls, Statuses, Groups
- Notification tap handling with data payload parsing

## 🤖 AI Chat Integration

- Dedicated "Zaxo AI" chat with AI badge
- Conversation history sent to backend for context
- Real-time streaming of AI responses
- Typing indicator shown while AI generates response

## 📄 License

Proprietary - All rights reserved.
