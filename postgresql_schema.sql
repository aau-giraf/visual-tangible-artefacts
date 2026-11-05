-- Postgresql schema for VTA (utf8mb4_0900_ai_ci)
-- Creates database and tables: user, category, artefact, savedBoard, savedArtefact
-- Safe to run multiple times if the DB doesn't already exist (will error if it does)
-- Adjust the database name if needed.

--Connect using \c dev_vta in psql;

-- Make sure the session uses the desired charset/collation
-- SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
CREATE DATABASE dev_vta
SET client_encoding = 'UTF8';


CREATE EXTENSION IF NOT EXISTS "postgres_fdw";

-- Create a foreign server to connect to the remote database
CREATE SERVER IF NOT EXISTS foreign_server
  FOREIGN DATA WRAPPER postgres_fdw
  OPTIONS (host 'localhost', dbname 'dev_vta', port '5432');

CREATE FOREIGN TABLE IF NOT EXISTS "user" (
  "id" INT NOT NULL,
  "firstName" VARCHAR(255) NOT NULL,
  "lastName" VARCHAR(255) NOT NULL,
  "username" VARCHAR(255) NOT NULL UNIQUE,
  "password" VARCHAR(255) NOT NULL,
  PRIMARY KEY ("id")
)
SERVER foreign_server

CREATE FOREIGN TABLE IF NOT EXISTS "image" (
  
)



-- User settings
CREATE TABLE "UserSettings" (
  "userid" int NOT NULL,
  "contrast" boolean NOT NULL DEFAULT false,
  "lightmode" boolean NOT NULL DEFAULT true,
  "darkmode" boolean NOT NULL DEFAULT false,
  "langauge" varchar(10) NOT NULL DEFAULT 'dk',
  "sentenceBar" boolean NOT NULL DEFAULT false,
);

-- board table
CREATE TABLE "board" (
  "id" INT NOT NULL,
  "usernid" INT NOT NULL,
  "name" VARCHAR(255) NOT NULL,
  PRIMARY KEY ("id")
)

-- artefact-board table
CREATE TABLE "artefact-board"(
  "boardid" INT NOT NULL,
  "imageid" INT NOT NULL,
  "posX" FLOAT NOT NULL,
  "posY" FLOAT NOT NULL,
  "gridX" INT NOT NULL,
  "gridY" INT NOT NULL,
  PRIMARY KEY ("boardid") references "board"("id") ON DELETE CASCADE,

)

-- artefact table
CREATE TABLE "artefact" (
  "imageid" INT NOT NULL,
  "useCount" INT NOT NULL DEFAULT 0,
)