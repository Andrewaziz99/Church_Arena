-- ============================================================
-- Church Arena — Supabase Schema
-- Run this in your Supabase SQL editor after creating the project.
-- ============================================================

-- ── Teams ─────────────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS teams (
  id         TEXT PRIMARY KEY,
  name       TEXT NOT NULL,
  color      INTEGER NOT NULL,
  score      INTEGER NOT NULL DEFAULT 0,
  section    TEXT NOT NULL DEFAULT '',
  members    TEXT NOT NULL DEFAULT '',   -- '||'-separated names
  is_active  BOOLEAN NOT NULL DEFAULT false,
  updated_at TIMESTAMPTZ DEFAULT now()
);

-- Enable realtime for teams
ALTER PUBLICATION supabase_realtime ADD TABLE teams;

-- ── Game sessions ─────────────────────────────────────────────
CREATE TABLE IF NOT EXISTS game_sessions (
  id                TEXT PRIMARY KEY,
  room_id           TEXT NOT NULL DEFAULT 'main',  -- e.g. 'room1', 'room2', 'room3'
  section           TEXT NOT NULL DEFAULT '',
  status            TEXT NOT NULL DEFAULT 'idle',  -- idle | active | paused | ended
  current_round     INTEGER NOT NULL DEFAULT 1,
  current_question_index INTEGER NOT NULL DEFAULT 0,
  buzzed_team_id    TEXT REFERENCES teams(id),
  timer_remaining   INTEGER NOT NULL DEFAULT 0,
  started_at        TIMESTAMPTZ DEFAULT now(),
  updated_at        TIMESTAMPTZ DEFAULT now()
);

ALTER PUBLICATION supabase_realtime ADD TABLE game_sessions;

-- ── Game events (buzzer events, score changes) ────────────────
CREATE TABLE IF NOT EXISTS game_events (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  session_id  TEXT REFERENCES game_sessions(id) ON DELETE CASCADE,
  event_type  TEXT NOT NULL,  -- 'buzz' | 'score_change' | 'next_question' | 'reset_buzzer'
  team_id     TEXT REFERENCES teams(id),
  payload     JSONB,
  created_at  TIMESTAMPTZ DEFAULT now()
);

ALTER PUBLICATION supabase_realtime ADD TABLE game_events;

-- ── Score snapshots (for scoreboard) ─────────────────────────
CREATE TABLE IF NOT EXISTS score_snapshots (
  id          BIGINT GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
  session_id  TEXT REFERENCES game_sessions(id) ON DELETE CASCADE,
  team_id     TEXT REFERENCES teams(id),
  score       INTEGER NOT NULL,
  snapshotted_at TIMESTAMPTZ DEFAULT now()
);

-- ── Row level security (allow all from anon for now) ──────────
ALTER TABLE teams           ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_sessions   ENABLE ROW LEVEL SECURITY;
ALTER TABLE game_events     ENABLE ROW LEVEL SECURITY;
ALTER TABLE score_snapshots ENABLE ROW LEVEL SECURITY;

CREATE POLICY "allow_all_teams"           ON teams           FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_game_sessions"   ON game_sessions   FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_game_events"     ON game_events     FOR ALL USING (true) WITH CHECK (true);
CREATE POLICY "allow_all_score_snapshots" ON score_snapshots FOR ALL USING (true) WITH CHECK (true);
