# Class: ArtefactConfiguration

**Path:** `Backend/VTA.Data/DbContexts/Configurations/ArtefactConfiguration.cs`

## Overview
The `ArtefactConfiguration` class implements `IEntityTypeConfiguration` to define the database mapping and relationships for the `Artefact` entity using Entity Framework Core's Fluent API. This includes key definitions, table mapping, property configurations, and foreign key relationships.

## Extends
*(None)*

## Implements
- `Microsoft.EntityFrameworkCore.IEntityTypeConfiguration<VTA.Data.Models.Artefact>`

## Properties
*(None)*

## Methods
- `Configure(EntityTypeBuilder<Artefact> builder)`:
  - Configures `ArtefactId` as the primary key.
  - Maps the entity to the `artefact` table.
  - Defines indexes for `CategoryId` and `UserId`.
  - Configures property details like `MaxLength`, `ColumnName`, and `ColumnType` for `ArtefactId`, `ArtefactIndex`, `CategoryId`, `ImagePath`, `SoundPath`, `ModifiedDate`, `UserId`, `Name`, and `NameShown`.
  - Establishes a one-to-many relationship with `Category` (an `Artefact` belongs to one `Category`) with `DeleteBehavior.Restrict`.
  - Establishes a one-to-many relationship with `User` (an `Artefact` is owned by one `User`) with `DeleteBehavior.Cascade`.
  - Configures a one-to-many relationship with `SavedArtefact` (an `Artefact` can be part of many `SavedArtefacts`) with `DeleteBehavior.Restrict`.

## Internal Imports
- `VTA.Data.Models`

## Notable Packages
- `Microsoft.EntityFrameworkCore`
- `Microsoft.EntityFrameworkCore.Metadata.Builders`

## Relationships
- Configures the `Artefact` entity.
- Relates `Artefact` to `Category`, `User`, and `SavedArtefact` entities.
