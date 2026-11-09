SET client_encoding = 'UTF8';

-- Sequences for id´s
CREATE SEQUENCE "user_id_seq" AS INTEGER START WITH 1;


-- Organization
CREATE TABLE "organization" (
  "Id"    INTEGER     NOT NULL,
  "Name"  VARCHAR(65),
  PRIMARY KEY ("Id")
);

-- Class
CREATE TABLE "class" (
  "Id"              INTEGER     NOT NULL,
  "Name"            VARCHAR(65),
  "OrganizationId"  INTEGER     NOT NULL,
  PRIMARY KEY ("Id"),
  FOREIGN KEY ("OrganizationId") REFERENCES "organization" ("Id") ON DELETE CASCADE
);

-- User
CREATE TABLE "user" (
  "Id"         INTEGER      NOT NULL DEFAULT nextval('user_id_seq'),
  "FirstName"  VARCHAR(65),
  "LastName"   VARCHAR(65),
  "UserName"   VARCHAR(65)  NOT NULL UNIQUE,
  "password"   VARCHAR(65)  NOT NULL,
  PRIMARY KEY ("Id")
);

-- Citizen
CREATE TABLE "citizen" (
  "Id"       INTEGER  NOT NULL,
  "ClassId"  INTEGER  NOT NULL,
  PRIMARY KEY ("Id"),
  FOREIGN KEY ("ClassId") REFERENCES "class" ("Id") ON DELETE CASCADE,
  FOREIGN KEY ("Id") REFERENCES "user" ("Id") ON DELETE CASCADE
);

-- NonCitizen
CREATE TABLE "nonCitizen" (
  "Id"     INTEGER      NOT NULL,
  "Email"  VARCHAR(65)  UNIQUE,
  PRIMARY KEY ("Id"),
  FOREIGN KEY ("Id") REFERENCES "user" ("Id") ON DELETE CASCADE
);

-- Guardianship
CREATE TABLE "guardianship" (
  "CitizenId"   INTEGER  NOT NULL,
  "GuardianId"  INTEGER  NOT NULL,
  PRIMARY KEY ("CitizenId", "GuardianId"),
  FOREIGN KEY ("CitizenId") REFERENCES "citizen" ("Id") ON DELETE CASCADE,
  FOREIGN KEY ("GuardianId") REFERENCES "nonCitizen" ("Id") ON DELETE CASCADE
);

-- UserRole
CREATE TABLE "userRole" (
  "NonCitizenId"    INTEGER      NOT NULL,
  "OrganizationId"  INTEGER      NOT NULL,
  "Role"            VARCHAR(65)  NOT NULL,
  PRIMARY KEY ("NonCitizenId", "OrganizationId", "Role"),
  FOREIGN KEY ("NonCitizenId") REFERENCES "nonCitizen" ("Id") ON DELETE CASCADE,
  FOREIGN KEY ("OrganizationId") REFERENCES "organization" ("Id") ON DELETE CASCADE
);

-- Image
CREATE TABLE "image" (
  "Id"              INTEGER       NOT NULL,
  "Name"            VARCHAR(65),
  "CitizenId"       INTEGER       NOT NULL,
  "Path"            VARCHAR(65),
  "OrganizationId"  INTEGER       NOT NULL,
  "StorageKey"      VARCHAR(512)  NOT NULL,
  "FileName"        VARCHAR(255)  NOT NULL,
  "FileType"        VARCHAR(100)  NOT NULL,
  "SizeBytes"       BIGINT        NOT NULL,
  "CreatedAt"       TIMESTAMP WITH TIME ZONE,
  PRIMARY KEY ("Id"),
  FOREIGN KEY ("CitizenId") REFERENCES "citizen" ("Id") ON DELETE CASCADE,
  FOREIGN KEY ("OrganizationId") REFERENCES "organization" ("Id") ON DELETE CASCADE
);