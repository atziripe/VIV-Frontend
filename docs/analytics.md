# Analytics tracking plan (Amplitude)

Product analytics go to **Amplitude's EU data centre**. All events are sent from the app; server-side events (week generated, deletion executed, inactivity sweep) can be added from the backend later with the same `user_id`.

Code: `lib/core/analytics/` (`Analytics` has one method per event). Every event below is a method there, so a new event means a new method, not a string in a screen.

## Consent and privacy rules

- **Consent:** analytics follow the `research_product_improvement` consent purpose (`/me/consents`).
  - Asked as an optional, unchecked box on the onboarding Consent screen.
  - Can be changed later in Privacy & data → "Help improve VIV".
- **Before the user decides** (Welcome → sign-up → onboarding):
  - events are held **in memory for this session only**: nothing is sent, nothing is written to the device, and the Amplitude SDK isn't even started;
  - if the user opts in, the held events are sent;
  - if the user opts out, or signs out, they are dropped.
- **Opting out later** puts the SDK in opt-out mode immediately.
- **Signing out** resets the SDK, which forgets the user id and the device id.
- **No health data, ever:** no cycle phase, cycle day, days late or period dates; no check-in sleep or body answers; no weight, height or date of birth.
- **"Not a fit yet" isn't tracked.**
  - The backend already counts the reason anonymously (`POST /onboarding/ineligibility`).
  - Those users never reach the consent step, so their held events are dropped.
- **Identity:** `user_id` is the Firebase uid. Never a name or an email.
- **No key, no analytics:** without `AMPLITUDE_API_KEY` every call is a no-op.

## Setup

Add the Amplitude project API key to `dart_defines.local.json` (gitignored):

```json
{ "AMPLITUDE_API_KEY": "..." }
```

Use one Amplitude project for development and another for production.

## KPIs

| KPI | Built from |
| --- | --- |
| **Weeks on plan** (north star): % of active users with ≥3 check-ins and ≥1 completed session in a week | `checkin_completed`, `session_completed` |
| **Activation:** first check-in and first session within 7 days of sign-up | `signup_completed`, `checkin_completed`, `session_completed` |
| **Onboarding conversion** | `welcome_viewed` → `auth_started` → `signup_completed` → `fit_check_passed` → `onboarding_step_completed` (×4) → `consent_given` → `onboarding_completed` → `first_week_ready` |
| **Adherence** (sessions done ÷ planned) | `session_completed`. Planned sessions come from the backend later |
| **Check-in habit** | `checkin_completed` per user per week |
| **Adaptation accepted** | `checkin_suggestion_accepted` ÷ `checkin_completed` where `suggestion_shown` |
| **Retention** (D1 / D7 / D30, weekly) | any event, Amplitude retention charts |
| **Module adoption** | `nutrition_setup_completed`, `meal_swapped`, `recovery_action_logged`, `week_day_edited` |
| **Trust / exit** | `consent_changed`, `data_exported`, `deletion_scheduled`, `deletion_cancelled`, `consent_withdrawn` |
| **Technical quality** | `api_error`, `first_week_ready.wait_seconds` / `failed` |

## Events

| Event | When | Properties |
| --- | --- | --- |
| `welcome_viewed` | Welcome screen shown | — |
| `auth_started` | Apple / Google / email button tapped | `method` (`apple`, `google`, `email`), `screen` (`sign_up`, `log_in`) |
| `signup_completed` | Sign-in that created a new account | `method` |
| `login_completed` | Sign-in to an existing account | `method` |
| `fit_check_passed` | Fit check continued with a natural cycle | — |
| `onboarding_step_completed` | Continue on a numbered step | `step` (`about_you`, `training`, `week`, `cycle`) |
| `consent_given` | "Build my week" tapped | `analytics` (bool) |
| `onboarding_completed` | `POST /onboarding` succeeded | — |
| `first_week_ready` | First week job finished or gave up | `wait_seconds`, `failed` |
| `home_viewed` | Today timeline shown | `now_card_kind` (optional), `is_rest_day` |
| `now_card_tapped` | Primary button on the now card | `kind` |
| `checkin_completed` | `POST /checkin` succeeded | `need` (`push_me`, `meet_me_where_im_at`, `let_me_reset`), `suggestion_shown` |
| `checkin_suggestion_accepted` | Suggestion applied to today | — |
| `session_started` | Live logging started | — |
| `session_completed` | Live logging finished | `duration_min`, `sets_logged` |
| `week_day_edited` | A day's slot changed (edit sheet or "Not today") | `to_rest` |
| `recovery_action_logged` | Recovery card action saved | `kind` |
| `nutrition_setup_completed` | Nutrition preferences submitted | — |
| `meal_swapped` | Meal option selected | — |
| `consent_changed` | An optional consent toggled | `purpose`, `granted` |
| `data_exported` | Export shared | — |
| `deletion_scheduled` | `DELETE /me` succeeded | — |
| `deletion_cancelled` | Pending deletion cancelled (banner or Privacy) | — |
| `consent_withdrawn` | Health-data consent withdrawn, sent just before the immediate deletion | — |
| `api_error` | Any failed request | `endpoint` (path only), `status` (optional) |

### User properties

These come from `/me` and never include health data:
- `goal_id`
- `training_often`
- `activities_count`
- `nutrition_enabled`
- `week_with_viv`
- `onboarding_completed`
- `signup_method`

Amplitude adds platform, OS, app version and country on its own.
