# Class: RelationConfiguration

**Path:** `Backend/VTA.Data/DbContexts/Configurations/RelationConfiguration.cs`

## Overview
The `RelationConfiguration` class implements `IEntityTypeConfiguration` to define the database mapping and relationships for the `Relation` entity using Entity Framework Core's Fluent API. This includes key definitions, table mapping, property configurations, and foreign key relationships between caregivers and children.

## Extends
*(None)*

## Implements
- `Microsoft.EntityFrameworkCore.IEntityTypeConfiguration<VTA.Data.Models.Relation>`

## Properties
*(None)*

## Methods
- `Configure(EntityTypeBuilder<Relation> builder)`:
  - Configures `Id` as the primary key.
  - Maps the entity to the `relation` table.
  - Configures property details like `MaxLength`, `ColumnName`, `IsRequired`, and `HasDefaultValueSql` for `Id`, `CaregiverId`, `ChildId`, `IsActive`, and `CreatedAt`.
  - Establishes a one-to-many relationship with `User` for the `Caregiver` (a `User` can be a caregiver in many `Relation`s) with `DeleteBehavior.Restrict`.
  - Establishes a one-to-many relationship with `User` for the `Child` (a `User` can be a child in many `Relation`s) with `DeleteBehavior.Restrict`.

## Internal Imports
- `VTA.Data.Models` (namespace)

## Notable Packages
- `Microsoft.EntityFrameworkCore`
- `Microsoft.EntityFrameworkCore.Metadata.Builders`

## Relationships
- Configures the `Relation` entity.
- Relates `Relation` to the `User` entity (twice, for Caregiver and Child).
