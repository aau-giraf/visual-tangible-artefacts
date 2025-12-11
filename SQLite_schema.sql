CREATE TABLE user (
  id TEXT PRIMARY KEY,
  name TEXT,
  username TEXT,
  name_visible INTEGER NOT NULL,
  field_count INTEGER NOT NULL,
  modified_date INTEGER,           -- unix timestamp (nullable)
  is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE category (
  category_id TEXT PRIMARY KEY,
  category_index INTEGER,
  user_id TEXT NOT NULL,
  name TEXT,
  image_path TEXT,
  modified_date INTEGER,
  usage_count INTEGER NOT NULL DEFAULT 0,
  last_used_date INTEGER,
  is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE artefact (
  artefact_id TEXT PRIMARY KEY,
  artefact_index INTEGER NOT NULL,
  user_id TEXT NOT NULL,
  category_id TEXT,
  image_path TEXT,
  sound_path TEXT,
  modified_date INTEGER,
  name TEXT,
  name_shown INTEGER NOT NULL,
  is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE saved_board (
  id TEXT PRIMARY KEY,
  name TEXT NOT NULL,
  user_id TEXT NOT NULL,
  saved_artefact_ids TEXT,   -- JSON as TEXT
  artefact_ids TEXT,
  snapshot_path TEXT,
  created_date INTEGER NOT NULL,
  modified_date INTEGER,
  is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE saved_artefact (
  id TEXT PRIMARY KEY,
  artefact_id TEXT NOT NULL,
  board_id TEXT NOT NULL,
  pos_x REAL NOT NULL DEFAULT 0,
  pos_y REAL NOT NULL DEFAULT 0,
  width REAL NOT NULL DEFAULT 200,
  height REAL NOT NULL DEFAULT 200,
  created_date INTEGER NOT NULL,
  modified_date INTEGER,
  name_visible INTEGER,
  is_deleted INTEGER NOT NULL DEFAULT 0
);

CREATE TABLE session_meta (
  id INTEGER PRIMARY KEY AUTOINCREMENT,
  session_id TEXT,
  board_id TEXT NOT NULL,
  user_id TEXT NOT NULL,
  started_at INTEGER NOT NULL,    -- unix timestamp
  last_synced_at INTEGER,
  is_dirty INTEGER NOT NULL       -- 0/1, “has unsynced changes”
);
