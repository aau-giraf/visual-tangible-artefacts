-- MySQL 8.0+ schema for VTA (utf8mb4_0900_ai_ci)
-- Creates database and tables: user_settings, category, artefact, savedBoard, savedArtefact, sessions
-- Users are managed by giraf-core; VTA only stores user settings and domain data.

CREATE DATABASE IF NOT EXISTS dev_vta
  /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */;
USE dev_vta;

SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- Drop in dependency order
DROP TABLE IF EXISTS savedArtefact;
DROP TABLE IF EXISTS savedBoard;
DROP TABLE IF EXISTS artefact;
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS sessions;
DROP TABLE IF EXISTS user_settings;

-- USER SETTINGS (VTA-specific preferences, keyed by Core user ID)
CREATE TABLE user_settings (
  user_id      INT          NOT NULL,
  name_visible TINYINT(1)   NOT NULL DEFAULT 0,
  field_count  INT          NOT NULL DEFAULT 4,
  PRIMARY KEY (user_id)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

-- CATEGORY
CREATE TABLE category (
  categoryId     VARCHAR(36)  NOT NULL,
  categoryIndex  TINYINT UNSIGNED NULL,
  userId         INT          NOT NULL,
  name           VARCHAR(50)  NULL,
  imagePath      VARCHAR(255) NULL,
  modifiedDate   DATETIME NULL,
  usageCount     INT NOT NULL DEFAULT 0,
  lastUsedDate   DATETIME NULL,
  PRIMARY KEY (categoryId),
  KEY userId (userId)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

-- ARTEFACT
CREATE TABLE artefact (
  artefactId     VARCHAR(36)   NOT NULL,
  artefactIndex  SMALLINT UNSIGNED NOT NULL,
  userID         INT           NOT NULL,
  categoryId     VARCHAR(36)   NULL,
  imagePath      VARCHAR(255)  NULL,
  soundPath      VARCHAR(255)  NULL,
  modifiedDate   DATETIME      NULL,
  name           VARCHAR(255)  NULL,
  nameShown      TINYINT(1)    NOT NULL DEFAULT 0,
  PRIMARY KEY (artefactId),
  KEY categoryId (categoryId),
  KEY userId (userID),
  CONSTRAINT artefact_ibfk_2
    FOREIGN KEY (categoryId) REFERENCES category(categoryId)
    ON DELETE RESTRICT
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

-- SAVED BOARD
CREATE TABLE savedBoard (
  id               VARCHAR(36)  NOT NULL,
  name             VARCHAR(255) NOT NULL,
  userId           INT          NOT NULL,
  savedArtefactIds JSON         NULL,
  artefactIds      JSON         NULL,
  snapshotPath     VARCHAR(255) NULL,
  createdDate      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modifiedDate     DATETIME     NULL,
  PRIMARY KEY (id),
  KEY userId (userId)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

-- SAVED ARTEFACT
CREATE TABLE savedArtefact (
  id          VARCHAR(36)  NOT NULL,
  artefactId  VARCHAR(36)  NOT NULL,
  boardId     VARCHAR(36)  NOT NULL,
  posX        FLOAT        NOT NULL DEFAULT 0,
  posY        FLOAT        NOT NULL DEFAULT 0,
  width       FLOAT        NOT NULL DEFAULT 200,
  height      FLOAT        NOT NULL DEFAULT 200,
  createdDate DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  nameVisible TINYINT(1)   NULL DEFAULT NULL,
  PRIMARY KEY (id),
  KEY artefactId (artefactId),
  KEY boardId (boardId),
  CONSTRAINT savedArtefact_ibfk_1
    FOREIGN KEY (artefactId) REFERENCES artefact(artefactId)
    ON DELETE CASCADE,
  CONSTRAINT savedArtefact_ibfk_2
    FOREIGN KEY (boardId) REFERENCES savedBoard(id)
    ON DELETE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

-- SESSIONS (video call tracking)
CREATE TABLE sessions (
  id          INT          NOT NULL AUTO_INCREMENT,
  caller_id   INT          NOT NULL,
  callee_id   INT          NOT NULL,
  start_time  DATETIME     NULL,
  end_time    DATETIME     NULL,
  duration    TIME         NULL,
  call_status VARCHAR(20)  NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

-- Indexes
CREATE INDEX idx_category_userid_index ON category(userId, categoryIndex);
CREATE INDEX idx_artefact_userid_categoryid ON artefact(userID, categoryId);
CREATE INDEX idx_artefact_index ON artefact(artefactIndex);
