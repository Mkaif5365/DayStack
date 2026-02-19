# DayStack 👋

**Stack your days. Build your life.**

DayStack is a premium, offline-first discipline tracker built with Flutter and Supabase. It focuses on consistent daily progress through task management and journey tracking.

## ✨ Features

- **Rebranded Experience**: A sleek, dark-themed UI with emerald and gold accents.
- **Offline-First Persistence**: Powered by Hive, your progress stays on your device instantly—no more resets when relaunching or losing connection.
- **Robust No-Fap Journey**: A dedicated counter that persists across app restarts and syncs silently with the cloud.
- **Daily Focus Stats**: Profile metrics focused on "Today's Tasks" and "Completed Today" to keep you grounded in the present.
- **Stack Score**: A cumulative consistency metric that represents your overall journey.
- **Calendar History**: View your past task completions and streaks to stay motivated.

## 🛠️ Tech Stack

- **Framework**: Flutter
- **State Management**: Riverpod (Notifier/Provider)
- **Database**:
  - **Local**: Hive (Instant Cache)
  - **Cloud**: Supabase (Reliable Sync)
- **Navigation**: GoRouter
- **Persistence**: shared_preferences & flutter_secure_storage

## 🚀 Setup & Installation

### 1. Prerequisites

- Flutter SDK installed.
- Supabase account and project.

### 2. Database Configuration

Run the provided SQL in your Supabase SQL Editor:

- [schema.sql](supabase/schema.sql)

### 3. Application Setup

1.  **Create a `.env` file** in the root directory:
    ```env
    SUPABASE_URL=your_supabase_url
    SUPABASE_ANON_KEY=your_supabase_anon_key
    ```
2.  **Install dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Run the app**:
    ```bash
    flutter run
    ```

## 📦 Building for Production

### Android (APK)

To generate a release-ready APK:

1.  **Clean the project**:
    ```bash
    flutter clean
    ```
2.  **Get dependencies**:
    ```bash
    flutter pub get
    ```
3.  **Build the APK**:
    ```bash
    flutter build apk --release
    ```
    The output will be found at: `build/app/outputs/flutter-apk/app-release.apk`

---

_Built for a disciplined life._
