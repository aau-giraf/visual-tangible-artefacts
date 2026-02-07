# Class: VTAContext

**Path:** `Backend/VTA.Data/DbContexts/VTAContext.cs`

## Overview
The `VTAContext` class is the Entity Framework Core DbContext for the VTA application. It represents the session with the database and provides `DbSet` properties for querying and saving instances of each entity in the model. It also configures the model using fluent API configurations.

## Extends
- `Microsoft.EntityFrameworkCore.DbContext`

## Properties
- `Artefacts` (`DbSet<Artefact>`): Represents the collection of `Artefact` entities.
- `Categories` (`DbSet<Category>`): Represents the collection of `Category` entities.
- `Users` (`DbSet<User>`): Represents the collection of `User` entities.
- `SavedBoards` (`DbSet<SavedBoard>`): Represents the collection of `SavedBoard` entities.
- `SavedArtefacts` (`DbSet<SavedArtefact>`): Represents the collection of `SavedArtefact` entities.
- `Relations` (`DbSet<Relation>`): Represents the collection of `Relation` entities.
- `Sessions` (`DbSet<Session>`): Represents the collection of `Session` entities.

## Methods
- `VTAContext()`: Default constructor.
- `VTAContext(DbContextOptions<VTAContext> options)`: Constructor that accepts `DbContextOptions`, allowing for dependency injection and configuration (e.g., database provider, connection string).
- `OnModelCreating(ModelBuilder modelBuilder)`: Overrides the base `DbContext` method to configure the database schema, including collation, character set, and applying all model configurations from the assembly containing `VTAContext`.

## Internal Imports
- `VTA.Data.Models` (namespace)

## Notable Packages
- `Microsoft.EntityFrameworkCore`

## Relationships
- Associated Classes: `Artefact`, `Category`, `User`, `SavedBoard`, `SavedArtefact`, `Relation`, `Session` (all through `DbSet` properties and model configurations)
