-- Migration script to add width and height columns to savedArtefact table
-- Run this on your existing database to add the new columns

USE dev_vta;

-- Check if the columns already exist before adding them
SET @sql = 'SELECT COUNT(*) INTO @col_exists FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = "savedArtefact" AND COLUMN_NAME = "width"';
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add width column if it doesn't exist
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE savedArtefact ADD COLUMN width FLOAT NOT NULL DEFAULT 200 AFTER posY', 
    'SELECT "width column already exists" as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Check if height column exists
SET @sql = 'SELECT COUNT(*) INTO @col_exists FROM INFORMATION_SCHEMA.COLUMNS 
           WHERE TABLE_SCHEMA = DATABASE() AND TABLE_NAME = "savedArtefact" AND COLUMN_NAME = "height"';
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Add height column if it doesn't exist
SET @sql = IF(@col_exists = 0, 
    'ALTER TABLE savedArtefact ADD COLUMN height FLOAT NOT NULL DEFAULT 200 AFTER width', 
    'SELECT "height column already exists" as message');
PREPARE stmt FROM @sql;
EXECUTE stmt;
DEALLOCATE PREPARE stmt;

-- Verify the changes
DESCRIBE savedArtefact;