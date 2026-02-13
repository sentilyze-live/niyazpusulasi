# Niyaz Pusulası (Prayer Compass)

A modern Islamic daily helper app for iOS, optimized for the Turkish market.

## Features (MVP)

- **Prayer Times** — Diyanet-compatible calculation (offline-first via Adhan library), 6 daily times + Imsak, next-prayer countdown, Qibla direction
- **Ramadan Imsakiye** — Full month calendar with Imsak/Iftar times, live countdown (Sahur / Iftar), offline cached
- **Notifications** — Rolling 12-day schedule within iOS 64-slot limit, Time Sensitive alerts, per-prayer toggle + offset, Notification Health Check screen
- **Spiritual Habits** — Daily checklist (5 default habits), streak counter, monthly heatmap, daily reflection (1-10 rating + note)
- **Widgets** — Home screen (next prayer, all times, Ramadan) + Lock screen (circular, rectangular, inline)
- **Settings** — GPS or manual city selection (17 Turkish cities), calculation method selector, Hanafi/Shafi madhab, dark/light/system theme, 12h/24h time format

## Architecture

```
SwiftUI + MVVM
├── Services (FallbackPrayerTimesProvider, TimeEngine, NotificationManager, LocationManager, SettingsManager, HabitService)
├── Models (PrayerTimeDay, RamadanDay, LocationSelection, CalcSettings, ReminderSettings, CoreData entities)
├── ViewModels (TodayVM, RamadanVM, HabitsVM)
├── Views (Today, Ramadan, Habits, Settings, Components)
└── WidgetKit Extension (NextPrayer, TodayTimes, Ramadan)
```

### Key Design Decisions

- **Offline-first**: Adhan Swift library calculates prayer times locally — no network required
- **Dual provider**: AlAdhan API for cross-validation + Hijri dates, with actor-based cache
- **Notification budget**: 5 prayers × 12 days = 60 slots (of 64 max), with budget calculator in settings
- **CoreData** for habits/reflections (SwiftData too unstable for production in 2025-2026)
- **UserDefaults (App Group)** for prayer cache, settings, and widget data sharing

## Setup

### Prerequisites
- Xcode 15+ (macOS Sonoma or later)
- iOS 17.0 deployment target

### Steps

1. Open in Xcode: `File > Open > select the project folder`
2. Create a new Xcode iOS App project named `NiyazPusulasi` in this directory
3. Add the existing Swift files to the project targets
4. Add SPM dependency: `https://github.com/batoulapps/adhan-swift` (from version 1.4.0)
5. Add Widget Extension target: `NiyazPusulasWidget`
6. Configure App Group: `group.com.niyazpusulasi.shared` on both targets
7. Add capabilities:
   - App Groups (both targets)
   - Background Modes > Background fetch (main app)
   - Push Notifications (for Time Sensitive support)
8. Add the CoreData model file (`NiyazPusulasi.xcdatamodeld`) to the main target
9. Set the Info.plist keys:
   - `NSLocationWhenInUseUsageDescription`: "Namaz vakitlerini hesaplamak için konumunuz kullanılır."
   - `BGTaskSchedulerPermittedIdentifiers`: `["com.niyazpusulasi.refresh"]`
10. Build and run on simulator or device

### Project Structure

```
NiyazPusulasi/
├── App/                    # App entry point, ContentView
├── Models/                 # Data models + CoreData
├── Services/               # Business logic (providers, engine, managers)
├── ViewModels/             # MVVM view models
├── Views/                  # SwiftUI views organized by feature
│   ├── Today/
│   ├── Ramadan/
│   ├── Habits/
│   ├── Settings/
│   └── Components/
├── Extensions/             # Date, Color extensions
└── Resources/              # Assets, sounds, localization
NiyazPusulasWidget/         # WidgetKit extension
NiyazPusulasTests/          # Unit tests
```

## Data Flow

```
User opens app
  → LocationManager provides coordinates
  → FallbackPrayerTimesProvider:
      1. Check PrayerTimesCache (UserDefaults)
      2. Calculate via AdhanPrayerTimesProvider (offline)
      3. Cache result
      4. Background: cross-validate with AlAdhanAPIProvider
  → TimeEngine determines current/next prayer
  → TodayViewModel updates UI
  → WidgetDataWriter pushes to App Group
  → WidgetKit reads via TimelineProvider
  → NotificationManager schedules 60 notifications for N days
```

## Notification Strategy

iOS limits apps to 64 pending local notifications. Our budget:
- 60 slots for prayer/Ramadan alerts
- 4 reserved for housekeeping

Reschedule triggers:
1. Every app foreground entry
2. BGAppRefreshTask (every ~6 hours)
3. Settings change
4. Location change

## Testing

Run tests: `Cmd+U` in Xcode

Test files:
- `PrayerTimesTests.swift` — Calculation accuracy, city comparison, madhab validation
- `TimeEngineTests.swift` — Current/next prayer logic, Ramadan state, cross-day
- `NotificationTests.swift` — Budget compliance, ID uniqueness, coverage calculation

## Localization

- Development language: Turkish (tr)
- Supported: Turkish, English
- Uses Xcode String Catalogs (.xcstrings)
- Prayer names: İmsak, Güneş, Öğle, İkindi, Akşam, Yatsı

## Dependencies

| Package | Purpose | License |
|---------|---------|---------|
| [adhan-swift](https://github.com/batoulapps/adhan-swift) | Offline prayer time calculation | MIT |

All other frameworks are Apple-provided: SwiftUI, WidgetKit, CoreData, CoreLocation, UserNotifications, BackgroundTasks.

## License

Private — All rights reserved.
