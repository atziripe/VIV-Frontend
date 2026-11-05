# Backlog (post-MVP)

Out of scope for the MVP. Each item says what it needs before it can be built.

## Nutrition

### "Cooked it" saved on the backend
Today "Cooked it" lives only on the phone (`cookedMealsProvider`), resets each
day and only fills the protein bar on Eat.

- **Backend:** an endpoint to log a cooked meal, e.g.
  `POST /nutrition/meal-log {date, meal_slot, option_index, cooked: bool}`, and
  the day's logged slots echoed back (on `GET /nutrition/plan` or
  `/home/today`).
- **Frontend:** swap the device provider for the endpoint; keep the bar
  animation and the "N g in · breakfast done" line.

### Meal photos cached on disk
Photos are cached in memory only, so they download again after a restart.
- **Frontend:** `cached_network_image` behind `MealImage`.

## Training

### "This week" card redesign
Bars instead of day circles (see the cycle-card sketch, Nov 2026).
- **Frontend only:** `WeekCard` in `core/widgets/week_card.dart`.

### Move sessions (drag and drop)
Blocked on the backend.
- **Backend:** `POST /training/weekly-plan/rearrange {week_start, dry_run,
  moves: [{from, to}]}` returning `{week, changes: [{date, before, after,
  reason}]}`; validates and rebalances, re-hydrates moved days, clears the
  weekly-note cache, updates `is_training_day` on the nutrition plan and keeps
  `/home/today` consistent. `dry_run` powers the preview.

### Lifestyle changes and "Training paused"
Deferred. The backend already has `POST /lifestyle-changes`,
`GET /lifestyle-changes` and `training_paused` / `has_active_injury` on `/me`.
- **Frontend:** a "Something changed" flow (illness, travel, injury) and a
  paused state on Home and Train.

## Engagement

### Push notifications
`POST /users/me/device-token` exists; the app doesn't register for push yet,
so the morning check-in has no reminder ("Remind me" is hidden).
- **Frontend:** `firebase_messaging`, permission prompt, token upload, refresh.
- **Backend:** the scheduled sends themselves.
