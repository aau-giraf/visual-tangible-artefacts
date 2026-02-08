# Class: SavedArtefactConfiguration

**Path:** `Backend/VTA.Data/DbContexts/Configurations/SavedArtefactConfiguration.cs`

## Overview
The `SavedArtefactConfiguration` class implements `IEntityTypeConfiguration` to define the database mapping and relationships for the `SavedArtefact` entity using Entity Framework Core's Fluent API. This configuration details how `SavedArtefact` instances are stored, their properties, and their relationships with `Artefact` and `SavedBoard` entities.

## Extends
*(None)*

## Implements
- `Microsoft.EntityFrameworkCore.IEntityTypeConfiguration<VTA.Data.Models.SavedArtefact>`

## Properties
*(None)*

## Methods
- `Configure(EntityTypeBuilder<SavedArtefact> builder)`:
  - Configures `Id` as the primary key.
  - Maps the entity to the `savedArtefact` table.
  - Defines indexes for `ArtefactId` and `BoardId`.
  - Configures property details like `MaxLength`, `ColumnName`, `HasDefaultValue`, `HasDefaultValueSql`, and `ColumnType` for `Id`, `ArtefactId`, `BoardId`, `PosX`, `PosY`, `Width`, `Height`, `CreatedDate`, and `NameVisible`.
  - Establishes a many-to-one relationship with `Artefact` (a `SavedArtefact` refers to one `Artefact`) with `DeleteBehavior.Cascade`.
  - Establishes a many-to-one relationship with `SavedBoard` (a `SavedArtefact` is on one `SavedBoard`) with `DeleteBehavior.Cascade`.

## Internal Imports
- `VTA.Data.Models` (namespace)

## Notable Packages
- `Microsoft.EntityFrameworkCore`
- `Microsoft.EntityFrameworkCore.Metadata.Builders`

## Relationships
- Configures the `SavedArtefact` entity.
- Relates `SavedArtefact` to `Artefact` and `SavedBoard` entities.
