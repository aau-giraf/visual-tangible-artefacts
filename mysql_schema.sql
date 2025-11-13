-- MySQL 8.0+ schema for VTA (utf8mb4_0900_ai_ci)
-- Creates database and tables: user, category, artefact, savedBoard, savedArtefact
-- Safe to run multiple times if the DB doesn't already exist (will error if it does)
-- Adjust the database name if needed.

CREATE DATABASE IF NOT EXISTS dev_vta
  /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */;
USE dev_vta;

-- Make sure the session uses the desired charset/collation
SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- Drop in dependency order (savedArtefact -> savedBoard -> artefact -> category/user)
DROP TABLE IF EXISTS savedArtefact;
DROP TABLE IF EXISTS savedBoard;
DROP TABLE IF EXISTS artefact;
DROP TABLE IF EXISTS category;
DROP TABLE IF EXISTS user;

-- USER
CREATE TABLE user (
  id           VARCHAR(36)  NOT NULL,
  name         VARCHAR(50)  NULL,
  password     VARCHAR(255) NOT NULL,
  guardianKey  VARCHAR(255) NULL,
  username     VARCHAR(50)  NOT NULL,
  PRIMARY KEY (id)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

-- CATEGORY
CREATE TABLE category (
  categoryId     VARCHAR(36)  NOT NULL,
  categoryIndex  TINYINT UNSIGNED NULL,
  userId         VARCHAR(36)  NOT NULL,
  name           VARCHAR(50)  NULL,
  imagePath      VARCHAR(255) NULL,
  modifiedDate   DATETIME NULL,
  usageCount     INT NOT NULL DEFAULT 0,
  lastUsedDate   DATETIME NULL,
  PRIMARY KEY (categoryId),
  KEY userId (userId),
  CONSTRAINT category_ibfk_1
    FOREIGN KEY (userId) REFERENCES user(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

-- ARTEFACT
CREATE TABLE artefact (
  artefactId     VARCHAR(36)   NOT NULL,
  artefactIndex  SMALLINT UNSIGNED NOT NULL,
  userID         VARCHAR(36)   NOT NULL,
  categoryId     VARCHAR(36)   NULL,
  imagePath      VARCHAR(255)  NULL,
  soundPath      VARCHAR(255)  NULL,
  modifiedDate   DATETIME      NULL,
  name           VARCHAR(255)  NULL,
  nameShown     TINYINT(1)    NOT NULL DEFAULT 0,
  PRIMARY KEY (artefactId),
  KEY categoryId (categoryId),
  KEY userId (userID),
  CONSTRAINT artefact_ibfk_2
    FOREIGN KEY (categoryId) REFERENCES category(categoryId)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT artefact_ibfk_1
    FOREIGN KEY (userID) REFERENCES user(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

-- SAVED BOARD
CREATE TABLE savedBoard (
  id               VARCHAR(36)  NOT NULL,
  name             VARCHAR(255) NOT NULL,
  userId           VARCHAR(36)  NOT NULL,
  savedArtefactId  VARCHAR(36)  NULL,
  snapshotPath     VARCHAR(255) NULL,
  createdDate      DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  modifiedDate     DATETIME     NULL,
  PRIMARY KEY (id),
  KEY userId (userId),
  CONSTRAINT savedBoard_ibfk_1
    FOREIGN KEY (userId) REFERENCES user(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE
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
  createdDate DATETIME     NOT NULL DEFAULT CURRENT_TIMESTAMP,
  PRIMARY KEY (id),
  KEY artefactId (artefactId),
  KEY boardId (boardId),
  CONSTRAINT savedArtefact_ibfk_1
    FOREIGN KEY (artefactId) REFERENCES artefact(artefactId)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  CONSTRAINT savedArtefact_ibfk_2
    FOREIGN KEY (boardId) REFERENCES savedBoard(id)
    ON DELETE CASCADE
    ON UPDATE CASCADE,
  UNIQUE KEY unique_artefact_board (artefactId, boardId)
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;

-- Add foreign key constraint from savedBoard to savedArtefact
-- (done after savedArtefact table is created to avoid circular dependency)
ALTER TABLE savedBoard
  ADD CONSTRAINT savedBoard_ibfk_2
    FOREIGN KEY (savedArtefactId) REFERENCES savedArtefact(id)
    ON DELETE SET NULL
    ON UPDATE CASCADE;

-- Performance Indexes
-- Username is frequently used for login lookups
CREATE INDEX idx_user_username ON user(username);

-- Category queries often filter by userId and order by categoryIndex
CREATE INDEX idx_category_userid_index ON category(userId, categoryIndex);

-- Artefact queries often filter by userId and categoryId together
CREATE INDEX idx_artefact_userid_categoryid ON artefact(userID, categoryId);

-- Artefact index is used for ordering
CREATE INDEX idx_artefact_index ON artefact(artefactIndex);
