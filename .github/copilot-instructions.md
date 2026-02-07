# Copilot Instructions — VTA (Visual Tangible Artefacts)

## Documentation

Read the existing docs before making changes. Start with `docs/_index.md` for the full index.

| What you need | Where to look |
|---|---|
| System diagram, layers, data flow | `docs/architecture/overview.md` |
| Feature dependency graph, coupling hotspots | `docs/architecture/dependency_map.md` |
| Docker, ports, secrets, schemas | `docs/architecture/infrastructure.md` |
| Per-feature interaction diagrams & sequences | `docs/features/` (9 docs, see `docs/features/_overview.md`) |
| Known tech debt & planned refactors | `docs/improvement_proposals.md` |
| Class-level API surface for any file | `docs/classes/backend/`, `docs/classes/flutter/`, `docs/classes/admin/` |
| Per-component agent guides | `Backend/CLAUDE-backend.md`, `Frontend/vta_app/CLAUDE-flutter.md`, `Frontend/admin-dashboard/CLAUDE-admin.md` |

## Build & Run

```bash
docker compose up                                        # full stack (MySQL + API + SyncService + TURN)
dotnet run --project Backend/VTA.API                     # API on :5192
dotnet run --project Backend/SyncService                 # Sync on :5133 (local) / :5002 (Docker)
dotnet test Backend/VTA.Tests/                           # needs Docker (Testcontainers)
dotnet test Backend/SyncService.Tests/
cd Frontend/vta_app && flutter pub get && flutter run -d chrome
cd Frontend/admin-dashboard && npm install && npm run dev # :5173
```

## Critical Conventions

These are the things that will break your work if you get them wrong:

- **JWT custom claim**: User identity is `User.FindFirst("userId")?.Value` — not `sub`, not `nameidentifier`.
- **DB-first, no migrations**: `mysql_schema.sql` is the schema source of truth. Models are scaffolded via `dotnet ef dbcontext scaffold` (Pomelo). Never add EF migrations.
- **No backend service layer**: All controllers and `BoardHub` inject `VTAContext` directly. No service/repository abstraction.
- **DTO mapping**: Static `DtoConverter` class, not AutoMapper.
- **Flutter API returns**: `ApiProvider` returns `Response?` (null on failure). Callers must null-check AND verify `response.isOk`.
- **SignalR method names**: Hub method names and Flutter client callback names must match exactly (string-based, e.g. `"ArtifactAdded"`).
- **SignalR package**: Flutter uses `signalr_netcore`, not the official Microsoft package.
- **Localization**: New user-facing strings must use ARB keys (`l10n.yaml`), not hardcoded strings.
- **Branching**: Feature branches → `dev-main` → `main`. Never push directly to `main`.

## Cross-Component Workflows

- **New real-time event**: `BoardHub.cs` hub method → Flutter `SignalRService` callback → names must match exactly.
- **New API endpoint**: Controller method → DTO + `DtoConverter` → Flutter model/controller → admin API module (if admin-facing).
- **Schema change**: Update `mysql_schema.sql` → scaffold EF models → update DTOs/controllers. No migrations.
