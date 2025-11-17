-- Manual Migration: Add User Hierarchy and Relations
-- Date: 2025-11-17
-- This script adds the necessary columns and tables for the User hierarchy (TPH) and Relation entities

USE vta_dev;

-- ============================================================
-- STEP 1: Modify existing 'user' table (IF NOT EXISTS)
-- ============================================================

-- Add new columns to user table (only if they don't exist)
SET @preparedStatement = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = 'vta_dev'
     AND TABLE_NAME = 'user'
     AND COLUMN_NAME = 'firstName') = 0,
    'ALTER TABLE `user` ADD COLUMN `firstName` VARCHAR(100) NULL AFTER `password`',
    'SELECT ''firstName already exists'' AS message'
));
PREPARE stmt FROM @preparedStatement;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @preparedStatement = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = 'vta_dev'
     AND TABLE_NAME = 'user'
     AND COLUMN_NAME = 'lastName') = 0,
    'ALTER TABLE `user` ADD COLUMN `lastName` VARCHAR(100) NULL AFTER `firstName`',
    'SELECT ''lastName already exists'' AS message'
));
PREPARE stmt FROM @preparedStatement;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @preparedStatement = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = 'vta_dev'
     AND TABLE_NAME = 'user'
     AND COLUMN_NAME = 'role') = 0,
    'ALTER TABLE `user` ADD COLUMN `role` INT NOT NULL DEFAULT 1 COMMENT ''UserRole: 0=Admin, 1=Caregiver, 2=Child'' AFTER `lastName`',
    'SELECT ''role already exists'' AS message'
));
PREPARE stmt FROM @preparedStatement;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @preparedStatement = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = 'vta_dev'
     AND TABLE_NAME = 'user'
     AND COLUMN_NAME = 'UserType') = 0,
    'ALTER TABLE `user` ADD COLUMN `UserType` VARCHAR(13) NOT NULL DEFAULT ''Caregiver'' COMMENT ''Discriminator for TPH: User, Admin, Caregiver, Child'' AFTER `username`',
    'SELECT ''UserType already exists'' AS message'
));
PREPARE stmt FROM @preparedStatement;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

SET @preparedStatement = (SELECT IF(
    (SELECT COUNT(*) FROM INFORMATION_SCHEMA.COLUMNS
     WHERE TABLE_SCHEMA = 'vta_dev'
     AND TABLE_NAME = 'user'
     AND COLUMN_NAME = 'relationType') = 0,
    'ALTER TABLE `user` ADD COLUMN `relationType` INT NULL COMMENT ''RelationType for Caregiver: 0=Caregiver, 1=Guardian, 2=Parent'' AFTER `UserType`',
    'SELECT ''relationType already exists'' AS message'
));
PREPARE stmt FROM @preparedStatement;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- ============================================================
-- STEP 2: Create 'relation' table (IF NOT EXISTS)
-- ============================================================

CREATE TABLE IF NOT EXISTS `relation` (
    `relationId` VARCHAR(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
    `studentId` VARCHAR(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
    `relativeId` VARCHAR(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
    `relationType` INT NOT NULL COMMENT '0=Caregiver, 1=Guardian, 2=Parent',
    `status` INT NOT NULL COMMENT '0=Pending, 1=Active, 2=Inactive, 3=Rejected',
    `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `updatedAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP,
    CONSTRAINT `PRIMARY` PRIMARY KEY (`relationId`),
    INDEX `studentId` (`studentId`),
    INDEX `relativeId` (`relativeId`),
    CONSTRAINT `relation_ibfk_student` FOREIGN KEY (`studentId`) REFERENCES `user` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `relation_ibfk_relative` FOREIGN KEY (`relativeId`) REFERENCES `user` (`id`) ON DELETE RESTRICT
) CHARACTER SET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- STEP 3: Create 'invite' table (IF NOT EXISTS)
-- ============================================================

CREATE TABLE IF NOT EXISTS `invite` (
    `inviteId` INT NOT NULL AUTO_INCREMENT,
    `createdAt` DATETIME NOT NULL DEFAULT CURRENT_TIMESTAMP,
    `expiresAt` DATETIME NOT NULL,
    `createdBy` VARCHAR(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
    `relationId` VARCHAR(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
    `status` INT NOT NULL COMMENT '0=Pending, 1=Accepted, 2=Declined',
    CONSTRAINT `PRIMARY` PRIMARY KEY (`inviteId`),
    INDEX `createdBy` (`createdBy`),
    INDEX `relationId` (`relationId`),
    CONSTRAINT `invite_ibfk_user` FOREIGN KEY (`createdBy`) REFERENCES `user` (`id`) ON DELETE RESTRICT,
    CONSTRAINT `invite_ibfk_relation` FOREIGN KEY (`relationId`) REFERENCES `relation` (`relationId`) ON DELETE CASCADE
) CHARACTER SET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- STEP 4: Create 'session' table (IF NOT EXISTS)
-- ============================================================

CREATE TABLE IF NOT EXISTS `session` (
    `id` VARCHAR(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
    `inviteId` INT NULL,
    `relationId` VARCHAR(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NOT NULL,
    `boardId` VARCHAR(36) CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci NULL,
    `status` INT NOT NULL COMMENT '0=Active, 1=Completed, 2=Cancelled',
    CONSTRAINT `PRIMARY` PRIMARY KEY (`id`),
    UNIQUE INDEX `inviteId` (`inviteId`),
    INDEX `relationId` (`relationId`),
    INDEX `boardId` (`boardId`),
    CONSTRAINT `session_ibfk_invite` FOREIGN KEY (`inviteId`) REFERENCES `invite` (`inviteId`) ON DELETE CASCADE,
    CONSTRAINT `session_ibfk_relation` FOREIGN KEY (`relationId`) REFERENCES `relation` (`relationId`) ON DELETE RESTRICT
    -- Note: boardId foreign key constraint skipped until SavedBoard functionality is complete
    -- CONSTRAINT `session_ibfk_board` FOREIGN KEY (`boardId`) REFERENCES `savedboard` (`id`) ON DELETE SET NULL
) CHARACTER SET=utf8mb4 COLLATE=utf8mb4_0900_ai_ci;

-- ============================================================
-- STEP 5: Update existing data to match new schema
-- ============================================================

-- Set default UserType for existing users based on guardianKey
UPDATE `user` 
SET `UserType` = CASE 
    WHEN `guardianKey` IS NOT NULL AND `guardianKey` != '' THEN 'Caregiver'
    ELSE 'Child'
END
WHERE `UserType` = 'Caregiver';

-- Update role based on UserType
UPDATE `user` 
SET `role` = CASE 
    WHEN `UserType` = 'Admin' THEN 0
    WHEN `UserType` = 'Caregiver' THEN 1
    WHEN `UserType` = 'Child' THEN 2
    ELSE 1
END;

-- Migrate name to firstName for existing users
UPDATE `user` 
SET `firstName` = `name`
WHERE `name` IS NOT NULL AND `firstName` IS NULL;

-- ============================================================
-- STEP 6: Record migration in __EFMigrationsHistory
-- ============================================================

-- Check if migrations table exists, create if not
CREATE TABLE IF NOT EXISTS `__EFMigrationsHistory` (
    `MigrationId` VARCHAR(150) CHARACTER SET utf8mb4 NOT NULL,
    `ProductVersion` VARCHAR(32) CHARACTER SET utf8mb4 NOT NULL,
    CONSTRAINT `PK___EFMigrationsHistory` PRIMARY KEY (`MigrationId`)
) CHARACTER SET=utf8mb4;

-- Insert migration record (ignore if already exists)
INSERT IGNORE INTO `__EFMigrationsHistory` (`MigrationId`, `ProductVersion`)
VALUES ('20251117122419_AddUserHierarchyAndRelations', '8.0.0');

-- ============================================================
-- SUCCESS MESSAGE
-- ============================================================

SELECT 'Migration completed successfully!' AS Status;
