# Visual Tangible Artefacts

This repository is a monorepo containing both frontend and backend code for the VTA (Visual Tangible Artefacts) project. It is part of the GIRAF ecosystem.

**Table of Contents**  
- [Quick Overview](#quick-overview)
- [Contributing to Visual Tangible Artefacts](#contributing-to-visual-tangible-artefacts)
  - [General Guidelines](#general-guidelines)
  - [Database-First Approach](#database-first-approach)
- [Naming Conventions](#naming-conventions)
  - [Dart (Frontend) Naming Conventions](#dart-frontend-naming-conventions)
  - [C# (API) Naming Conventions](#c-api-naming-conventions)
 
## Questions and appsettings handover
For any questions or request for appsettings handover, contact rkrage22@student.aau.dk

## Quick Overview

- **Monorepo Structure:**  
  All frontend, backend, and tests reside in one repository.
  
- **Development Branches:**  
  - `dev-main`: Main integration branch. Features should be merged here first and tested.
  - `main`: Production branch. Code from `dev-main` is merged here after passing CI and review.

- **CI/CD Setup:**  
  - **CI** runs on GitHub-hosted runners for all pushes/PRs to `dev-main` or `main`.
  - **CD** runs on a self-hosted runner when changes are merged into `main`.
  - Workflows are defined in `.github/workflows/`.
  - Automated test runs use Docker and Testcontainers to create a clean MySQL environment for integration tests.

- **GitHub Projects & Issues:**  
  Task management uses GitHub Projects.  
  - Opening a new issue triggers a workflow that sets a start date.
  - Closing an issue triggers a workflow that sets an end date.
  - These workflows require a `GIT_TOKEN` secret in GitHub Actions.

- **Protected Branches & Reviews:**  
  - Direct pushes to `main` are blocked.
  - A PR from `dev-main` to `main` requires passing tests and at least one reviewer approval.
  - Admins can override in emergencies if needed.

- **Secrets and Configurations:**  
  - All sensitive data is stored in GitHub Secrets (`Settings -> Secrets and variables -> Actions`).
  - Example secrets: `GIT_TOKEN`, `JWT_SECRET`, `TEST_CONNECTION_STRING`.
  - CI/CD, Docker-based tests, and API deployments rely on these secrets.
  
- **Testing Environment:**  
  - Tests run automatically via `dotnet test` in CI.
  - `CustomApplicationFactory.cs` uses Testcontainers to spawn a temporary MySQL database.
  - Configuration fallback for tests (in order):
    1. `/var/www/VTA.API/appsettings.json` (VPS environment)
    2. Local `appsettings.json` (developer machine)
    3. Environment variables (in GitHub Actions)
  - EF migrations are auto-generated at test runtime, so no manual SQL scripts are needed.

- **VPS & Deployment Details:**  
  - The API is deployed to `/var/www/VTA.API/` on the VPS.
  - Deployment uses `rsync` to update files and `systemctl restart vtaapi.service` to restart the API.
  - VPS-side configuration changes (like `sudo visudo` edits) may be required for runner permissions.

## Contributing to Visual Tangible Artefacts

### General Guidelines
Contributions typically follow a feature-branch-based workflow:
1. **Create an issue:** Start by opening an issue on GitHub to describe the feature, improvement, or bug fix.
2. **Branch off from `dev-main`:** Create a new branch named after the issue (e.g., `feature/issue-123-new-ui`).
3. **Implement and Test:** Develop your changes locally, add tests where applicable, and ensure all tests pass.
4. **Pull Request and Review:** Open a pull request (PR) from your feature branch into `dev-main`. If you’re uncertain about the correctness, request a code review.
5. **Merge to `main`:** After your code is tested and approved, it will be merged from `dev-main` into `main` for deployment.

**Tip:** Sometimes it helps to merge `main` into your feature branch first to test against production-ready code, then finalize your changes and open a PR to merge into `main`.

**Branching Strategy Overview:**
  
![Branching strategy](https://github.com/aau-giraf/visual-tangible-artefacts/blob/dev-main/Resources/Branching.png)

### Database-First Approach
We follow a **DB-first approach**, meaning the database schema is the source of truth, and code models are generated from it.

**Workflow:**
1. **Design the database schema:** Define tables, relationships, and constraints in the database directly.
2. **Generate models from DB:**  
   Use `dotnet ef` scaffold commands to generate or update model classes:
   ```bash
   dotnet ef dbcontext scaffold "server=[server];port=[port];user=[user];password=[password];database=VTA" \
   Pomelo.EntityFrameworkCore.MySql -o scaffold -f
   ```
   This regenerates the entire DB context and model classes. For partial updates (only certain tables):
   ```bash
   dotnet ef dbcontext scaffold "server=[server];port=[port];user=[user];password=[password];database=VTA" \
   Pomelo.EntityFrameworkCore.MySql -o scaffold --table [Table1] --table [Table2] -f
   ```
3. **Auto-Generated DB Contexts:**  
   The DB context includes all tables. If concurrency or complexity is an issue, consider splitting your context into multiple smaller ones. Refer to existing contexts for examples.
4. **Regenerate after schema changes:**  
   Whenever the schema changes, regenerate the models to keep code and database aligned.

---

## Naming Conventions

### Dart (Frontend) Naming Conventions
- **Classes, Enums, Typedefs, Type Parameters:** `PascalCase` (UpperCamelCase)
  ```dart
  class SliderMenu { ... }
  typedef Predicate<T> = bool Function(T value);
  ```
- **Extensions:** `PascalCase` (UpperCamelCase)
  ```dart
  extension MyFancyList<T> on List<T> { ... }
  ```
- **Variables, Functions, Parameters, Named Constants:** `camelCase` (lowerCamelCase)
  ```dart
  var itemCount = 3;
  void alignItems(bool clearItems) { ... }
  ```
- **Directories and Files:** `lowercase_with_underscores`
  ```
  lib/
  my_widget.dart
  utils/
    string_helpers.dart
  ```
- **Import Prefixes:** `lowercase_with_underscores`
- **Acronyms:** Capitalize as words. For acronyms longer than two letters, `PascalCase`.
  ```dart
  class HttpRequest { ... }
  ```
- **Formatting:** Use `dart format` to format code.  
  Refer to [Dart style guidelines](https://dart.dev/effective-dart/style) for more details.
- **Documentation:** Document your code! Refer to [Dart documentation guidelines](https://dart.dev/effective-dart/documentation).

### C# (API) Naming Conventions
- **Classes, Enums, Structs:** `PascalCase`
  ```csharp
  class MyClass { ... }
  enum Colors { Red, Green, Blue }
  ```
- **Methods, Properties, Events:** `PascalCase`
  ```csharp
  public void FetchData() { ... }
  public string Name { get; set; }
  ```
- **Variables, Parameters:** `camelCase`
  ```csharp
  int itemCount = 3;
  void SetItemCount(int itemCount) { ... }
  ```
- **Constants:** `PascalCase` with `const`
  ```csharp
  const int MaxItems = 10;
  ```
- **Interfaces:** Prefix with `I` + `PascalCase`
  ```csharp
  public interface IMyInterface { ... }
  ```
- **Namespaces:** `PascalCase`
  ```csharp
  namespace MyApplication.Data { ... }
  ```
- **Files:** One type per file, named after the type (`PascalCase`)
  ```
  MyClass.cs
  IMyInterface.cs
  Colors.cs
  ```
- **Acronyms:** Treat acronyms as words (`HttpRequest`, `IOHandler`)
- **Formatting:** Follow [C# Coding Conventions](https://learn.microsoft.com/en-us/dotnet/csharp/fundamentals/coding-style/coding-conventions).
- **Documentation:** Use XML comments (`///`) and follow [Microsoft documentation guidelines](https://learn.microsoft.com/en-us/dotnet/csharp/programming-guide/xmldoc/).

---
