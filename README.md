# VIV — Flutter app

iOS + Android client for the VIV backend: a training, nutrition and recovery
plan that adapts to your week and your menstrual cycle.

- **Design:** [VIVFEM in Figma](https://www.figma.com/design/1nCBTZEMrBmax4WnOjmv6j/VIVFEM)
- **API:** `viv-backend` OpenAPI 3.0.3 (37 routes). This app uses the **current pipeline** only. The legacy routes (`/checkins`, `/training/generate`, `/plans/*`) and `/rpc` are intentionally not wrapped.

## Stack

| Concern | Choice |
| --- | --- |
| State | `flutter_riverpod` 3 (no codegen) |
| Navigation | `go_router` — redirect-driven auth/onboarding gate, `StatefulShellRoute` for the 4 tabs |
| HTTP | `dio` behind a small `ApiClient` (plain-text errors, 204 → `null`, 401 → refresh token once) |
| Auth | Firebase Auth (email, Google, Apple) → ID token as `Authorization: Bearer` |
| App Check | `firebase_app_check`, sent as `X-Firebase-AppCheck` (backend is in monitor mode) |
| Local cache | `shared_preferences` (today's check-in result, meal choices) |

## Getting started

Requires Flutter **3.47+** (Dart 3.13).

```sh
flutter pub get

# 1. Connect Firebase (writes lib/firebase_options.dart + platform config files)
dart pub global activate flutterfire_cli
flutterfire configure --platforms=ios,android

# 2. Run against your backend
flutter run --dart-define=API_BASE_URL=https://your-api-host
#   Android emulator → local backend:  --dart-define=API_BASE_URL=http://10.0.2.2:8080
```

### Firebase / sign-in setup

- **Firebase console → Authentication:** enable Email/Password, Google, and Apple.
- **Google on Android:** pass the Firebase project's *Web client ID* so Google returns an ID token:
  `--dart-define=GOOGLE_SERVER_CLIENT_ID=xxxx.apps.googleusercontent.com`.
  Add your debug SHA-1 in the Firebase Android app settings.
- **Google on iOS:** add the `REVERSED_CLIENT_ID` from `GoogleService-Info.plist` as a URL scheme in `ios/Runner/Info.plist`.
- **Apple (iOS only for now):** enable the *Sign in with Apple* capability in Xcode. The button is hidden on Android, which would need a web Service ID.
- **App Check:** debug builds use the debug providers. Register the debug token printed in the device log in Firebase → App Check. Release builds use Play Integrity / App Attest.

| `--dart-define` | Default | Purpose |
| --- | --- | --- |
| `API_BASE_URL` | `http://localhost:8080` | Backend root (routes mounted at `/`) |
| `GOOGLE_SERVER_CLIENT_ID` | — | Google Sign-In ID token on Android |
| `APP_CHECK_DEBUG` | `true` outside release | Use App Check debug providers |

## Project layout

```
lib/
  main.dart / app.dart          Firebase + App Check init, ProviderScope, MaterialApp.router
  core/
    theme/                      Design tokens from Figma (colors, type, spacing) + ThemeData
    widgets/                    VivButton, VivCard, OptionTile, ChoicePill, VivPage, …
    network/                    ApiClient, ApiException, job polling
    layout/responsive.dart      Breakpoints + max-width centering for tablets
  data/
    models/                     Typed models for every current-pipeline payload
    api/viv_api.dart            One method per endpoint
    providers.dart              Riverpod providers (me, week, day, nutrition, recovery, check-in)
  features/
    auth/                       Welcome · Sign up · Log in
    onboarding/                 Fit check → About you → Training → Week → Cycle → Consent → building
    home/                       Tab shell, splash, Today, period-start sheet
    checkin/                    Progressive 4-question check-in + completion moment
    training/                   This week, edit a day, session detail, live set logging + rest timer
    nutrition/                  Eat today, swap meal, meal detail, full targets, nutrition setup
    recovery/                   Recovery card + actions
    profile/                    Menu, Your info (edits via PATCH /me)
  router/                       Routes + session gate (signedOut / needsOnboarding / ready)
```

## Design system ↔ Figma

Colors come from the Figma variables, e.g. `Cannon Pink #8A4A57` is the light-mode primary, `Puce #C97F8D` the dark-mode primary, and `Zeus #16110F` / `Vista White #FBF7F5` the backgrounds. Read them via `context.viv.primary` and similar (`VivColors` is a `ThemeExtension`, so light/dark switch automatically). Type follows the Figma text styles: SF Pro (platform default on iOS) plus bundled **JetBrains Mono** for the uppercase eyebrows.

**Responsive:** content is capped at 560 pt and centered on tablets/landscape. At ≥ 840 pt the bottom tab bar becomes a navigation rail.

## API coverage

| Area | Endpoints | Where |
| --- | --- | --- |
| Profile | `GET/PATCH /me` | session gate, Today, Profile |
| Onboarding | `POST /onboarding` + job poll | Consent → Building |
| Check-in | `POST /checkin` | Check-in |
| Cycle | `POST /cycle/period-start` | Today late-period card, Your info |
| Weekly plan | `current`, `day` (GET/PATCH), `note`, `generate` + status | Today, Train |
| Session logging | `day/start`, `day/log-set`, `day/complete` | Live session |
| Nutrition | `nutrition/onboarding`, `nutrition/plan`, `meal-selection` | Eat |
| Recovery | `recovery/card`, `recovery/card/action` | Recover |
| Device | `users/me/device-token` | API method ready; FCM not wired yet |

## Open questions / gaps (to resolve with design + backend)

1. **Name + date of birth** are required by `POST /onboarding` but have no Figma frame. They are collected in an added "About you" step, so onboarding shows "Step 1 of 4" instead of "of 3".
2. **"Which days usually fall apart?"** (onboarding) has no API field, so it is collected but not sent.
3. **No "today's check-in" read endpoint:** the last `POST /checkin` response is cached on the device, so a reinstall shows the check-in prompt again (resubmitting is idempotent).
4. **Meal selections aren't echoed** in `GET /nutrition/plan`, so the choice is mirrored on the device.
5. **Status of `GET /nutrition/plan` before nutrition onboarding** is undocumented. The app treats 404/5xx as "not set up yet" (`TODO(api)` in `providers.dart`).
6. **No endpoint** for the "not a fit yet" email waitlist, or for completing a non-Strength (non-loggable) day.
7. Not built yet: Notifications, Privacy & data, Help screens, push notifications (FCM), the hero photo on Welcome (placeholder gradient), and Terms/Privacy links.

## Development

```sh
flutter analyze
flutter test          # models, API client, onboarding mapping, every screen × phone/tablet × light/dark
dart format lib test  # 100-column page width (analysis_options.yaml)
```
