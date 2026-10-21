-- MySQL 8.0+ schema for VTA (utf8mb4_0900_ai_ci)
-- Creates database and tables: user, category, artefact, savedBoard, savedArtefact
-- Safe to run multiple times if the DB doesn't already exist (will error if it does)
-- Adjust the database name if needed.

--Connect using \c dev_vta in psql;

-- Make sure the session uses the desired charset/collation
-- SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET client_encoding = 'UTF8';

-- Drop in dependency order (savedArtefact -> savedBoard -> artefact -> category/user)
DROP TABLE IF EXISTS "savedArtefact";
DROP TABLE IF EXISTS "savedBoard";
DROP TABLE IF EXISTS "artefact";
DROP TABLE IF EXISTS "category";
DROP TABLE IF EXISTS "user";

-- USER
CREATE TABLE "user" (
  id              VARCHAR(36)   NOT NULL,
  name            VARCHAR(50)   NULL,
  password        VARCHAR(255)  NOT NULL,
  "guardianKey"   VARCHAR(255)  NULL,
  username        VARCHAR(50)   NOT NULL,
  "nameVisible"   SMALLINT      NOT NULL DEFAULT 0,
  "fieldCount"    INTEGER       NOT NULL DEFAULT 4,
  PRIMARY KEY (id)
); 

-- Insert a system user and a default "Session-Artefact" category if they don't already exist.
INSERT INTO "user" (id, name, password, "guardianKey", username, "nameVisible", "fieldCount")
VALUES ('system', 'System', '', NULL, 'system', 0, 4)
ON CONFLICT (id) DO NOTHING;

-- CATEGORY
CREATE TABLE category (
  "categoryId"      VARCHAR(36)   NOT NULL,
  "categoryIndex"   SMALLINT      CHECK ("categoryIndex"  BETWEEN 0 AND 255),
  "userId"          VARCHAR(36)   NOT NULL,
   name             VARCHAR(50)   NULL,
  "imagePath"       VARCHAR(255)  NULL,
  "modifiedDate"    TIMESTAMP     NULL,
  "usageCount"      INTEGER       NOT NULL DEFAULT 0,
  "lastUsedDate"    TIMESTAMP     NULL,
  PRIMARY KEY ("categoryId"),
  CONSTRAINT category_ibfk_1
    FOREIGN KEY ("userId") REFERENCES "user"(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
); 
  CREATE INDEX IF NOT EXISTS idx_artefact_userId ON category("userId"); 

INSERT INTO category ("categoryId", "categoryIndex", "userId", name, "imagePath", "modifiedDate", "usageCount", "lastUsedDate")
VALUES ('Session-Artefact', 0, 'system', 'Session Artefacts', NULL, NOW(), 0, NULL)
ON CONFLICT ("categoryId") DO NOTHING;

-- ARTEFACT
CREATE TABLE artefact (
  "artefactId"      VARCHAR(36)   NOT NULL,
  "artefactIndex"   INTEGER       CHECK ("artefactIndex" BETWEEN 0 AND 65535),
  "userID"          VARCHAR(36)   NOT NULL,
  "categoryId"      VARCHAR(36)   NULL,
  "imagePath"       VARCHAR(255)  NULL,
  "soundPath"       VARCHAR(255)  NULL,
  "modifiedDate"    TIMESTAMP     NULL,
   name             VARCHAR(255)  NULL,
  "nameShown"      	SMALLINT      NOT NULL DEFAULT 0,
  PRIMARY KEY ("artefactId"),
  CONSTRAINT artefact_ibfk_2
    FOREIGN KEY ("categoryId") REFERENCES category("categoryId")
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT artefact_ibfk_1
    FOREIGN KEY ("userID") REFERENCES "user"(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
); 
  CREATE INDEX IF NOT EXISTS idx_artefact_categoryid ON artefact("categoryId");
  CREATE INDEX IF NOT EXISTS idx_artefact_userid ON artefact("userID");

-- SAVED BOARD
CREATE TABLE "savedBoard" (
  id                      VARCHAR(36)   NOT NULL,
  name                    VARCHAR(255)  NOT NULL,
  "userId"                VARCHAR(36)   NOT NULL,
  "savedArtefactIds" JSONB, 
  "artefactIds"      JSONB,
  "snapshotPath"          VARCHAR(255)  NULL,
  "createdDate"           TIMESTAMP     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "modifiedDate"          TIMESTAMP     NULL,
  PRIMARY KEY (id),
  CONSTRAINT savedBoard_ibfk_1
  FOREIGN KEY ("userId") REFERENCES "user"(id)
  ON DELETE CASCADE
  ON UPDATE CASCADE
); 
  CREATE INDEX IF NOT EXISTS idx_savedBoard_userid ON "savedBoard" ("userId");

-- SAVED ARTEFACT
CREATE TABLE "savedArtefact" (
  id            VARCHAR(36)    NOT NULL,
  "artefactId"  VARCHAR(36)    NOT NULL,
  "boardId"     VARCHAR(36)    NOT NULL,
  "posX"        REAL           NOT NULL DEFAULT 0,
  "posY"        REAL           NOT NULL DEFAULT 0,
  width         REAL           NOT NULL DEFAULT 200,
  height        REAL           NOT NULL DEFAULT 200,
  "createdDate" TIMESTAMP      NOT NULL DEFAULT CURRENT_TIMESTAMP,
  "nameVisible" SMALLINT       NULL DEFAULT NULL,
  PRIMARY KEY (id),
  CONSTRAINT savedArtefact_ibfk_1
    FOREIGN KEY ("artefactId") REFERENCES artefact("artefactId")
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT savedArtefact_ibfk_2
    FOREIGN KEY ("boardId") REFERENCES "savedBoard"(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
); 
  CREATE INDEX IF NOT EXISTS idx_savedArtefact_artefactid ON "savedArtefact" ("artefactId");
  CREATE INDEX IF NOT EXISTS idx_savedArtefact_boardid ON "savedArtefact" ("boardId");

-- Username is frequently used for login lookups
CREATE INDEX IF NOT EXISTS idx_user_username ON "user"(username);

-- Category queries often filter by userId and order by categoryIndex
CREATE INDEX IF NOT EXISTS idx_category_userid_index ON category("userId", "categoryIndex");

-- Artefact queries often filter by userId and categoryId together
CREATE INDEX IF NOT EXISTS idx_artefact_userid_categoryid ON artefact("userID", "categoryId");

-- Artefact index is used for ordering
CREATE INDEX IF NOT EXISTS idx_artefact_index ON artefact("artefactIndex");