-- Postgresql schema for VTA (utf8mb4_0900_ai_ci)
-- Creates database and tables: user, category, artefact, savedBoard, savedArtefact
-- Safe to run multiple times if the DB doesn't already exist (will error if it does)
-- Adjust the database name if needed.

-- Make sure the session uses the desired charset/collation
-- SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET client_encoding = 'UTF8';

CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Connection to the dummy_core container
CREATE SERVER IF NOT EXISTS foreign_server
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'dbDummyCore', port '5432', dbname 'dummy_core_offline');

CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER
  SERVER foreign_server
  OPTIONS (user 'dummy_core_user', password 'dummy_core_password');

-- Foreign tables (data lives in dummy_core)
CREATE FOREIGN TABLE "user" (
  "Id" INTEGER NOT NULL
)
SERVER foreign_server
OPTIONS (schema_name 'public', table_name 'user');

CREATE FOREIGN TABLE "image" (
  "Id" INTEGER NOT NULL
)
SERVER foreign_server
OPTIONS (schema_name 'public', table_name 'image');

CREATE TABLE "local_user" (id INTEGER PRIMARY KEY);
CREATE TABLE "local_image" (id INTEGER PRIMARY KEY);

-- User settings (no FK: "user" is a foreign table)
CREATE TABLE "UserSettings" (
  "userid"      INT         NOT NULL,
  "contrast"    BOOLEAN     NOT NULL DEFAULT false,
  "lightmode"   BOOLEAN     NOT NULL DEFAULT true,
  "darkmode"    BOOLEAN     NOT NULL DEFAULT false,
  "language"    VARCHAR(10) NOT NULL DEFAULT 'dk',
  "sentenceBar" BOOLEAN     NOT NULL DEFAULT false,
  fOREIGN KEY ("userid") REFERENCES "local_user" ("id") ON DELETE CASCADE
);

-- Board
CREATE TABLE "board" (
  "id"     INT          NOT NULL,
  "userid" INT          NOT NULL,
  "name"   VARCHAR(255) NOT NULL,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("userid") REFERENCES "local_user" ("id") ON DELETE CASCADE
);

-- Artefact
CREATE TABLE "artefact" (
  "imageid"  INT NOT NULL,
  "useCount" INT NOT NULL DEFAULT 0,
  FOREIGN KEY ("imageid") REFERENCES "local_image" ("id") ON DELETE CASCADE
);

-- Artefact-board
CREATE TABLE "artefact-board" (
  "boardid" INT   NOT NULL,
  "imageid" INT   NOT NULL,
  "posX"    FLOAT NOT NULL,
  "posY"    FLOAT NOT NULL,
  "gridX"   INT   NOT NULL,
  "gridY"   INT   NOT NULL,
  FOREIGN KEY ("boardid") REFERENCES "board"("id") ON DELETE CASCADE,
  FOREIGN KEY ("imageid") REFERENCES "local_image"("id") ON DELETE CASCADE
);



INSERT INTO "local_user" SELECT "Id" FROM "user" ON CONFLICT DO NOTHING;
INSERT INTO "local_image" SELECT "Id" FROM "image" ON CONFLICT DO NOTHING;
INSERT INTO "UserSettings" ("userid") VALUES
  (SELECT "Id" FROM "user" ON CONFLICT DO NOTHING);
INSERT INTO "board" ("id", "userid", "name") VALUES
  (1, (SELECT "Id" FROM "user"), 'Goat') ON CONFLICT DO NOTHING;
INSERT into "artefact" ("imageid") VALUES
  (SELECT "Id" FROM "image" ON CONFLICT DO NOTHING);
INSERT into "artefact-board" ("boardid", "imageid", "posX", "posY", "gridX", "gridY") VALUES
  ((SELECT "Id" FROM "board"), (SELECT "Id" FROM "image"), 0.0, 0.0, 0, 0) ON CONFLICT DO NOTHING;
