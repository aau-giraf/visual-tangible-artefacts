# Copilot Instructions — VTA (Visual Tangible Artefacts)

## Documentation

> **⚠️ The `docs/` folder is a historical snapshot** taken before the improvement roadmap began. The broad architecture is still correct, but specific details (controller structure, service layer, route paths, dependencies) may be outdated. When `docs/` conflicts with the actual source code or the per-component guides below, **trust the source code**.

| What you need | Where to look |
|---|---|
| **Authoritative** per-component guides | `Backend/CLAUDE-backend.md`, `Frontend/vta_app/CLAUDE-flutter.md`, `Frontend/admin-dashboard/CLAUDE-admin.md` |
| Improvement roadmap & current progress | `improvementPlan.md` (root) |
| System diagram, layers, data flow | `docs/architecture/overview.md` *(historical)* |
| Feature dependency graph, coupling hotspots | `docs/architecture/dependency_map.md` *(historical)* |
| Docker, ports, secrets, schemas | `docs/architecture/infrastructure.md` *(historical)* |
| Per-feature interaction diagrams & sequences | `docs/features/` *(historical)* |
| Known tech debt (original analysis) | `docs/improvement_proposals.md` *(historical)* |
| Class-level API surface | `docs/classes/` *(historical — may not reflect new services)* |

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

- **JWT custom claim**: User identity is `User.FindFirst("id")?.Value` — not `sub`, not `nameidentifier`.
- **DB-first, no migrations**: `mysql_schema.sql` is the schema source of truth. Models are scaffolded via `dotnet ef dbcontext scaffold` (Pomelo). Never add EF migrations.
- **Backend service layer**: Controllers delegate business logic to service classes in `VTA.API/Services/` (e.g. `ITtsService`, `IRelationService`, `IUserService`). Services inject `VTAContext` and are registered as `AddScoped` in `Program.cs`. Controllers handle HTTP concerns only (routing, model binding, auth, status codes).
- **DTO mapping**: Static `DtoConverter` class, not AutoMapper.
- **Flutter API returns**: `ApiProvider` returns `Response?` (null on failure). Callers must null-check AND verify `response.isOk`.
- **SignalR method names**: Hub method names and Flutter client callback names must match exactly (string-based, e.g. `"ArtifactAdded"`).
- **SignalR package**: Flutter uses `signalr_netcore`, not the official Microsoft package.
- **Localization**: New user-facing strings must use ARB keys (`l10n.yaml`), not hardcoded strings.
- **Branching**: Feature branches → `dev-main` → `main`. Never push directly to `main`.

## Git Workflow (Fork + Squash-Merge)

This repo uses a fork model with squash-merges. After a PR is squash-merged upstream, your local `dev-main` will have stale commits with different SHAs. **You must sync after every merge.**

**Local git config (already set):**
- `branch.dev-main.remote = upstream` — `git pull` on `dev-main` pulls from the canonical repo, not your fork.
- `pull.rebase = true` — pulls rebase instead of merge, dropping already-merged commits.
- `merge.ff = only` — prevents accidental merge commits.

**After a squash-merge lands on upstream:**
```bash
./sync.sh                  # resets dev-main to upstream, pushes to fork
# OR manually:
git fetch upstream && git checkout dev-main && git reset --hard upstream/dev-main && git push origin dev-main --force-with-lease
```

**Starting a new feature branch:**
```bash
./sync.sh                  # ensure dev-main is current first
git checkout -b feature/my-feature
```

**After CI goes green on a PR:**
```bash
gh pr merge <number> --repo aau-giraf/visual-tangible-artefacts --squash --admin
./sync.sh                  # immediately sync after merge
```

## Cross-Component Workflows

- **New real-time event**: `BoardHub.cs` hub method → Flutter `SignalRService` callback → names must match exactly.
- **New API endpoint**: Controller method → DTO + `DtoConverter` → Flutter model/controller → admin API module (if admin-facing).
- **Schema change**: Update `mysql_schema.sql` → scaffold EF models → update DTOs/controllers. No migrations.
