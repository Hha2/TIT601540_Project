# Persist Flutter — Setup Guide

## 1. Firebase Setup (Required)

### Step A — Create Firebase Project
1. Go to [console.firebase.google.com](https://console.firebase.google.com)
2. Click **Add project** → name it (e.g., `persist-app`)
3. Enable Google Analytics (optional) → Create project

### Step B — Add Android App
1. In Firebase console → **Project Settings** → **Your apps** → Add app → Android
2. Package name: `com.persist.persist_flutter`
3. Download `google-services.json`
4. Place it in: `android/app/google-services.json`

### Step C — Add iOS App (if needed)
1. Add app → iOS
2. Bundle ID: `com.persist.persistFlutter`
3. Download `GoogleService-Info.plist`
4. Place it in: `ios/Runner/GoogleService-Info.plist`

### Step D — Update `lib/firebase_options.dart`
Either:
- Run `dart pub global activate flutterfire_cli` then `flutterfire configure`
- OR manually copy your Firebase config values into `lib/firebase_options.dart`

### Step E — Enable Firebase Services
In the Firebase console enable:
- **Authentication** → Sign-in method → Email/Password
- **Cloud Firestore** → Create database (start in test mode)

### Step F — Firestore Security Rules (for production)
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

---

## 2. OpenRouter AI Setup (Optional)

1. Go to [openrouter.ai](https://openrouter.ai) and create an account
2. Generate an API key
3. Open `lib/services/openrouter_service.dart`
4. Replace `'YOUR_OPENROUTER_API_KEY'` with your key

Without this key, AI chat and goal generation won't work, but the rest of the app functions normally.

---

## 3. Running the App

```bash
cd persist-flutter
flutter pub get
flutter run
```

---

## App Structure

```
lib/
├── main.dart                    # Entry point + providers
├── firebase_options.dart        # Firebase config (fill this in)
├── constants/
│   └── themes.dart              # 5 themes: Emerald, Rose, Violet, Obsidian, Midnight
├── models/
│   ├── goal.dart                # Goal, Day, Task models
│   ├── user_profile.dart        # User profile model
│   ├── mood.dart                # Mood entry model
│   ├── chat_message.dart        # Chat message model
│   └── app_usage.dart           # App usage model
├── providers/
│   ├── auth_provider.dart       # Firebase auth state
│   ├── goals_provider.dart      # Goals with real-time Firestore sync
│   └── theme_provider.dart      # Theme switching (persisted)
├── services/
│   ├── firestore_service.dart   # Firestore operations + skip probability
│   └── openrouter_service.dart  # OpenRouter AI integration
├── screens/
│   ├── auth/
│   │   ├── login_screen.dart
│   │   └── signup_screen.dart
│   ├── tabs/
│   │   ├── home_screen.dart     # Today's tasks + mood chart
│   │   ├── goals_screen.dart    # Goals list with filters
│   │   ├── insights_screen.dart # Analytics + skip probability
│   │   ├── reflect_screen.dart  # AI coach chat
│   │   └── settings_screen.dart # Theme picker + notifications
│   ├── goal_detail_screen.dart  # Day-by-day accordion view
│   ├── new_goal_screen.dart     # Create/edit goal + AI builder
│   └── app_usage_detail_screen.dart
├── widgets/
│   └── mood_chart.dart          # Custom SVG-like line chart
└── main_screen.dart             # Bottom tab navigation
```

## Features
- Firebase Auth (email/password)
- Real-time Firestore sync for goals
- 5 switchable themes (3 light + 2 dark), persisted locally
- AI-powered goal plan generation via OpenRouter
- AI chat coach with goal creation flow
- Mood logging after task completion
- Skip probability calculation
- SVG-style mood trend chart (CustomPainter)
- Animated custom bottom tab bar
- Goal detail with accordion day view
- App usage analytics
