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

### Confirm non-loggable sessions (Yoga, Pilates, Running, …)
Waiting on the backend. Today only Strength can be logged. `/home/today`
marks every other session `done` on its own (today's straight away, past
days once they pass), so the week's count includes sessions nobody
confirmed.

- **Backend:**
  - Let `POST /training/weekly-plan/day/complete {date, feedback?}` accept a
    non-loggable day without a prior `/day/start`, storing a session log with
    `status: completed` and no sets. Allow any date in the current week up to
    today, so yesterday can be confirmed late.
  - In `get_home_timeline.go`, count a non-loggable day as `done` only when
    that log exists, same as Strength. Today's session stays `pending` until
    confirmed. An unconfirmed past day stays `pending`; the app already draws
    that as a neutral dashed circle, never a red mark.
  - Return that log as `session` on `GET /training/weekly-plan/day` for those
    days too.
  - Have the recovery card treat a confirmed non-loggable session as
    yesterday's real session.
- **Frontend (once the backend ships):** a "Mark as done" button on session
  detail and on the Home session field for non-loggable days, then the
  existing done screen with the feel pills (`easy` / `right` / `too_much`).

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
