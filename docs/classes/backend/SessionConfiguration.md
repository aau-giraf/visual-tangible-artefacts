# Class: SessionConfiguration

**Path:** `Backend/VTA.Data/DbContexts/Configurations/SessionConfiguration.cs`

## Overview
The `SessionConfiguration` class implements `IEntityTypeConfiguration` to define the database mapping and relationships for the `Session` entity using Entity Framework Core's Fluent API. This configuration details how call session data is stored, including participants, timestamps, duration, and status.

## Extends
*(None)*

## Implements
- `Microsoft.EntityFrameworkCore.IEntityTypeConfiguration<VTA.Data.Models.Session>`

## Properties
*(None)*

## Methods
- `Configure(EntityTypeBuilder<Session> builder)`:
  - Configures `Id` as the primary key and sets it to be value-generated on add.
  - Maps the entity to the `sessions` table.
  - Configures property details like `IsRequired`, `MaxLength`, `ColumnName`, `ColumnType`, and `HasConversion` for `Id`, `CallerId`, `CalleeId`, `StartTime`, `EndTime`, `Duration`, and `CallStatus`. Notably, `CallStatus` is stored as a string in the database.
  - Establishes a many-to-one relationship with `User` for `Caller` (`Session` has one `Caller`) with `DeleteBehavior.Restrict`.
  - Establishes a many-to-one relationship with `User` for `Callee` (`Session` has one `Callee`) with `DeleteBehavior.Restrict`.

## Internal Imports
- `VTA.Data.Models` (namespace)

## Notable Packages
- `Microsoft.EntityFrameworkCore`
- `Microsoft.EntityFrameworkCore.Metadata.Builders`

## Relationships
- Configures the `Session` entity.
- Relates `Session` to the `User` entity (twice, for Caller and Callee).
- Uses the `CallStatus` enum.
