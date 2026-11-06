# Guitar Studio (Android Native Flutter App)

<p align="center">
  <b>Complete Native Android Application for Guitar Studio with Interactive 3D Fretboard, Songs Player, Real-time Tuner, and Indian Percussion.</b>
</p>

---

## 🎸 Overview

This repository contains the full native Android application for **Guitar Studio** (`com.leadingnote.guitar_studio`), built using Flutter and high-performance native Android components. It connects directly with the Leading Note Music Academy backend while bundling the entire 3D WebGL engine, audio libraries, and assets locally for instant, offline-capable playback.

---

## ✨ Features

- **Interactive 3D Fretboard & Anatomical Hands**:
  - Full 3D interactive neck powered by Three.js & WebGL2.
  - 360° touch rotation, pinch-to-zoom, and string picking.
  - "See the hands" anatomical fretting hand (`left.glb`).
  - "Whole guitar" acoustic scene with dual animated hands (`acoustic-scene.glb`).
- **Live Microphone Pitch Tuner**:
  - Integrated `android.permission.RECORD_AUDIO` pipeline.
  - Real-time pitch tracking and chromatic tuning gauge.
- **Chord Library & Sound Engine**:
  - Comprehensive library across all roots and qualities (Major, Minor, 7th, maj7, etc.).
  - Real studio acoustic sample playback.
- **Song Studio & Interactive Tab Player**:
  - Synchronized moving tab timeline with 3D fretboard note highlighting and scoring.
- **Rhythm Studio & Indian Percussion**:
  - Metronome with custom subdivisions, tap tempo, and beat accents.
  - Studio drums and authentic Indian Tabla rhythms (Teental, Keherwa, Dadra loops).
- **Practice Studio & Hindi Localization**:
  - Interactive chord games, lessons, and Hindi language mode (`हिंदी`).
- **AI Guitar Tutor ("Ask me")**:
  - Floating AI assistant sheet with interactive queries and suggestions.

---

## 🛠️ Architecture & Native Optimizations

1. **Local High-Speed Asset Streaming**:
   - Uses AndroidX `WebViewAssetLoader` with domain `https://appassets.androidplatform.net`.
   - Avoids file-scheme CORS locks and provides instant 60 FPS rendering.
2. **Hybrid Authentication Proxy (`MainActivity.kt`)**:
   - Proxies `/api/*` endpoints to the remote Oracle server (`https://guitar.leadingnotemusicacademy.com`).
   - If an unauthenticated guest launches the app, an instant `Student` session is provided to prevent login lockouts and ensure a seamless Google Play Review experience.
   - Live logins authenticate securely against the Oracle database.

---

## 📱 Hardware Testing

Tested and verified on physical hardware:
- **Device**: Xiaomi Redmi Note 7S (`11ff0407`)
- **OS**: Android 10 (API 29, ARM64)
- **Status**: Passed all 8 core functional modules with 0 crashes.

---

## 🚀 Building & Releasing

### Prerequisites
- Flutter SDK 3.47.9+
- Android SDK 34+
- Java 17

### Build Release APK (Sideloading)
```bash
flutter build apk --release
```
Output: `build/app/outputs/flutter-apk/app-release.apk` (~142 MB)

### Build Release App Bundle (Google Play Store)
```bash
flutter build appbundle --release
```
Output: `build/app/outputs/bundle/release/app-release.aab` (~132 MB)

---

## 📄 License & Credits
Developed for **Leading Note Music Academy**. All rights reserved.
