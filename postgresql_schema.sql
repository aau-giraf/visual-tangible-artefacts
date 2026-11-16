-- Postgresql schema for VTA (utf8mb4_0900_ai_ci)
-- Creates database and tables: local_user, local_image, UserSettings, board, artefact, artefact-board, 
-- Safe to run multiple times if the DB doesn't already exist (will error if it does)
-- Adjust the database name if needed.

-- Make sure the session uses the desired charset/collation
-- SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET client_encoding = 'UTF8';

CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Create a foreign server to connect to the dummy_core database
CREATE SERVER IF NOT EXISTS foreign_server
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'dbDummyCore', port '5432', dbname 'dummy_core_offline');

-- Create a user mapping for the current user to connect to the foreign server
CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER
  SERVER foreign_server
  OPTIONS (user 'dummy_core_user', password 'dummy_core_password');

-- Foreign table for users (data lives in dummy_core)
CREATE FOREIGN TABLE "user" (
  "id" INTEGER NOT NULL
)
SERVER foreign_server
OPTIONS (schema_name 'public', table_name 'user');

-- Foreign table for images (data lives in dummy_core)
CREATE FOREIGN TABLE "image" (
  "id" INTEGER NOT NULL
)
SERVER foreign_server
OPTIONS (schema_name 'public', table_name 'image');

CREATE SEQUENCE "board_id_seq" AS INTEGER START WITH 1;

-- Local user table to store user IDs from the foreign "user" table
CREATE TABLE "local_user" ("id" INTEGER PRIMARY KEY);

-- Local image table to store image IDs from the foreign "image" table
CREATE TABLE "local_image" ("id" INTEGER PRIMARY KEY);

-- User settings
CREATE TABLE "userSettings" (
  "userId"      INT         NOT NULL,
  "contrast"    BOOLEAN     NOT NULL DEFAULT false,
  "lightmode"   BOOLEAN     NOT NULL DEFAULT true,
  "darkmode"    BOOLEAN     NOT NULL DEFAULT false,
  "language"    VARCHAR(10) NOT NULL DEFAULT 'dk',
  "sentenceBar" BOOLEAN     NOT NULL DEFAULT false,
  FOREIGN KEY ("userId") REFERENCES "local_user" ("id") ON DELETE CASCADE
);

-- Board
CREATE TABLE "board" (
  "id"     INT          NOT NULL DEFAULT nextval('board_id_seq'),
  "userId" INT          NOT NULL,
  "name"   VARCHAR(255) NOT NULL,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("userId") REFERENCES "local_user" ("id") ON DELETE CASCADE
);

-- Artefact
CREATE TABLE "artefact" (
  "imageId"  INT NOT NULL,
  "useCount" INT NOT NULL DEFAULT 0,
  FOREIGN KEY ("imageId") REFERENCES "local_image" ("id") ON DELETE CASCADE
);

-- Artefact-board
CREATE TABLE "artefact-board" (
  "boardId" INT   NOT NULL,
  "imageId" INT   NOT NULL,
  "posX"    FLOAT NOT NULL,
  "posY"    FLOAT NOT NULL,
  "gridX"   INT   NOT NULL,
  "gridY"   INT   NOT NULL,
  FOREIGN KEY ("boardId") REFERENCES "board"("id") ON DELETE CASCADE,
  FOREIGN KEY ("imageId") REFERENCES "local_image"("id") ON DELETE CASCADE
);

-- Populate the database with some initial data
INSERT INTO "local_user" SELECT "id" FROM "user" ON CONFLICT DO NOTHING;
INSERT INTO "local_image" SELECT "id" FROM "image" ON CONFLICT DO NOTHING;
INSERT INTO "userSettings" ("userId") VALUES
  ((SELECT "id" FROM "local_user")) ON CONFLICT DO NOTHING;
INSERT INTO "board" ("id", "userId", "name") VALUES
  (1, (SELECT "id" FROM "local_user"), 'Goat') ON CONFLICT DO NOTHING;
INSERT into "artefact" ("imageId") VALUES
  ((SELECT "id" FROM "local_image")) ON CONFLICT DO NOTHING;
INSERT into "artefact-board" ("boardId", "imageId", "posX", "posY", "gridX", "gridY") VALUES
  ((SELECT "id" FROM "board"), (SELECT "id" FROM "local_image"), 34.1, 19.23, 2, 1) ON CONFLICT DO NOTHING;