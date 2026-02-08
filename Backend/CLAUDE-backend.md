# Backend — Claude Code Guide

## Solution Structure

```
Backend/
├── VTA.Data/                    # Shared data layer (class library)
│   ├── Models/                  # EF Core entity models (DB-first)
│   │   ├── Artefact.cs         # Core artifact entity (image + sound)
│   │   ├── Category.cs         # Artifact categories
│   │   ├── User.cs             # User entity
│   │   ├── UserRole.cs         # Role enum (Admin, Caregiver, Child)
│   │   ├── SavedBoard.cs       # Saved board configurations
│   │   ├── SavedArtefact.cs    # Artifacts placed on boards
│   │   ├── Relation.cs         # Caregiver-child relationships
│   │   ├── Session.cs          # Active collaboration sessions
│   │   └── CallStatus.cs       # Video call status enum
│   ├── DbContexts/
│   │   ├── VTAContext.cs        # Main EF Core DbContext
│   │   └── Configurations/     # 7 entity type configurations
│   └── Extensions/
│       └── DbContextExtensions.cs  # DI registration + migration helper
│
├── VTA.API/                     # REST API (ASP.NET Core 8 Web API)
│   ├── Controllers/             # 11 API controllers
│   │   ├── UsersController.cs       # Auth (login/signup) + user CRUD
│   │   ├── ArtefactsController.cs   # Artifact CRUD + TTS generation
│   │   ├── CategoriesController.cs  # Category management
│   │   ├── BoardsController.cs      # Board CRUD
│   │   ├── SavedArtefactsController.cs # Board artifact placement
│   │   ├── AssetsController.cs      # Image/sound file serving
│   │   ├── AdminController.cs       # Admin-only operations
│   │   ├── RelationController.cs    # Caregiver-child linking
│   │   ├── ContactsController.cs    # Contact list management
│   │   ├── SyncController.cs        # Offline sync endpoints
│   │   └── MigrationController.cs   # Data migration utilities
│   ├── Services/                # Business logic layer (Controller → Service → Data)
│   │   ├── ITtsService.cs          # TTS generation interface
│   │   ├── TtsService.cs           # ElevenLabs-backed TTS implementation
│   │   ├── IRelationService.cs     # Pairing CRUD + contact queries interface
│   │   ├── RelationService.cs      # Pairing/contacts implementation
│   │   ├── IUserService.cs         # Auth, registration, user deletion interface
│   │   ├── UserService.cs          # User management implementation
│   │   ├── IArtefactService.cs     # Artefact CRUD + asset management interface
│   │   ├── ArtefactService.cs      # Artefact business logic implementation
│   │   ├── IBoardService.cs        # Board CRUD + layout management interface
│   │   ├── BoardService.cs         # Board business logic implementation
│   │   ├── IImageService.cs        # Image file operations interface
│   │   ├── ImageService.cs         # Wraps ImageUtilities as injectable service
│   │   ├── ISoundService.cs        # Sound file operations interface
│   │   └── SoundService.cs         # Wraps SoundUtilities as injectable service
│   ├── DTOs/                    # Data transfer objects + converter
│   ├── Utilities/
│   │   ├── ElevenLabsService.cs    # TTS via ElevenLabs API
│   │   ├── ImageUtilities.cs       # Image processing
│   │   ├── SoundUtilities.cs       # Sound file handling
│   │   ├── MigrationService.cs     # Data migration logic
│   │   └── SecretsProvider.cs      # Singleton secrets store
│   ├── Extensions/
│   │   └── WebApplicationExtensions.cs
│   └── Program.cs              # Startup: JWT, Swagger, CORS, DI
│
├── SyncService/                 # Real-time service (ASP.NET Core 8)
│   ├── Hubs/
│   │   └── BoardHub.cs         # SignalR hub (board sync + WebRTC signaling)
│   ├── Models/                  # Hub-specific models
│   │   ├── BoardSession.cs     # Active session tracking
│   │   ├── PendingSessionRequest.cs
│   │   ├── UserInfo.cs         # Connected user info
│   │   └── ArtifactAdded/      # Real-time artifact event payloads
│   └── Program.cs              # Startup: SignalR, JWT for WebSocket auth
│
├── VTA.Tests/                   # API tests (xUnit + Testcontainers)
│   ├── IntegrationTests/       # Full HTTP pipeline tests
│   ├── UnitTests/              # Isolated unit tests
│   └── TestHelpers/            # CustomApplicationFactory, test utilities
│
└── SyncService.Tests/           # SyncService tests (xUnit)
    ├── IntegrationTests/
    └── Helpers/
```

## Build & Run

```bash
# Restore all projects
dotnet restore VTA.sln

# Run API (from repo root or Backend/VTA.API/)
dotnet run --project Backend/VTA.API        # http://localhost:5192

# Run SyncService
dotnet run --project Backend/SyncService    # http://localhost:5133

# Run tests (needs Docker for Testcontainers)
dotnet test Backend/VTA.Tests/
dotnet test Backend/SyncService.Tests/
```

## Key Patterns

- **Controller → Service → Data**: Controllers handle HTTP concerns only. Business logic lives in `Services/` classes registered via `AddScoped<IService, Service>()`. Services inject `VTAContext` directly.
- **DB-First**: Models scaffolded from MySQL via `dotnet ef dbcontext scaffold` using Pomelo.EntityFrameworkCore.MySql
- **JWT Auth**: Both API and SyncService validate the same JWT tokens (shared issuer/audience/secret)
- **SyncService auth**: JWT passed via `access_token` query parameter for SignalR WebSocket connections
- **Asset storage**: Images/sounds stored on disk in `Assets/` directory, served via AssetsController
- **Response compression**: Enabled on API for bandwidth optimization
- **Max upload**: 150 MB (Kestrel + FormOptions)

## Configuration

Settings come from `appsettings.json` or environment variables:
- `ConnectionStrings:DefaultConnection` — MySQL connection string
- `Secret:SecretKey` — JWT signing key (or `JWT_SECRET` env var)
- `AUTO_CREATE_DATABASE=true` — Triggers EF migration on startup (dev only)
