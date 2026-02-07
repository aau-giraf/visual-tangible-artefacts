# Repository Structure

The `visual-tangible-artefacts` (VTA) repository is a monorepo containing three main components:

- **Backend/:** A .NET 8 solution comprising:
    - `VTA.API`: A REST API and SignalR hub for core application logic, data persistence, and real-time communication.
    - `SyncService`: A SignalR real-time service for board synchronization.
    - `VTA.Data`: A data access layer handling database interactions (Entity Framework Core).
    - `VTA.Tests`: Unit and integration tests for the backend.
    - `SyncService.Tests`: Integration tests for the SyncService.

- **Frontend/vta_app/:** A Flutter mobile application (iOS, Android, Web) serving as the primary user interface.

- **Frontend/admin-dashboard/:** A Vue 3 web application providing administrative functionalities.

## Quick Commands

### Backend (from `visual-tangible-artefacts/Backend/`)

- **Build:** `dotnet build`
- **Run VTA.API:** `dotnet run --project VTA.API`
- **Run SyncService:** `dotnet run --project SyncService`
- **Test:** `dotnet test`

### Flutter App (from `visual-tangible-artefacts/Frontend/vta_app/`)

- **Build:** `flutter build web` (or `ios`, `apk`)
- **Run:** `flutter run`
- **Test Unit/Widget:** `flutter test`
- **Test Integration:** `flutter test integration_test/`

### Admin Dashboard (from `visual-tangible-artefacts/Frontend/admin-dashboard/`)

- **Install Dependencies:** `npm install` or `bun install`
- **Run Dev Server:** `npm run dev` or `bun run dev`
- **Build:** `npm run build` or `bun run build`

## Architecture Summary

The system follows a multi-tiered client-server architecture with real-time capabilities:

- **Flutter App:** Communicates with `VTA.API` via REST for data and with `SyncService` via SignalR for real-time board synchronization and WebRTC signaling.
- **VTA.API:** Provides data endpoints, authentication, and business logic. Interacts with a MySQL database.
- **SyncService:** Manages real-time connections and orchestrates board state synchronization among connected clients.
- **Admin Dashboard:** Interacts with `VTA.API` via REST for administrative tasks.
- **TURN Server:** (External) Used for WebRTC NAT traversal in video calls.

**Key Ports:**
- `VTA.API`: Typically runs on `:5192`
- `SyncService`: Typically runs on `:5133`

## Environment Setup

- **Docker Compose:** The `docker-compose.yml` in the project root can spin up a MySQL database and a TURN server (if configured).
- **.env:** Create a `.env` file in `visual-tangible-artefacts/` (see `.env.example`) for environment variables, including database connection strings and external service API keys.
- **MySQL:** The backend services connect to a MySQL database. Schema can be initialized from `mysql_schema.sql`.
- **TURN server:** Configuration files `turnserver.local.conf` and `turnserver.server.conf` are provided for the coturn TURN server.

## Key Conventions

- **Naming:** Follows standard conventions for C# (.NET), Dart (Flutter), and TypeScript/Vue.
- **Branching:** `dev-main` is the primary development branch. Features are developed on separate branches and merged into `dev-main`. `main` is reserved for stable releases.

## Testing Commands

- **.NET:** `dotnet test` (uses xUnit, configured with Testcontainers for integration tests).
- **Flutter:** `flutter test` for unit/widget tests, `flutter test integration_test/` for integration tests.

## Important Files and Entry Points

- `visual-tangible-artefacts/Backend/VTA.API/Program.cs`: Backend API entry point and service configuration.
- `visual-tangible-artefacts/Backend/SyncService/Program.cs`: Backend SyncService entry point.
- `visual-tangible-artefacts/Frontend/vta_app/lib/main.dart`: Flutter application entry point.
- `visual-tangible-artefacts/Frontend/admin-dashboard/src/main.ts`: Admin dashboard entry point.
- `visual-tangible-artefacts/VTA.sln`: Visual Studio solution file for the backend.
- `visual-tangible-artefacts/docker-compose.yml`: Docker setup for development environment.