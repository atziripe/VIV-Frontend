# VIV Flutter app — notes for Claude

- Flutter 3.47 / Dart 3.13, iOS + Android only. Riverpod 3 **without codegen**, go_router, dio, Firebase Auth.
- Figma source of truth: file key `1nCBTZEMrBmax4WnOjmv6j` (VIVFEM). Top-level frames: Welcome Page & Auth `36:538`, Fit & Onboarding `7:510`, All-in-one view `7:1419`, Training `12:4545`, Nutrition `12:5120`, Recovery `12:6043`, Checkin `12:6229`, Profile preferences `12:7136`.
- Backend: current pipeline only. Never call the legacy routes (`/checkins`, `/training/generate`, `/plans/*`) or `/rpc`.

## Conventions

- Colors: `context.viv.<role>` (semantic `VivColors`), never raw hex in screens. Text: `VivType.*` + `.copyWith(color: ...)`. Spacing: `VivSpace` / `VivRadius`.
- Screens are built from `core/widgets` (`VivPage`, `PageHeader`, `VivButton`, `VivCard`, `OptionTile`, `ChoicePill`, `Eyebrow`, `VivNote`). Add a shared widget before duplicating a pattern.
- Every endpoint goes through `VivApi` (`data/api/viv_api.dart`); models are hand-written in `data/models` using the `JsonRead` helpers (backend uses `omitempty`, so every field is optional).
- API values (enums, activity ids, cycle_type phrases) live in `data/models/catalog.dart`, `checkin.dart` and `onboarding_draft.dart`. The backend 400s on unknown values.
- Dates sent to the API are client-local `YYYY-MM-DD` via `Dates.ymd`.
- Error bodies are mostly `text/plain`; use `ApiException` / `userMessageFor`, and `showErrorSnack` in UI.

## Checks

`flutter analyze && flutter test`. `test/features/screens_render_test.dart` renders every screen on a 360 pt phone and a tablet in light and dark mode, so add new screens there.
