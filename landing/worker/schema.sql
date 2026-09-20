-- Event store for Izzy's own analytics. One row per event.
--
-- What is deliberately absent: IP addresses, user agents, anything a person typed,
-- and any identifier that outlives an uninstall. `install` is a UUID the app makes
-- on first launch and keeps in its own storage, so reinstalling produces a new one
-- and nothing here points back at a person.
CREATE TABLE IF NOT EXISTS events (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  install TEXT NOT NULL,
  name TEXT NOT NULL,
  at INTEGER NOT NULL,          -- unix seconds, from the device clock
  received_at INTEGER NOT NULL, -- unix seconds, from the worker
  app TEXT,                     -- "1.0.0 (24)"
  os TEXT,                      -- "18.0"
  device TEXT,                  -- "iPhone" or "iPad"
  lang TEXT,                    -- interface language, "ja" or "en"
  props TEXT                    -- JSON object, string values only
);

-- Retention and daily use read by install and day; everything else reads by name.
CREATE INDEX IF NOT EXISTS events_install_at ON events (install, at);
CREATE INDEX IF NOT EXISTS events_name_at ON events (name, at);
