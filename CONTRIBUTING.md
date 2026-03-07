# Contributing to VTA

For general workflow and guidelines, see the [organization CONTRIBUTING.md](https://github.com/aau-giraf/.github/blob/main/CONTRIBUTING.md).

## Development Setup

### Prerequisites

- .NET 8 SDK
- Docker (for MySQL + full-stack compose)
- Flutter SDK (for the mobile app)
- Node.js 18+ (for the admin dashboard)

### Full Stack (Docker)

```bash
docker compose up
# API on :5192, SyncService on :5133, MySQL on :3306
```

### Backend Only

```bash
cd Backend/VTA.API
dotnet run                    # API on :5192
dotnet test ../VTA.Tests/     # Needs Docker (Testcontainers)
```

### Flutter App

```bash
cd Frontend/vta_app
flutter pub get
flutter run
flutter test
```

### Admin Dashboard

```bash
cd Frontend/admin-dashboard
npm install
npm run dev                   # Dev server on :5173
```

### Database

VTA uses DB-first workflow. Schema source of truth is `mysql_schema.sql`.

```bash
# After schema changes, scaffold models:
dotnet ef dbcontext scaffold "server=...;database=VTA" \
  Pomelo.EntityFrameworkCore.MySql -o scaffold -f
```

## Code Style

- **Backend:** Standard .NET conventions
- **Flutter:** Never use `print()` — use `package:logging`
- **Admin dashboard:** Vue 3 + Vite, standard ESLint config
