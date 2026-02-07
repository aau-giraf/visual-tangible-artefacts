# Static Class: WebApplicationExtensions

**Path:** `Backend/VTA.API/Extensions/WebApplicationExtensions.cs`

## Overview
The `WebApplicationExtensions` static class provides extension methods for `Microsoft.AspNetCore.Builder.WebApplication` to integrate database migration and seeding of initial user data directly into the application's startup pipeline. This ensures the database is set up correctly and contains essential test users when the application starts.

## Extends
*(None, this is an extension methods class)*

## Implements
*(None)*

## Properties
*(None)*

## Methods

### `MigrateVTAContext(this WebApplication application)`
- **Purpose**: An extension method for `WebApplication` that orchestrates the database migration and seeding of test data.
- **Parameters**:
  - `application` (`WebApplication`): The application instance to extend.
- **Returns**: The `WebApplication` instance, allowing for method chaining.
- **Functionality**:
  - Checks for an environment variable `AUTO_CREATE_DATABASE` to determine if automatic database creation and seeding should occur.
  - Creates an asynchronous service scope to resolve necessary services.
  - Calls `MigrateVTAContext(this IServiceScope scope)` to ensure the database schema is created.
  - Calls `SeedTestUser(this VTAContext context)` to seed default user data.
  - Catches and logs any exceptions during the process, then rethrows them.

### `MigrateVTAContext(this IServiceScope scope)` (private extension method)
- **Purpose**: Ensures that the `VTAContext` database is created.
- **Parameters**:
  - `scope` (`IServiceScope`): The service scope from which `VTAContext` is retrieved.
- **Returns**: The `VTAContext` instance after ensuring database creation.
- **Functionality**:
  - Retrieves `VTAContext` from the service provider.
  - Calls `vtaContext.Database.EnsureCreatedAsync()` to create the database if it doesn't already exist.

### `SeedTestUser(this VTAContext context)` (private extension method)
- **Purpose**: Seeds the database with default test user accounts (giraf, admin, caregiver) and a sample caregiver-child relation.
- **Parameters**:
  - `context` (`VTAContext`): The database context to seed data into.
- **Returns**: The `VTAContext` instance after seeding.
- **Functionality**:
  - Checks if "giraf" user exists; if not, creates a new `Child` user with username "giraf" and a hashed password.
  - Checks if "admin" user exists; if not, creates a new `Admin` user. If "admin" exists but isn't an `Admin`, updates their role.
  - Checks if "caregiver" user exists; if not, creates a new `Caregiver` user.
  - Checks if a relation between the "caregiver" and "giraf" user exists; if not, creates one.
  - Uses `BCrypt.Net.BCrypt.HashPassword` to hash user passwords.

## Internal Imports
- `VTA.Data.DbContexts`
- `VTA.Data.Models`

## Notable Packages
- `Microsoft.EntityFrameworkCore`
- `Microsoft.Extensions.DependencyInjection`
- `BCrypt.Net`
