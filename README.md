# WakeMe — Flutter GPS Destination Alarm 📍⏰

> **Never miss your stop again.** A cross-platform Flutter application for travellers who fall asleep during train, bus, or road journeys and need reliable, offline-capable proximity alarms before arriving at their stop.

[![Flutter](https://img.shields.io/badge/Flutter-3.41+-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11+-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Platform](https://img.shields.io/badge/Platform-iOS%20%7C%20Android-40E0C0)](https://flutter.dev)
[![License](https://img.shields.io/badge/License-MIT-0C9F88)](LICENSE)

---

## 📱 Screenshots & Design Philosophy

WakeMe is engineered with a **premium dark aesthetic** built for travellers moving through night journeys, dimmed cabins, and long transits:

- **Background:** `#0B1220` (Deep Midnight)
- **Card Background:** `#142235` (Navy Surface)
- **Secondary Surface:** `#20344A` (Muted Teal-Navy)
- **Primary Accent:** `#40E0C0` (Vibrant Aqua Teal)
- **Active Teal:** `#0C9F88`
- **Main Text:** `#FFFFFF` | **Secondary Text:** `#9CB1C7`
- **Stage 1 (Approaching):** `#40E0C0` (Teal Chime)
- **Stage 2 (Wake Up Alarm):** `#FF756B` (Urgent Coral Alarm)
- **Warning:** `#FFB454` (Amber Fix Status)

---

## ✨ Features & Architecture

### 1. Home Screen & Destination Search
- **Free Geocoding:** Search destinations globally by name using OpenStreetMap Nominatim with zero API key requirement, plus native platform geocoding fallback.
- **Offline Caching:** Saves recent destinations and selected coordinates to local `SharedPreferences` so destinations remain selectable and viewable offline.
- **Live GPS Telemetry:** Real-time satellite status, speed in km/h, and GPS accuracy in meters (`±12m`).
- **Customizable Radii:** 
  - Stage 1 Approaching: Default **5.0 km** (customizable from 3 to 15 km).
  - Stage 2 Wake Up: Default **2.0 km** (customizable from 0.5 to 4.0 km).

### 2. Active Journey Screen
- **Real-Time GPS Tracking:** Updates as real GPS positions arrive via `Geolocator.getPositionStream`.
- **100% Offline Distance Computation:** Calculates great-circle distance locally on-device using the spherical Haversine formula—zero mobile data or server requests needed while en route.
- **Trip Progress Indicator:** Visual journey completion bar tracking distance covered from journey start to destination.
- **Active Telemetry Cards:** Displays live coordinates, speed, and last GPS fix timestamp.
- **Cancel Journey:** Clean cancellation dialog that stops audio, vibration, and background tracking.

### 3. Two-Stage Alert System
- **Stage 1 — Approaching (Default 5 km):**
  - Triggers once when remaining distance enters the 5 km perimeter.
  - Sounds a melodic two-tone chime (`assets/sounds/approaching.wav`).
  - Haptic double-pulse vibration.
  - Time-sensitive local notification: *"Approaching [Destination] — Prepare your belongings"*.
- **Stage 2 — Wake Up (Default 2 km):**
  - Triggers once when remaining distance enters the 2 km perimeter.
  - Urgent looping alarm tone (`assets/sounds/wakeup.wav`).
  - Continuous repeating vibration pattern.
  - High-priority full-screen wake-up alert: *"WAKE UP! You are within 2 km of your stop!"*.
  - Floating dismiss button (*"I'm Awake — Dismiss Sound"*).
- **Anti-False-Alarm Safeguards:**
  - **Single Trigger Guarantee:** Each stage can only trigger once per journey.
  - **Hysteresis & Fluctuation Lock:** GPS coordinate drift or bouncing around the boundary will never re-trigger an alarm.
  - **Poor Accuracy Filtering:** Readings with GPS accuracy worse than 120 meters are skipped to prevent inaccurate spikes from setting off alerts.
  - **Started-Inside Detection:** If the user initiates a journey while already inside an alert radius, WakeMe flags the stage as `STARTED INSIDE` with an explanatory notice instead of startling the passenger immediately.

### 4. Developer Distance Simulator 🧪
A built-in test suite allows developers and reviewers to test the entire alert sequence without driving 10 km:
- Toggle between **Real GPS Mode** and **Simulator Mode**.
- Quick test buttons:
  - `1. Far Away (8.0 km)` — Both alerts waiting.
  - `2. Enter 5 km (4.5 km)` — Triggers Stage 1 (Approaching chime + notification).
  - `3. Enter 2 km (1.8 km)` — Triggers Stage 2 (Wake-up alarm + vibration).
  - `4. Arrived (200 m)` — Destination reached.
- Step controls: `-500 m`, `-1.0 km`, and `Reset` to re-test repeatedly.
- **Zero interference:** Real GPS operation is completely unaffected when the simulator is switched off.

---

## 📂 Project Structure

```
wakeme/
├── assets/
│   ├── icons/
│   └── sounds/
│       ├── approaching.wav      # Generated PCM WAV chime for Stage 1
│       └── wakeup.wav           # Generated PCM WAV alarm for Stage 2
├── ios/
│   └── Runner/
│       └── Info.plist           # Configured with Location & Background modes
├── android/
│   └── app/src/main/
│       └── AndroidManifest.xml  # Configured with Foreground service & permissions
├── lib/
│   ├── main.dart                # Application entrypoint & multi-provider wiring
│   ├── models/
│   │   ├── destination.dart     # Destination data model with JSON serialization
│   │   ├── alert_stage.dart     # Alert stage enum & status metadata
│   │   └── journey_state.dart   # Immutable journey state
│   ├── services/
│   │   ├── storage_service.dart # SharedPreferences offline persistence
│   │   ├── location_service.dart# Geolocator stream & permission handler
│   │   ├── geocoding_service.dart# Free Nominatim + native geocoding
│   │   ├── notification_service.dart# Local notifications for iOS & Android
│   │   └── alarm_service.dart   # AudioPlayer & device vibration manager
│   ├── providers/
│   │   └── journey_provider.dart# Core state orchestrator & alert evaluator
│   ├── widgets/
│   │   ├── glass_card.dart      # Dark glassmorphism card component
│   │   ├── gps_status_indicator.dart # Live pulsing satellite telemetry
│   │   ├── alert_radius_selector.dart# Interactive dual-radius configurator
│   │   └── dev_simulator_dialog.dart # In-app developer test panel
│   ├── screens/
│   │   ├── home_screen.dart     # Main landing screen
│   │   ├── search_destination_screen.dart # Destination search & recents
│   │   └── active_journey_screen.dart     # Real-time tracking & alarm display
│   └── utils/
│       ├── colors.dart          # WakeMe color palette
│       ├── theme.dart           # Dark theme definition
│       └── distance_calculator.dart # Haversine formula & progress math
└── test/
    ├── widget_test.dart         # Unit tests for Haversine, models, & alert stages
    └── journey_provider_test.dart # Integration tests for simulation & duplicate prevention
```

---

## 🚀 Running the App

### Prerequisites
- [Flutter SDK](https://flutter.dev/docs/get-started/install) 3.22+ (tested on Flutter 3.41 / Dart 3.11)
- macOS with Xcode (for iOS/macOS) or Android Studio (for Android)

### Quick Start Commands

```bash
# 1. Clone repository
git clone https://github.com/smasim825/WakeMeUp.git
cd WakeMeUp
git checkout wakeme-mvp

# 2. Fetch dependencies
flutter pub get

# 3. Run automated tests
flutter test

# 4. Check static analysis
flutter analyze

# 5. Run the application
# iOS Simulator / Device:
flutter run -d ios

# macOS Desktop:
flutter run -d macos

# Android Device / Emulator:
flutter run -d android
```

---

## 🍏 iOS Configuration & Technical Guidelines

### Info.plist Configuration
The following permissions and background modes are configured in `ios/Runner/Info.plist`:

```xml
<key>CFBundleDisplayName</key>
<string>WakeMe</string>

<!-- Location Permissions -->
<key>NSLocationWhenInUseUsageDescription</key>
<string>WakeMe requires your location to calculate distance to your arrival destination and trigger your wake-up alarm.</string>
<key>NSLocationAlwaysAndWhenInUseUsageDescription</key>
<string>WakeMe requires continuous location updates while your journey is active so you are alerted when you approach your destination, even when the screen is locked or the app is in the background.</string>
<key>NSLocationAlwaysUsageDescription</key>
<string>WakeMe tracks your distance to destination during your active journey to alert you before you arrive.</string>

<!-- Background Modes -->
<key>UIBackgroundModes</key>
<array>
    <string>location</string>
    <string>fetch</string>
</array>
```

### Critical iOS Background Execution Realities & Limitations

1. **Native Location Updates in Background:**
   WakeMe uses `AppleSettings(activityType: ActivityType.otherNavigation, pauseLocationUpdatesAutomatically: false, showBackgroundLocationIndicator: true)` to keep CoreLocation updates active with the native iOS blue status pill when the user navigates away from the app.
2. **Audio & The Silent / Ring Switch:**
   - On iOS, standard app audio playback is muted when the physical hardware switch is set to **Silent Mode** unless configured with an active AVAudioSession category of `playback` and appropriate entitlements.
   - For critical waking alarms, WakeMe issues high-priority, time-sensitive local notifications with `InterruptionLevel.timeSensitive` and `InterruptionLevel.critical` where permitted.
3. **App Force-Quit:**
   - If the user swipes up to force-quit the app from the iOS App Switcher, **iOS terminates all active processes and stops CoreLocation updates**. iOS will not revive a force-killed app until reopened by the user.
   - WakeMe persists active journeys to `SharedPreferences`. When reopened after being closed, the app immediately detects the active journey, recalculates current distance, and resumes tracking.
4. **No Artificial Background Audio Hacks:**
   In compliance with Apple App Store Review Guidelines, WakeMe does **not** play silent looped audio tracks in the background to circumvent iOS lifecycle rules.

---

## 🧪 Verification & Test Results

All 11 unit and integration tests pass cleanly:

```bash
$ flutter test
00:02 +11: All tests passed!

$ flutter analyze
Analyzing WakeMeUp...
No issues found! (ran in 1.4s)
```

Test coverage includes:
- ✅ Haversine great-circle calculation accuracy vs real-world coordinates.
- ✅ Distance formatting (`<1000m` -> `m`, `>=1000m` -> `km`).
- ✅ Progress percentage calculation clamped between `0.0` and `1.0`.
- ✅ Destination model JSON serialization and deserialization.
- ✅ Stage 1 (5 km) and Stage 2 (2 km) sequential triggers in test simulator.
- ✅ Duplicate trigger prevention during GPS jitter.
- ✅ Alarm dismiss and journey cancellation cleanup.

---

## 📋 Completed Features

- [x] Premium dark-mode UI with custom palette (`#0B1220`, `#142235`, `#40E0C0`, `#FF756B`).
- [x] Global destination search via OpenStreetMap Nominatim (no API keys required).
- [x] Native geocoding fallback for address resolution.
- [x] 100% offline Haversine distance tracking and destination storage.
- [x] Two-stage customizable alarm thresholds (5 km approaching, 2 km wake up).
- [x] Two generated offline PCM WAV sound assets (`approaching.wav`, `wakeup.wav`).
- [x] Vibration and haptic feedback on alert triggers.
- [x] Local notifications with time-sensitive priorities.
- [x] Live GPS telemetry: accuracy in meters, speed in km/h, coordinates.
- [x] Poor GPS accuracy filtering (>120m) to suppress coordinate bounce false triggers.
- [x] Safe start-inside handling to prevent immediate false alarms.
- [x] Local persistence with journey resumption on restart.
- [x] Interactive in-app Developer Distance Simulator.
- [x] iOS and Android background location & notification configurations.

---

## 🔮 Limitations & Future Roadmap

1. **Map Visualization:** Integrate offline vector tile rendering (e.g. MapLibre / Flutter Map) for route preview.
2. **Apple Critical Alerts Entitlement:** Apply for Apple's official `com.apple.developer.usernotifications.critical-alerts` entitlement to allow alarms to override iOS hardware Silent Mode.
3. **Transit Geofencing:** Support transit stop IDs (GTFS) for rail lines where GPS signal is temporarily lost underground in tunnels.
4. **Battery Optimization Profiles:** Dynamic GPS interval scaling based on speed (reduce poll frequency when remaining distance is > 20 km; increase to high frequency under 5 km).
