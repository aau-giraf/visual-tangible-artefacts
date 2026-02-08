# Class: SavedBoardConfiguration

**Path:** `Backend/VTA.Data/DbContexts/Configurations/SavedBoardConfiguration.cs`

## Overview
The `SavedBoardConfiguration` class implements `IEntityTypeConfiguration` to define the database mapping and relationships for the `SavedBoard` entity using Entity Framework Core's Fluent API. This configuration details how `SavedBoard` instances are stored, their properties, and their relationships with `User` and `SavedArtefact` entities.

## Extends
*(None)*

## Implements
- `Microsoft.EntityFrameworkCore.IEntityTypeConfiguration<VTA.Data.Models.SavedBoard>`

## Properties
*(None)*

## Methods
- `Configure(EntityTypeBuilder<SavedBoard> builder)`:
  - Configures `Id` as the primary key.
  - Maps the entity to the `savedBoard` table.
  - Defines an index for `UserId`.
  - Configures property details like `MaxLength`, `ColumnName`, `ColumnType`, and `HasDefaultValueSql` for `Id`, `Name`, `UserId`, `SnapshotPath`, `SavedArtefactIds`, `ArtefactIds`, `CreatedDate`, and `ModifiedDate`. `SavedArtefactIds` and `ArtefactIds` are configured as `json` column types.
  - Establishes a many-to-one relationship with `User` (a `SavedBoard` is owned by one `User`) with `DeleteBehavior.Cascade`.
  - Establishes a one-to-many relationship with `SavedArtefact` (a `SavedBoard` can have many `SavedArtefacts`) with `DeleteBehavior.Cascade`.

## Internal Imports
- `VTA.Data.Models` (namespace)

## Notable Packages
- `Microsoft.EntityFrameworkCore`
- `Microsoft.EntityFrameworkCore.Metadata.Builders`

## Relationships
- Configures the `SavedBoard` entity.
- Relates `SavedBoard` to `User` and `SavedArtefact` entities.
