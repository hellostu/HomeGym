# HomeGym

A native macOS menu-bar app that prompts you to do short **"snack workouts"** during
your workday. It suggests an exercise (e.g. *3 sets of dumbbell curls*), you log the
weight and reps, and it tells you when to increase the weight — all without leaving
your desk for a full session.

## What it does

- **Lives in the menu bar** (no Dock icon). Click it for status + quick actions.
- **Prompts at random times** within your work hours, spaced out, weekdays-only by default.
- **Calendar-aware** — checks EventKit and never pops up during a meeting; it defers to
  just after the meeting ends.
- **Floating popup** appears over whatever you're working on with the suggested exercise.
- **Exercise library keyed to home-gym gear**: adjustable dumbbells, barbell + rack,
  EZ curl bar, adjustable bench, plus bodyweight moves. Rotates muscle groups so a week
  stays balanced.
- **Double progression**: each exercise has a rep range (default 8–12). Hit the top on
  every set and it suggests more weight next time; otherwise hold the weight and chase reps.
- **Equipment-accurate weights**: suggestions only ever land on loads you can actually
  make — the adjustable dumbbells snap to their fixed (pound-derived) kg ladder, and the
  barbell/EZ bar step from the empty-bar weight (20 kg / 9.5 kg) in 5 kg plate-pair jumps.
- **How-to guidance**: every exercise has step-by-step form cues and a key tip in the
  popup, plus a **Watch demo** button that opens a video demonstration in your browser.
- **Rest timer between sets**: logging a set auto-starts a countdown (default 90s,
  configurable) with +15s / Skip controls and a chime when rest is up.
- **Swap / repeat / resume**: swap a prompt for a different exercise, one-tap "repeat
  last set", and resume an unfinished workout where you left off.
- **PR celebration**: beating a previous best (weight or reps) pops a celebration.
- **Weekly consistency**: the menu shows how many workouts you've done this week.
- **Launch at login**: optional, so it's always there without opening it.
- **History & progress**: per-exercise session log and a top-weight trend chart.

## Running it

Open `HomeGym.xcodeproj` in Xcode 26 and press ⌘R. Run from Xcode so the app is
properly signed — Calendar and Notification permissions only work with a signed bundle.

On first launch:
1. The exercise library seeds automatically.
2. Open **Settings** from the menu bar and grant **Calendar** + **Notification** access.
3. Adjust work hours, workouts-per-day, minimum gap, and which muscle groups to include.
4. Use **"Do a workout now"** any time to test the popup.

## Build & test from the command line

```bash
xcodebuild -scheme HomeGym -destination 'platform=macOS' build
xcodebuild test -scheme HomeGym -destination 'platform=macOS'
```

## Layout

- `HomeGym/Models` — SwiftData models (`Exercise`, `WorkoutSet`, `SnackSession`, `AppSettings`).
- `HomeGym/Library` — the seeded exercise catalogue and `MuscleGroup`.
- `HomeGym/Progression` — `ProgressionEngine` (pure double-progression logic).
- `HomeGym/Scheduling` — `SlotPlanner` (pure timing), `WorkoutScheduler` (timer),
  `CalendarService` (EventKit), `NotificationService`.
- `HomeGym/UI` — menu, popup, history, settings.
- `HomeGym/AppCoordinator.swift` — ties services + data together.
- `HomeGymTests` — unit tests for the progression engine and slot planner.
