# Class: UserConfiguration

**Path:** `Backend/VTA.Data/DbContexts/Configurations/UserConfiguration.cs`

## Overview
The `UserConfiguration` class implements `IEntityTypeConfiguration` to define the database mapping and relationships for the `User` entity using Entity Framework Core's Fluent API. This configuration covers key definitions, table mapping, property configurations, and relationships with other entities like `Artefact`, `Category`, `SavedBoard`, and `Relation`.

## Extends
*(None)*

## Implements
- `Microsoft.EntityFrameworkCore.IEntityTypeConfiguration<VTA.Data.Models.User>`

## Properties
*(None)*

## Methods
- `Configure(EntityTypeBuilder<User> builder)`:
  - Configures `Id` as the primary key.
  - Maps the entity to the `user` table.
  - Configures property details like `MaxLength`, `ColumnName`, `IsRequired`, `HasDefaultValue`, and `HasConversion` for `Id`, `Role`, `Name`, `Password`, `Username`, `NameVisible`, and `FieldCount`. Notably, `Role` is stored as a string and defaults to `UserRole.Child`.
  - Configures two one-to-many relationships with `Relation` for `CaregiverRelations` and `ChildRelations`, setting `DeleteBehavior.Restrict` for foreign keys.

## Internal Imports
- `VTA.Data.Models` (namespace)

## Notable Packages
- `Microsoft.EntityFrameworkCore`
- `Microsoft.EntityFrameworkCore.Metadata.Builders`

## Relationships
- Configures the `User` entity.
- Relates `User` to `Artefact`, `Category`, `SavedBoard`, and `Relation` entities.
- Uses the `UserRole` enum.
