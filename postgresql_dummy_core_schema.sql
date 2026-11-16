-- Postgresql schema for Dummy Core (utf8mb4_0900_ai_ci)
-- Creates database and tables: organization, class, user, citizen, nonCitizen, guardianship, userRole, image
-- Safe to run multiple times if the DB doesn't already exist (will error if it does)
-- Adjust the database name if needed.


-- Make sure the session uses the desired charset/collation
-- SET NAMES utf8mb4 COLLATE utf8mb4_0900_ai_ci;
SET client_encoding = 'UTF8';

-- Sequences for id´s
CREATE SEQUENCE "organization_id_seq" AS INTEGER START WITH 1;
CREATE SEQUENCE "class_id_seq" AS INTEGER START WITH 1;
CREATE SEQUENCE "user_id_seq" AS INTEGER START WITH 1;
CREATE SEQUENCE "image_id_seq" AS INTEGER START WITH 1;

-- Organization
CREATE TABLE "organization" (
  "id"    INTEGER     NOT NULL DEFAULT nextval('organization_id_seq'),
  "Name"  VARCHAR(65),
  PRIMARY KEY ("id")
);

-- Class
CREATE TABLE "class" (
  "id"              INTEGER     NOT NULL DEFAULT nextval('class_id_seq'),
  "Name"            VARCHAR(65),
  "OrganizationId"  INTEGER     NOT NULL,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("OrganizationId") REFERENCES "organization" ("id") ON DELETE CASCADE
);

-- User
CREATE TABLE "user" (
  "id"         INTEGER      NOT NULL DEFAULT nextval('user_id_seq'),
  "FirstName"  VARCHAR(65),
  "LastName"   VARCHAR(65),
  "UserName"   VARCHAR(65)  NOT NULL UNIQUE,
  "password"   VARCHAR(65)  NOT NULL,
  PRIMARY KEY ("id")
);

-- Citizen
CREATE TABLE "citizen" (
  "id"       INTEGER  NOT NULL,
  "ClassId"  INTEGER  NOT NULL,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("ClassId") REFERENCES "class" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("id") REFERENCES "user" ("id") ON DELETE CASCADE
);

-- NonCitizen
CREATE TABLE "nonCitizen" (
  "id"     INTEGER      NOT NULL,
  "Email"  VARCHAR(65)  UNIQUE,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("id") REFERENCES "user" ("id") ON DELETE CASCADE
);

-- Guardianship
CREATE TABLE "guardianship" (
  "CitizenId"   INTEGER  NOT NULL,
  "GuardianId"  INTEGER  NOT NULL,
  PRIMARY KEY ("CitizenId", "GuardianId"),
  FOREIGN KEY ("CitizenId") REFERENCES "citizen" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("GuardianId") REFERENCES "nonCitizen" ("id") ON DELETE CASCADE
);

-- UserRole
CREATE TABLE "userRole" (
  "NonCitizenId"    INTEGER      NOT NULL,
  "OrganizationId"  INTEGER      NOT NULL,
  "Role"            VARCHAR(65)  NOT NULL,
  PRIMARY KEY ("NonCitizenId", "OrganizationId", "Role"),
  FOREIGN KEY ("NonCitizenId") REFERENCES "nonCitizen" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("OrganizationId") REFERENCES "organization" ("id") ON DELETE CASCADE
);

-- Image
CREATE TABLE "image" (
  "id"              INTEGER       NOT NULL DEFAULT nextval('image_id_seq'),
  "Name"            VARCHAR(65),
  "CitizenId"       INTEGER       NOT NULL,
  "Path"            VARCHAR(65),
  "OrganizationId"  INTEGER       NOT NULL,
  "StorageKey"      VARCHAR(512)  NOT NULL,
  "FileName"        VARCHAR(255)  NOT NULL,
  "FileType"        VARCHAR(100)  NOT NULL,
  "SizeBytes"       BIGINT        NOT NULL,
  "CreatedAt"       TIMESTAMP WITH TIME ZONE,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("CitizenId") REFERENCES "citizen" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("OrganizationId") REFERENCES "organization" ("id") ON DELETE CASCADE
);

-- Populate the database with some initial data
INSERT INTO "organization" ("Name") VALUES
  ('Organization A');
INSERT INTO "class" ("Name", "OrganizationId") VALUES
  ('Class 1', (SELECT "id" FROM "organization" WHERE "Name" = 'Organization A'));
INSERT INTO "user" ("FirstName", "LastName", "UserName", "password") VALUES
  ('John', 'Doe', 'johndoe', 'password1');
INSERT INTO "citizen" ("id", "ClassId") VALUES
  (1, 1);
INSERT INTO "nonCitizen" ("id", "Email") VALUES
  (1, 'bob.johnson@example.com');
INSERT INTO "guardianship" ("CitizenId", "GuardianId") VALUES
  (1, 1);
INSERT INTO "userRole" ("NonCitizenId", "OrganizationId", "Role") VALUES
  (1, 1, 'Admin');
INSERT INTO "image" ("Name", "CitizenId", "Path", "OrganizationId", "StorageKey", "FileName", "FileType", "SizeBytes", "CreatedAt") VALUES
  ('Image 1', 1, '/images/image1.jpg', 1, 'storage_key_1', 'image1.jpg', 'image/jpeg', 1024, NOW());

