# Handoff: VIV — "Pulse" UI redesign (all screens)

## Overview
VIV is an iOS app (Flutter / FlutterFlow) for active women 28–42 that adapts training, nutrition and recovery to her real week: energy, schedule, physiology. This handoff covers the full redesign in the **Pulse** direction: 43 screens across 8 flows, each in light and dark, plus a working interactive prototype of the daily loop with final motion.

Product rules that the UI must keep. These are not optional:
- **Not a dashboard.** The UI shows prescriptions and decisions ("do this today, here's why in one line"). It never shows charts or raw biometric/cycle data as the main experience.
- **Wellness, not clinical.** VIV is positioned outside EU MDR. No diagnostic language, no lab-style charts, no clinical iconography, and no red/amber/green status colours.
- **Bandwidth first, cycle second.** Lead with everyday life (sleep, busy day, missed session). The cycle is a quiet secondary layer: one dot and one line, never the headline.
- **Never guilt.** No streaks, nothing in red, no "you missed". Skipping is a valid state.
- **Propose, never impose.** Every adjustment shows the original, offers "Keep the original", and tags her choice "your call".
- **Explain the why.** Every recommendation has a "Why today" link to 2–3 plain-language reasons.
- **No loaders.** The deterministic plan engine runs on device. Check-in, logging and swaps recompute instantly. No spinners, skeletons or "building your plan…" screens.
- Cycle-phase naming follows McNulty et al. 2020: early follicular, late follicular, ovulatory, early/mid luteal, late luteal. There is no "menstrual" phase; menstruation sits inside early follicular.

## About the design files
The files in `design/` are **design references built in HTML**. They are prototypes showing the intended look and behaviour, not production code. Your task is to **recreate them in the existing Flutter codebase** with its established patterns (widgets, theme, navigation, state management). Do not embed or port the HTML.

To view: open `design/VIV Design Proposal Pulse.dc.html` in a browser. Keep the four files in `design/` together, because they load each other.
- Top of the page: two **live phones**, one light and one dark. Tap through home → check-in → proposal → session done → evening. The buttons under each phone jump to a state or restart.
- Below: sections 01–08, each showing every screen in light, then dark, then the design notes.

## Fidelity
**High fidelity.** Colours, type, spacing, radii, copy and motion are final. Recreate them as closely as possible. All copy is final English. **Do not reword the four check-in questions or their answers.**

## Design tokens

### Colour: light
| Token | Hex | Use |
|---|---|---|
| page | `#FBF7F5` | screen background |
| raised | `#FFFFFF` | cards, sheets, grouped lists |
| sunken | `#F3EDEA` | rest-day pills, quiet strips, done-check fill, segmented track |
| line | `#E4DAD6` | 1px hairlines |
| ring | `#D3C6C2` | unselected radio/circle outlines, toggle off |
| ink | `#1A1310` | titles, values |
| ink2 | `#4A403D` | body inside cards |
| muted | `#6E6260` | body on page |
| subtle | `#7A6D69` | eyebrows, meta |
| faint | `#C4B6B1` | chevrons only |
| accent / cta | `#8A4A57` | primary buttons, links, selection, active tab dot |
| ctaText | `#FFFFFF` | text on cta |
| tint | `#F6EEEF` | soft info cards ("what changes") |
| tintInk | `#8A4A57` | text/eyebrow on tint |
| **field** | `#8A4A57` | the "now" block (see Wine field) |
| photo placeholder | `#E9DFDB` | image slots |
| stage | `#1A1310` | session-done background |

### Colour: dark
| Token | Hex |
|---|---|
| page | `#16110F` |
| raised | `#211A17` |
| sunken | `#2A221F` |
| line | `#352C28` |
| ring | `#4A3E39` |
| ink | `#F5EFEC` |
| ink2 | `#D8CCC7` |
| muted | `#A2938E` |
| subtle | `#968782` |
| faint | `#6E5F5A` |
| accent / cta | `#C97F8D` (rose) |
| ctaText | `#1A1210` |
| tint | `#2E2125` |
| tintInk | `#D998A4` |
| **field** | `#8E4D5B` |
| stage | `#211A17` |

### Colour: on the wine field (both themes)
| Token | Value |
|---|---|
| onField | `#FFF8F6` (titles, primary pill bg) |
| onFieldSoft | `rgba(255,248,246,0.88)` (body) |
| onFieldMuted | `rgba(255,248,246,0.80)` (eyebrows, pillar label) |
| onFieldFaint | `rgba(255,248,246,0.13–0.16)` (secondary pill bg, unselected options, progress track) |
| onFieldInv | `#5E2C38` (text on the onField pill) |
| fieldGlow | `#C97F8D` (blurred drifting blob) |
| ring stroke (done screen) | `#C97F8D` on `rgba(245,239,236,0.12)` track |

### Phase dots (fill only, never text, max one per screen)
early follicular `#B66F75` · late follicular `#978642` · ovulatory `#57966E` · early/mid luteal `#4590B2` · late luteal `#9777AF`. These are oklch(0.62 0.09 h) with h = 15 / 95 / 155 / 230 / 310. Identical in both themes.

`tokens/viv-variables.json` holds the same colour values in Tokens Studio format. It predates Pulse, so ignore its type sizes and radii and use the tables here.

### Typography: Schibsted Grotesk (Google Fonts, weights 400–800)
| Role | Size / line-height / weight / tracking |
|---|---|
| Screen title (h1) | 32–36 / 1.04 / 800 / −0.038em |
| Hero / proposal headline | 40 / 1.02 / 800 / −0.04em |
| Field title | 30–34 / 1.04 / 800 / −0.035em |
| Card title (h3) | 22–28 / 1.08 / 800 / −0.03em |
| Check-in question | 36 / 1.06 / 800 / −0.035em |
| Body lead | 15.5–16 / 1.5 / 400 |
| Body | 14.5–15 / 1.45–1.5 / 400 |
| Row title | 15.5–16 / – / 500–700 |
| Eyebrow | 12 / – / 700 / +0.1em, uppercase |
| Meta | 13 / – / 400–600 |
| Legal | 12.5 / 1.5 / 400 (smallest allowed) |
| Numbers (protein, rest timer, ring) | 52 / 96 / 60–62, weight 800, tracking −0.045 to −0.05em, tabular figures |

Use `text-wrap: balance` behaviour for headlines; prefer no orphans.

### Shape and spacing
- **All buttons, chips, segmented controls, set rows, strips and toggles are fully rounded** (radius 999).
- Button heights: 58 (bottom CTA), 54/52 (in-card), 48 (compact). Min tap target 44.
- Radii: wine field 30 (26 for in-list fields, 24 for day rows), cards 26, grouped lists 24, tiles 22, options/inputs 18–20, sheets 30 (top corners only).
- Screen padding: 20px horizontal, 60px top (clears the status bar; set it on the scaffold), 30–34px bottom inset on the pinned footer or tab bar, **never inside the scroll view**.
- Card padding 20 (16–18 compact), internal gap 12–15. Section gaps 14–24.
- Shadow (light only): `0 1px 2px rgba(26,19,16,.04), 0 10px 28px rgba(26,19,16,.06)`. Dark mode has no shadows.
- Hairlines are always 1px. The only 1.5px stroke is the selected state, in accent.

## Core components
- **Wine field ("now" block).** The single most important element. A full `field`-coloured block with one blurred `fieldGlow` circle (230px, blur 46, opacity .7, offset top-right, slowly drifting) behind the content. Header row: pulsing onField dot + eyebrow ("NOW · 07:40") on the left, pillar ("CHECK-IN", "TRAIN", "RECOVER") on the right. Then an optional tag (onField bg, onFieldInv text), the title, the body, buttons (primary = onField pill with onFieldInv text and "→"; secondary = onFieldFaint pill with onField text) and a "Why today ›" link. **Only one per screen.**
- **Timeline row** (Home "Rest of today"): 42px time column, 22px circle (done = sunken fill with ✓; later = 1.5px ring outline), title + one-line meta, 1px bottom hairline.
- **Week card:** 7 day circles, 28px. Done = cta fill with ✓; today = 2.5px accent ring; planned = ring outline; missed = dashed ring; rest = 5px dot. Header reads "N of 3 sessions". **Never a streak.**
- **Option row** (single-select): 58px min, radius 20, raised bg. Selected = 1.5px accent border plus an accent radio (7px stroke).
- **Bottom sheet:** raised bg, radius 30 top, 38×5 grabber, scrim `rgba(26,19,16,.45)` light / `rgba(0,0,0,.6)` dark.
- **Settings row:** shows its current value (700 weight, unit in subtle 14px). An empty field shows a "+ Add" tint pill, **never `null` and never the field's own name.**
- **Cost tag** (recovery): Building = sunken/muted, Medium = tint/tintInk, High = the whole card becomes a wine field with an onField tag.

## Screens
Every screen exists in light and dark in the reference file. Section numbers match the file.

**01 Entry:** Welcome (photo slot top, VIV wordmark, headline "Some weeks you train. Most weeks, life wins."), Sign up (Apple, Google, email), Log in.

**02 Fit check + onboarding:** Fit check (5 single-select options) → Not a fit yet (honest exclusion, one email capture) → 1 · Training (multi-select chips + goal) → 2 · Your week (days segmented, which days fall apart, desk/mixed/on feet) → 3 · Cycle (last period chips, cycle length) → Consent (single checkbox, link to the policy) → First week (instant, explains itself: "built around Tuesday and Thursday").

**03 Daily loop**, the core:
- **Home** is a time-aware timeline. The wine field holds whatever is due now. At 07:40 that's the check-in, at 17:45 the session, at 21:10 recovery. Below it: "Rest of today" rows, then the week card, then the tab bar (Today / Train / Eat / Recover).
- **Check-in** is a full-screen wine field with one question at a time. 4-segment progress, "Skip today" top right, answered values collected as chips at the top, question in 36px, options as 60px pills. Tapping an option advances automatically: there is no submit button. Footer: "Four taps. Then your plan."
- **Proposal:** eyebrow "Thursday · your call", headline built from her answers ("Rough night and a packed day."). A "Planned" card struck through, then a "Proposed" wine field. "Sounds good" (primary) and "Keep the original" (secondary). If her answers don't warrant a change, a single "As planned" field with a "Let's go" CTA.
- **Why today sheet:** 2–3 numbered reasons and one legal line.
- Other states: Home after accepting (tag "Adjusted · your call"), evening, skipped check-in ("That's fine, you're on your usual plan"), day after a miss ("Nothing to make up", with an option to do it today).

**04 Train:** This week (one column; today is the wine field with Start; rest days are slim pills) · Move sessions (drag; the lifted row tilts 1.2° with a deeper shadow; a tint card explains the consequence before saving) · Session detail · In session (the active set is the wine field with weight and reps steppers) · Rest (full wine, 96px timer) · Done (dark stage, ring 2/3, "How did that feel?").

**05 Eat:** Eat today (protein in the wine field at 52px with a progress bar; one suggestion per meal with Swap) · Meal detail · Swap sheet (alternatives ranked by effort, plus "Don't suggest X again") · Full targets (rounded values, training/rest day toggle).

**06 Recover:** Medium cost (one action visible, "Two more, and why" collapsed) · Medium expanded (max 2 secondary actions + 1 reason; cap this in the component) · High cost (the card is the wine field, with "I trained anyway" as an escape hatch and a strip "Thursday's session · Moved to Friday") · Training day ("Building").

**07 Cycle, quietly:** an always-on "Period arrived? · Log it" strip pinned at the bottom of Home · Prompt card near the estimate ("Yes, log it / Not yet") · Log sheet (Today / Yesterday / Earlier) · Rebuilt (wine field "What moved", new cycle estimate, Undo strip) · "Not yet" holding sheet (the plan holds; "Ask me again tomorrow") · Six days late ("VIV got this one wrong", with options to update cycle length or stop estimating). **No days-late counter, no irregularity flag, no pregnancy mention**, and one line pointing to her doctor.

**08 You:** Menu (her name, week number and session count in the wine field; grouped rows show their current values) · Your info · Edit a field sheet (shows "What changes" before Save) · Privacy & data (toggles with reasons, download, **Withdraw consent** with an honest consequence, and a not-a-medical-device line).

## Interactions and motion
Easing everywhere: `cubic-bezier(.2,.8,.2,1)`. In Flutter, `Curves.easeOutCubic` is close enough.

| Moment | Spec |
|---|---|
| Screen enter | fade + translateY 16→0, 520ms, children staggered 60–70ms |
| Wine field enter | scale .94→1 + fade, 620ms, 120ms delay |
| Field glow drift (ambient) | translate (−26, 18) + scale 1.15 and back, 9–12s loop |
| "Now" dot pulse (ambient) | ring scales 1→2.6 and fades, 1.8s loop |
| Check-in open | slides up over Home, 460ms |
| Answer tap | option fills (180ms) and scales to 1.02, 300ms hold, then the answer pops into a chip (scale .6→1.06→1, 380ms) and the next question slides in from the right (36px, 420ms). Options stagger 55ms. Progress segment fills via scaleX, 420ms. Guard against double taps during the hold. |
| Last answer → proposal | cross-fade 360ms. Headline 80ms, body 180ms, planned card 300ms. **Strike line draws across the old plan at 820ms** (scaleX 0→1, 520ms). **Proposed field scales in at 1150ms.** Buttons at 1300ms. |
| Sheets | rise 280–380ms, scrim fade 240ms |
| Accept / keep | back to Home, toast pill rises 360ms and auto-hides after 2.6s ("Swapped. Saturday has the heavy one." / "Kept the original. Your call.") |
| Session done | ring stroke-dashoffset 1/3→2/3 over 1400ms, 300ms delay; headline at 900ms |
| Week bars / protein bar | width fill 700–900ms, staggered 140ms |
| Press | scale .97 on primary pills |

Haptics: `HapticFeedback.selectionClick()` on each check-in answer, `mediumImpact()` when the done ring fills.
**Reduce Motion:** remove the drift, pulse, stagger and slides; keep the fades.
Motion only plays where something changed for her. Lists and settings stay still. Nothing bounces, no confetti.

Status bar style follows the surface: light glyphs on the wine field (check-in, rest), on the done stage and in dark mode; dark glyphs otherwise.

## State and logic (prototype behaviour to reproduce)
- `day`: `morning` (before check-in) → `planned` (after check-in or skip) → `evening` (after the session). This drives the Home hero and the timeline rows.
- `answers[4]`: indices into the fixed option lists. **The session is adjusted when** sleep ≥ Restless, OR body ≥ Heavier, OR day ≥ Packed, OR need = Let me reset.
- `adjusted`, `kept` (she chose "Keep the original"), `skipped`.
- Headline = sleep phrase ("A deep night" / "A normal night" / "Rough night" / "Barely any sleep") + " and " + day phrase ("an open day" / "a normal day" / "a packed day" / "an unpredictable day").
- Why-today reasons are built from the triggered answers (max 3). See `reasons` in `design/VIV Pulse.dc.html`.
- Early or late period: one shared log sheet and one confirmation screen, driven by a signed day-delta. Early rebuilds immediately; late holds the plan.

Check-in content (final, do not reword):
1. How did you sleep last night? Deep and restful / Normal / Restless / Barely slept
2. How does your body feel? Strong & responsive / Normal / Heavier than usual / Sensitive or reactive
3. How demanding is today? Light & open / Normal / Packed / Unpredictable
4. What do you need from today's session? Push me / Meet me where I'm at / Let me reset

## Assets
No final imagery is included. Photo slots are flat placeholders: the welcome hero (a real woman mid-week, ordinary setting, face visible, not a gym-glam crop) and meal thumbnails. Icons are minimal text glyphs (‹ › → ✓ ⌄). Use the codebase's icon set. No emoji.

## Files
- `design/VIV Design Proposal Pulse.dc.html`: every screen, light and dark, with notes per section. **Main reference.**
- `design/VIV Pulse.dc.html`: the interactive daily-loop prototype (logic is in the `<script>` class at the bottom). **Reference for motion timing and state.**
- `design/ios-frame.jsx`, `design/support.js`: viewer scaffolding only; don't port.
- `tokens/viv-variables.json`: colour tokens in Tokens Studio format.

## Suggested prompt for Claude Code
> Read `design_handoff_viv_pulse/README.md` fully, then open the two HTML files in `design/` for reference. Implement the Pulse redesign in our Flutter app. Start by adding the tokens above to our ThemeData (light + dark) and building the shared widgets: WineField, TimelineRow, WeekCard, OptionRow, PillButton, BottomSheet, SettingsRow. Then rebuild the daily loop (Home → Check-in → Proposal → Why sheet → Session done) with the exact motion spec. After that, do the remaining sections 01–08. Keep the product rules in the Overview, and ask me before changing copy or adding any data visualisation.
