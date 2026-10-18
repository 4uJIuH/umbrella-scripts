CREATE TABLE IF NOT EXISTS votes (
  steam_id TEXT NOT NULL,
  script_id TEXT NOT NULL,
  vote INTEGER NOT NULL CHECK (vote IN (-1, 1)),
  updated INTEGER NOT NULL,
  PRIMARY KEY (steam_id, script_id)
);
CREATE INDEX IF NOT EXISTS votes_script ON votes (script_id);
CREATE TABLE IF NOT EXISTS feedback (
  steam_id TEXT NOT NULL,
  script_id TEXT NOT NULL,
  ip TEXT NOT NULL,
  created INTEGER NOT NULL
);
CREATE INDEX IF NOT EXISTS feedback_user ON feedback (steam_id, created);
CREATE INDEX IF NOT EXISTS feedback_ip ON feedback (ip, created);
