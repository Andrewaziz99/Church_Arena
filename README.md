# Church Arena — مهرجان العباقرة

A Flutter Windows desktop application for running church quiz competitions. Supports multiple rounds with buzzer hardware, real-time cloud sync, a dedicated TV presenter window, and a full Arabic UI.

---

## Features

### Competition Rounds

**Round 1 — أسئلة الفرق (Team Questions)**
All available questions are split equally across teams. Each team answers their assigned questions individually. Questions are served in `sort_order` sequence — no shuffle.

**Round 2 — ضربات جزاء (Penalty Shootout)**
Teams compete in pairs. The first team to buzz and answer correctly wins the round's points. Configurable questions per match: 1, 2, 3, 5, or 10.

**Round 3 — تحت الضغط (Under Pressure)**
Individual contestants from each team answer rapid-fire questions under a shared countdown timer. Configurable questions per contestant: 1, 2, 3, 5, 10, or All available.

### Question Management
- Import questions from CSV or Excel (.xlsx) with a downloadable template
- Drag-to-reorder questions within any category (persisted as `sort_order`)
- Filter by category, round type (r1 / r2 / r3), and difficulty (easy / medium / hard)
- Question types: text, image, audio, video
- Configurable points and wrong-answer deduction per question
- Category colour coding and section scoping

### Teams
- Create teams with custom colours and member lists
- Per-section filtering (grade groups: اولى وثانية, ثالثة ورابعة, خامسة وسادسة)
- Live score tracking with optimistic UI updates
- Clear all scores at once

### TV Presenter Window
A second Flutter engine opens on the secondary monitor (auto-detected via `screen_retriever`) and covers the full display. It shows:
- Idle screen — church logo and event title (مهرجان العباقرة)
- Question display with category, difficulty, points, and optional media
- Answer reveal overlay

IPC between the main app and the TV window uses `desktop_multi_window` method channels.

### Cloud Sync (Supabase)
- Offline-first: all data lives in local SQLite; Supabase is optional
- Fire-and-forget upserts with `onConflict: 'id'` — no duplicates
- Real-time pull via Supabase Realtime subscriptions
- **Sync All Data** button on the dashboard pushes everything in one shot: teams (with live scores), categories, questions (with sort_order), and full competition history
- Room ID scoping — multiple devices in the same room share live data

### Scoreboard & History
- End-of-competition results stored locally and synced to Supabase
- Historical leaderboard with winner snapshots per session

### Hardware — Arduino Buzzer
- Serial port connection (COM port + baud rate configurable in Settings)
- Auto-reconnect on startup using saved settings
- Buzzer reset between questions

### Settings
- COM port / baud rate for the buzzer
- Question timer duration (10–120 s)
- Number of teams
- Sound volume
- Fullscreen toggle (main window)
- Room ID for cloud sync

### How To Play Demo
An animated 5-page walkthrough accessible from the sidebar at any time, with a mock game launcher using sample Christian Arabic team names.

---

## Architecture

```
lib/
├── core/
│   ├── constants/       # AppColors, AppStrings
│   ├── database/        # SQLite helper + DatabaseSeeder
│   ├── errors/          # Failure types
│   ├── extensions/      # BuildContext helpers
│   ├── utils/           # AppLogger
│   └── widgets/         # AppNavSidebar (shared layout shell)
│
├── features/
│   ├── dashboard/       # Main dashboard + connection log
│   ├── demo/            # How To Play animated guide
│   ├── game/            # Game session BLoC, state machine, screens
│   ├── questions/       # Category + question CRUD, import, reorder
│   ├── scoreboard/      # Competition results + history screen
│   ├── settings/        # App settings BLoC + screen
│   ├── teams/           # Team CRUD + score management
│   └── tv/              # TV presenter Flutter app (sub-window engine)
│
├── injection/           # GetIt + injectable DI wiring
├── router/              # GoRouter route definitions
└── services/
    ├── arduino/         # Serial port / buzzer service
    ├── audio/           # Sound effects
    ├── sync/            # SupabaseSyncService, RealtimeManager, ConnectionLog
    └── tv/              # TvWindowService (lifecycle + IPC)
```

### Key Patterns
- **BLoC** (`flutter_bloc`) for all state management — one bloc per feature
- **Clean Architecture** — domain entities, use cases, and data repositories separated per feature
- **Offline-first** — SQLite is the source of truth; Supabase sync runs as background fire-and-forget
- **Optimistic UI** — state is emitted before the DB write; reverted on failure
- **GetIt + injectable** for dependency injection
- **GoRouter** for navigation

---

## Data Model

### SQLite Tables

| Table | Key Columns |
|---|---|
| `teams` | id, name, color, score, section, members, is_active |
| `categories` | id, name, color, section, round_type (r1/r2/r3), question_ids |
| `questions` | id, text, category_id, type, difficulty, points, wrong_points, sort_order, correct_answer, options, is_used, media_path |
| `competition_results` | id, completed_at, teams_json |
| `app_settings` | com_port, baud_rate, timer_duration, number_of_teams, sound_volume, is_fullscreen, room_id |

### Supabase Tables
Mirror the SQLite schema. Two one-time SQL statements are required before first use (see Setup below).

---

## Setup

### Requirements
- Flutter ≥ 3.10 with Windows desktop target enabled
- Dart ≥ 3.0

### Run
```bash
flutter pub get
flutter run -d windows
```

### Supabase (optional)
The app runs fully offline without Supabase. To enable cloud sync, pass credentials at build time:

```bash
flutter run -d windows \
  --dart-define=SUPABASE_URL=https://your-project.supabase.co \
  --dart-define=SUPABASE_ANON_KEY=your-anon-key
```

Then run this SQL once in the Supabase SQL editor:

```sql
-- Add sort_order to questions
ALTER TABLE public.questions
  ADD COLUMN IF NOT EXISTS sort_order INTEGER NOT NULL DEFAULT 0;

-- Competition results table
CREATE TABLE IF NOT EXISTS public.competition_results (
  id           TEXT PRIMARY KEY,
  completed_at TIMESTAMPTZ NOT NULL,
  teams_json   TEXT NOT NULL
);
ALTER TABLE public.competition_results ENABLE ROW LEVEL SECURITY;
CREATE POLICY "allow all" ON public.competition_results FOR ALL USING (true);
```

### Arduino Buzzer
Connect the Arduino via USB. In Settings, select the correct COM port and baud rate. The app auto-connects on the next startup using the saved values.

---

## Key Dependencies

| Package | Purpose |
|---|---|
| `flutter_bloc` | State management (BLoC pattern) |
| `go_router` | Declarative navigation |
| `get_it` + `injectable` | Dependency injection |
| `sqflite_common_ffi` | SQLite on Windows |
| `supabase_flutter` | Cloud sync + Realtime subscriptions |
| `desktop_multi_window` | TV presenter second-window engine |
| `window_manager` | Main window sizing and fullscreen |
| `screen_retriever` | Detect and position on secondary monitor |
| `flutter_libserialport` | Arduino serial communication |
| `audioplayers` | Sound effects |
| `file_picker` | CSV / Excel import dialog |
| `google_fonts` | Alexandria font (Arabic) |
| `flutter_animate` | UI animations |
| `dartz` | Functional `Either` for error handling |
