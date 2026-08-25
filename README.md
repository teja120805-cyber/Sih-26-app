# Companion Console — Flutter app

A native **Flutter** port of the *Personal Health Companion* (SIH26181) web
dashboard. It reproduces the "Companion Console" as a mobile app: a single
continuous scroll that reacts to a full simulated day of realistic sensor data,
with all of the maths and ML **computed on-device**, nothing fetched.

> **Source it was ported from:** the `dashboard/index.html` single-file web app
> in [`AbishekvGuru/SIH26`](https://github.com/AbishekvGuru/SIH26).

## What's implemented

Every section from the web console, driven by one `ConsoleState`:

| Section | Widget |
|---|---|
| Demo controls (Normal / Heat-wave · Typical / Higher-risk · Online / Offline · play · scrub) | `widgets/demo_bar.dart` |
| Headline summary + action chips | `widgets/hero_card.dart` |
| Strain chart (PSI + core temp, threshold lines, alert bands, time-to-next-alert projection) | `widgets/strain_chart.dart` |
| Vitals row (HR · SpO₂ · core temp with baseline gauges) + ML risk classifier | `widgets/vitals_row.dart` |
| Activity rings + hydration tracker | `widgets/activity_card.dart` |
| Sleep score, stages & recovery | `widgets/sleep_card.dart` |
| Environment conditions + threshold bars | `widgets/environment_card.dart` |
| Route map with alert markers (drawn/offline fallback) | `widgets/route_map_card.dart` |
| Alerts (severity bars + plain-language list) | `widgets/alerts_card.dart` |
| Fall & distress no-response countdown | `widgets/fall_check_card.dart` |
| "How this was calculated" transparency panel | `widgets/transparency_card.dart` |

### The real computation is ported, not faked

`lib/models/` reproduces the console's on-device pipeline in Dart:

- **`day_data.dart`** — the recursive (Kalman-style) core-temperature filter,
  the Physiological Strain Index, alert-tier extraction with minimum dwell,
  hydration/activity, sleep, environment and hero logic.
- **`ml_models.dart`** — dependency-free inference over the *actual* fitted
  models in `assets/data/models.json`: the Isolation Forest anomaly score, and
  the Random-Forest / linear classifiers & regressors (`predictProbability`,
  `predictValue`), walked with the same tree format the web uses.
- **`profile.dart`** — the two demo profiles' baselines and thresholds.

The two `assets/data/day_*.csv` files and `models.json` are the exact data
bundled from the source repo.

## For teammates — running it

The `android/` and `web/` platform folders **are committed**, so you don't need
`flutter create`. Just:

```bash
git clone https://github.com/teja120805-cyber/Sih-26-app.git
cd Sih-26-app
flutter pub get
flutter run            # pick a device when prompted
```

No third-party packages — `pub get` only fetches two tiny lint/icon packages.

### What each teammate needs to download

Everyone: the **Flutter SDK** (bundles Dart), 3.27+ — https://docs.flutter.dev/get-started/install
Then pick **one** run target:

| Target | Extra download | Command |
|---|---|---|
| **Web** (fastest) | Google Chrome | `flutter run -d chrome` |
| **Android** (phone/emulator) | Android Studio (for the SDK) → `flutter doctor --android-licenses` | `flutter run` |
| **Windows** desktop | Visual Studio 2022 + "Desktop development with C++" | `flutter run -d windows` |

Run `flutter doctor` to confirm the setup.

## Installing the APK (no Flutter needed)

To just try it on an Android phone, grab the APK from the repo's
[Releases](https://github.com/teja120805-cyber/Sih-26-app/releases) (or the
`build/app/outputs/flutter-apk/app-release.apk` a maintainer built), copy it to
the phone, and open it. You'll need to allow "install from unknown sources."

Build it yourself with:

```bash
flutter build apk --release
# → build/app/outputs/flutter-apk/app-release.apk
```

### Requirements
- **Flutter 3.27+** (Dart 3.6+). The app uses `Color.withValues`, added in 3.27.
- **JDK 17** for Android builds (bundled with Android Studio, or install separately).

## Not a medical device

This proves the computation pipeline and interaction design. It has not been
clinically validated, and none of the training data came from this exact
hardware — every number is a demo of the approach, not a diagnosis.
