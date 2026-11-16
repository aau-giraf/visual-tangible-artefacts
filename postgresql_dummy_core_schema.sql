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
  "name"  VARCHAR(65),
  PRIMARY KEY ("id")
);

-- Class
CREATE TABLE "class" (
  "id"              INTEGER     NOT NULL DEFAULT nextval('class_id_seq'),
  "Name"            VARCHAR(65),
  "OrganizationId"  INTEGER     NOT NULL,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("organizationId") REFERENCES "organization" ("id") ON DELETE CASCADE
);

-- User
CREATE TABLE "user" (
  "id"         INTEGER      NOT NULL DEFAULT nextval('user_id_seq'),
  "firstName"  VARCHAR(65),
  "lastName"   VARCHAR(65),
  "userName"   VARCHAR(65)  NOT NULL UNIQUE,
  "password"   VARCHAR(65)  NOT NULL,
  PRIMARY KEY ("id")
);

-- Citizen
CREATE TABLE "citizen" (
  "id"       INTEGER  NOT NULL,
  "classId"  INTEGER  NOT NULL,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("classId") REFERENCES "class" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("id") REFERENCES "user" ("id") ON DELETE CASCADE
);

-- NonCitizen
CREATE TABLE "nonCitizen" (
  "id"     INTEGER      NOT NULL,
  "email"  VARCHAR(65)  UNIQUE,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("id") REFERENCES "user" ("id") ON DELETE CASCADE
);

-- Guardianship
CREATE TABLE "guardianship" (
  "citizenId"   INTEGER  NOT NULL,
  "guardianId"  INTEGER  NOT NULL,
  PRIMARY KEY ("citizenId", "guardianId"),
  FOREIGN KEY ("citizenId") REFERENCES "citizen" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("guardianId") REFERENCES "nonCitizen" ("id") ON DELETE CASCADE
);

-- UserRole
CREATE TABLE "userRole" (
  "nonCitizenId"    INTEGER      NOT NULL,
  "organizationId"  INTEGER      NOT NULL,
  "role"            VARCHAR(65)  NOT NULL,
  PRIMARY KEY ("nonCitizenId", "organizationId", "role"),
  FOREIGN KEY ("nonCitizenId") REFERENCES "nonCitizen" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("organizationId") REFERENCES "organization" ("id") ON DELETE CASCADE
);

-- Image
CREATE TABLE "image" (
  "id"              INTEGER       NOT NULL DEFAULT nextval('image_id_seq'),
  "name"            VARCHAR(65),
  "citizenId"       INTEGER       NOT NULL,
  "path"            VARCHAR(65),
  "organizationId"  INTEGER       NOT NULL,
  "storageKey"      VARCHAR(512)  NOT NULL,
  "fileName"        VARCHAR(255)  NOT NULL,
  "fileType"        VARCHAR(100)  NOT NULL,
  "sizeBytes"       BIGINT        NOT NULL,
  "createdAt"       TIMESTAMP WITH TIME ZONE,
  PRIMARY KEY ("id"),
  FOREIGN KEY ("citizenId") REFERENCES "citizen" ("id") ON DELETE CASCADE,
  FOREIGN KEY ("organizationId") REFERENCES "organization" ("id") ON DELETE CASCADE
);

-- Populate the database with some initial data
INSERT INTO "organization" ("name") VALUES
  ('Organization A');
INSERT INTO "class" ("name", "organizationId") VALUES
  ('Class 1', (SELECT "id" FROM "organization" WHERE "name" = 'Organization A'));
INSERT INTO "user" ("firstName", "lastName", "userName", "password") VALUES
  ('John', 'Doe', 'johndoe', 'password1');
INSERT INTO "citizen" ("id", "classId") VALUES
  (1, 1);
INSERT INTO "nonCitizen" ("id", "email") VALUES
  (1, 'bob.johnson@example.com');
INSERT INTO "guardianship" ("citizenId", "guardianId") VALUES
  (1, 1);
INSERT INTO "userRole" ("nonCitizenId", "organizationId", "role") VALUES
  (1, 1, 'Admin');
INSERT INTO "image" ("name", "citizenId", "path", "organizationId", "storageKey", "fileName", "fileType", "sizeBytes", "createdAt") VALUES
  ('Image 1', 1, '/images/image1.jpg', 1, 'storage_key_1', 'image1.jpg', 'image/jpeg', 1024, NOW());

