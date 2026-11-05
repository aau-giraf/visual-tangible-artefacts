-- Postgresql schema for VTA (utf8mb4_0900_ai_ci)
-- Creates database and tables: user, category, artefact, savedBoard, savedArtefact
-- Safe to run multiple times if the DB doesn't already exist (will error if it does)
-- Adjust the database name if needed.

--Connect using \c dev_vta in psql;

-- Make sure the session uses the desired charset/collation
-- SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET client_encoding = 'UTF8';

CREATE EXTENSION IF NOT EXISTS postgres_fdw;

-- Connection to the dummy_core container
CREATE SERVER IF NOT EXISTS foreign_server
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'dbDummyCore', dbname 'dummy_core', port '5432');

CREATE USER MAPPING IF NOT EXISTS FOR CURRENT_USER
  SERVER foreign_server
  OPTIONS (user 'user1', password 'password1');

-- Foreign tables (data lives in dummy_core)
CREATE FOREIGN TABLE IF NOT EXISTS "user" (
  "id"        INT          OPTIONS (column_name 'Id')        NOT NULL,
  "firstName" VARCHAR(255) OPTIONS (column_name 'FirstName'),
  "lastName"  VARCHAR(255) OPTIONS (column_name 'LastName'),
  "username"  VARCHAR(255) OPTIONS (column_name 'UserName')  NOT NULL,
  "password"  VARCHAR(255) OPTIONS (column_name 'password')  NOT NULL
)
SERVER foreign_server
OPTIONS (schema_name 'public', table_name 'user');

CREATE FOREIGN TABLE IF NOT EXISTS "image" (
  "id"             INT          OPTIONS (column_name 'Id')             NOT NULL,
  "name"           VARCHAR(255) OPTIONS (column_name 'Name'),
  "citizenId"      INT          OPTIONS (column_name 'CitizenId')      NOT NULL,
  "path"           VARCHAR(255) OPTIONS (column_name 'Path'),
  "organizationId" INT          OPTIONS (column_name 'OrganizationId') NOT NULL,
  "storageKey"     VARCHAR(512) OPTIONS (column_name 'StorageKey')     NOT NULL,
  "fileName"       VARCHAR(255) OPTIONS (column_name 'FileName')       NOT NULL,
  "fileType"       VARCHAR(100) OPTIONS (column_name 'FileType')       NOT NULL,
  "sizeBytes"      BIGINT       OPTIONS (column_name 'SizeBytes')      NOT NULL,
  "createdAt"      TIMESTAMP WITH TIME ZONE OPTIONS (column_name 'CreatedAt')
)
SERVER foreign_server
OPTIONS (schema_name 'public', table_name 'image');

-- User settings (no FK: "user" is a foreign table)
CREATE TABLE "UserSettings" (
  "userid"      INT         NOT NULL,
  "contrast"    BOOLEAN     NOT NULL DEFAULT false,
  "lightmode"   BOOLEAN     NOT NULL DEFAULT true,
  "darkmode"    BOOLEAN     NOT NULL DEFAULT false,
  "language"    VARCHAR(10) NOT NULL DEFAULT 'dk',
  "sentenceBar" BOOLEAN     NOT NULL DEFAULT false,
  PRIMARY KEY ("userid")
);

-- Board
CREATE TABLE "board" (
  "id"     INT          NOT NULL,
  "userid" INT          NOT NULL,
  "name"   VARCHAR(255) NOT NULL,
  PRIMARY KEY ("id")
);

-- Artefact-board
CREATE TABLE "artefact-board" (
  "boardid" INT   NOT NULL,
  "imageid" INT   NOT NULL,
  "posX"    FLOAT NOT NULL,
  "posY"    FLOAT NOT NULL,
  "gridX"   INT   NOT NULL,
  "gridY"   INT   NOT NULL,
  FOREIGN KEY ("boardid") REFERENCES "board"("id") ON DELETE CASCADE
);

-- Artefact
CREATE TABLE "artefact" (
  "imageid"  INT NOT NULL,
  "useCount" INT NOT NULL DEFAULT 0,
  PRIMARY KEY ("imageid")
);