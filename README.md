# Zaxo - Flutter Android App 🚀

**"Message & Call Freely. 100% Free Forever."**

A stunning WhatsApp clone built with Flutter 3.22+, featuring glassmorphism design, advanced animations, end-to-end encryption, and AI-powered chat.

## 📱 Screens

| Screen | Description |
|--------|-------------|
| Splash | Animated logo with particle effects, gradient mesh |
| Onboarding | 3-page intro with floating elements, 3D effects |
| Sign In/Up | Glassmorphism forms with animated gradients |
| Home | Bottom navigation with custom morphing indicator |
| Chat List | SliverAppBar, search, swipe actions, multi-select |
| Chat Screen | Message bubbles, typing indicator, emoji, voice notes |
| Audio Call | Pulsing avatar, waveform, auto-hiding controls |
| Video Call | PiP self-view, draggable, effects panel |
| Status | Ring indicator, viewer with auto-advance timer |
| Call History | Filter tabs, swipe to delete |
| Settings | Glassmorphism groups, neumorphic toggles |
| Profile | 3D tilt avatar, animated stats, QR code |
| Contacts | Search, group creation, invite |

## 🏗 Architecture

```
Clean Architecture + BLoC Pattern
├── core/          → Theme, Constants, Extensions, Utils
├── data/          → Models, DataSources, Repositories
├── domain/        → Entities, Repository interfaces, UseCases
├── presentation/  → BLoCs, Screens, Widgets
├── routes/        → GoRouter configuration
└── di/            → GetIt dependency injection
```

## 🛠 Tech Stack

- **Flutter 3.22+** (Dart 3.5+)
- **State Management**: flutter_bloc + Equatable
- **Navigation**: GoRouter
- **Animations**: flutter_animate, Lottie, Rive
- **Backend**: Firebase (Auth, Firestore, FCM, Storage)
- **API**: Cloudflare Workers (via Dio REST client)
- **Storage**: Hive (local cache) + SharedPreferences
- **Calls**: Agora RTC (WebRTC)
- **Encryption**: PointyCastle + Cryptography
- **Ads**: Google Mobile Ads (AdMob)
- **DI**: GetIt + Injectable

## 🚀 Getting Started

### Prerequisites

1. **Flutter SDK** 3.22+ ([Install](https://flutter.dev/docs/get-started/install))
2. **Android Studio** with Android SDK 34+
3. **Firebase CLI** ([Install](https://firebase.google.com/docs/cli))
4. **JDK 17+**

### Setup Steps

```bash
# 1. Clone or copy this project
cd zaxo_app

# 2. Install dependencies
flutter pub get

# 3. Generate code (Hive adapters, Injectable)
flutter packages pub run build_runner build --delete-conflicting-outputs

# 4. Firebase setup
# - Create a Firebase project at console.firebase.google.com
# - Add Android app with package name: com.zaxo.app
# - Download google-services.json → android/app/google-services.json
# - (Replace the placeholder file)

# 5. Enable Firebase services:
# - Authentication (Email/Password + Google)
# - Cloud Firestore
# - Cloud Messaging
# - Storage
# - Crashlytics
# - Analytics

# 6. Configure AdMob (optional)
# - Add your AdMob App ID to AndroidManifest.xml
# - Replace ad unit IDs in the app

# 7. Run the app
flutter run

# 8. Build APK
flutter build apk --release

# 9. Build App Bundle (for Play Store)
flutter build appbundle --release
```

### Environment Variables

Create a `.env` file or set these in your CI/CD:

```
FIREBASE_API_KEY=your_api_key
FIREBASE_PROJECT_ID=your_project_id
FIREBASE_APP_ID=your_app_id
FIREBASE_MESSAGING_SENDER_ID=your_sender_id
CLOUDFLARE_WORKER_URL=https://zaxo.eu.cc/api
AGORA_APP_ID=your_agora_app_id
ADMOB_APP_ID=your_admob_app_id
```

## 🎨 Design System

- **Primary**: #7C3AED (Deep Purple)
- **Secondary**: #06D6A0 (Mint Green)
- **Tertiary**: #F72585 (Hot Pink)
- **Background**: #0F0F1A (Deep Navy)
- **Surface**: #1A1A2E (Card Background)
- **Fonts**: Outfit (Headings) + Inter (Body)

## 📂 Project Structure

```
zaxo_app/
├── android/           → Android native config
├── ios/               → iOS native config  
├── web/               → PWA configuration
├── assets/            → Animations, Images, Fonts, Sounds
├── lib/
│   ├── main.dart      → App entry point
│   ├── app.dart       → MaterialApp with BLoC providers
│   ├── core/          → Theme, Constants, Extensions, Utils
│   ├── data/          → Models, DataSources, Repositories
│   ├── domain/        → Entities, Repository interfaces
│   ├── presentation/  → BLoCs, Screens, Widgets
│   ├── routes/        → GoRouter with transitions
│   └── di/            → GetIt dependency injection
├── pubspec.yaml       → Dependencies
└── analysis_options.yaml → Lint rules
```

## 🔒 Security

- End-to-end encryption (Signal Protocol inspired)
- Android Keystore for key storage
- Biometric authentication support
- Certificate pinning for API calls
- ProGuard/R8 obfuscation for release builds

## 📄 License

Proprietary - All rights reserved.
