-- MySQL 8.0+ schema for VTA (utf8mb4_0900_ai_ci)
-- Creates database and tables: user, category, artefact
-- Safe to run multiple times if the DB doesn't already exist (will error if it does)
-- Adjust the database name if needed.

CREATE DATABASE IF NOT EXISTS dev_vta
  /*!40100 DEFAULT CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci */;
USE dev_vta;

-- Make sure the session uses the desired charset/collation
SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;

-- Drop in dependency order (artefact -> category/user)
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

-- Insert a system user and a default "Session-Artefact" category if they don't already exist.
-- The category needs a valid userId because of the foreign key constraint, so we create
-- a lightweight system user and then create the category referencing it.
INSERT INTO user (id, name, password, guardianKey, username)
SELECT 'system', 'System', '', NULL, 'system'
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM user WHERE id = 'system');

INSERT INTO category (categoryId, categoryIndex, userId, name, imagePath, modifiedDate, usageCount, lastUsedDate)
SELECT 'Session-Artefact', 0, 'system', 'Session Artefacts', NULL, NOW(), 0, NULL
FROM DUAL
WHERE NOT EXISTS (SELECT 1 FROM category WHERE categoryId = 'Session-Artefact');

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
    ON DELETE RESTRICT
    ON UPDATE RESTRICT
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
    ON DELETE RESTRICT
    ON UPDATE RESTRICT,
  CONSTRAINT artefact_ibfk_1
    FOREIGN KEY (userID) REFERENCES user(id)
    ON DELETE RESTRICT
    ON UPDATE RESTRICT
) ENGINE=InnoDB
  DEFAULT CHARSET=utf8mb4
  COLLATE=utf8mb4_0900_ai_ci;
