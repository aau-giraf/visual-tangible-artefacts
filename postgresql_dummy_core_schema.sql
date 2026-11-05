

CREATE DATABASE dummy_core
SET client_encoding = 'UTF8';

-- Drop in dependency order ()
DROP TABLE IF EXISTS "User";
DROP TABLE IF EXISTS "Citizen";
DROP TABLE IF EXISTS "Guardianship";
DROP TABLE IF EXISTS "NonCitizen";
DROP TABLE IF EXISTS "UserRole";
DROP TABLE IF EXISTS "Image";
DROP TABLE IF EXISTS "Class";
DROP TABLE IF EXISTS "Organization";

-- USER
CREATE TABLE "user" (
  "Id"                INTEGER               NOT NULL,
  "FirstName"         VARCHAR(65)                  NULL,
  "LastName"          VARCHAR(65)                  NULL,
  "UserName"          VARCHAR(65) UNIQUE           NOT NULL,  
  "password"          VARCHAR(65)                  NOT NULL,
  PRIMARY KEY ("Id")
); 

--Citizen 
CREATE TABLE "citizen"(
    "Id"              INTEGER               NOT NULL, 
    "ClassId"         INTEGER               NOT NULL, 
     PRIMARY KEY ("Id"),
     FOREIGN KEY ("ClassId") REFERENCES "class" ("Id") ON DELETE CASCADE,
     FOREIGN KEY ("Id") REFERENCES "user" ("Id") ON DELETE CASCADE
);

--Guardianship 
CREATE TABLE "guardianship"(
    "CitizenId"      INTEGER               NOT NULL, 
    "GuardianId"     INTEGER               NOT NULL, 
     PRIMARY KEY ("CitizenId", "GuardianId"),
     FOREIGN KEY ("CitizenId") REFERENCES "citizen" ("Id") ON DELETE CASCADE,
     FOREIGN KEY ("GuardianId") REFERENCES "nonCitizen" ("Id") ON DELETE CASCADE
);

--NonCitizen
CREATE TABLE "nonCitizen"(
    "Id"            INTEGER                NOT NULL, 
    "Email"         VARCHAR(65) UNIQUE           NULL 
     PRIMARY KEY ("Id"),
     FOREIGN KEY ("Id") REFERENCES "user" ("Id") ON DELETE CASCADE
);

--UserRole 
CREATE TABLE "userRole"(
    "NonCitizenId"         INTEGER       NOT NULL, 
    "OrganizationId"       INTEGER       NOT NULL, 
    "Role"                 VARCHAR(65),         NOT NULL 
     PRIMARY KEY ("NonCitizenId", "OrganizationId", "Role"),
     FOREIGN KEY ("NonCitizenId") REFERENCES "nonCitizen" ("Id") ON DELETE CASCADE,
     FOREIGN KEY ("OrganizationId") REFERENCES "organization" ("Id") ON DELETE CASCADE
);

--Image 
CREATE TABLE "image" (
  "Id"                INTEGER            NOT NULL,
  "Name"              VARCHAR(65)               NULL,
  "CitizenId"         INTEGER            NOT NULL,
  "Path"              VARCHAR(65)               NULL,  
  "OrganizationId"    INTEGER            NOT NULL,
  "StorageKey"        VARCHAR(512)       NOT NULL,
  "FileName"          VARCHAR(255)       NOT NULL,
  "FileType"          VARCHAR(100)       NOT NULL,     
  "SizeBytes"         BIGINT             NOT NULL,  
  "CreatedAt"         TIMESTAMP WITH TIME ZONE   NULL, 
  PRIMARY KEY ("Id"),
  FOREIGN KEY ("CitizenId", "OrganizationId")
  FOREIGN KEY ("CitizenId") REFERENCES "citizen" ("Id") ON DELETE CASCADE,
  FOREIGN KEY ("OrganizationId") REFERENCES "organization" ("Id") ON DELETE CASCADE
); 

--Class
CREATE TABLE "class"(
    "Id"              INTEGER            NOT NULL, 
    "Name"            VARCHAR(65)               NULL, 
    "OrganizationId"  INTEGER,           NOT NULL 
     PRIMARY KEY ("Id"),
     FOREIGN KEY ("OrganizationId") REFERENCES "organization" ("Id") ON DELETE CASCADE
);

--Organization
CREATE TABLE "organization"(
    "Id"             INTEGER              NOT NULL, 
    "Name"           VARCHAR(65)                 NULL,  
     PRIMARY KEY ("Id")
);


