# Backend setup
To be made at a later stage




# Backend folder structure
This section show the folder structure with some infomation on the files

```
Backend/
├── SyncService/                 # Real-time service (ASP.NET Core 8)
│   ├── Hubs/
│   │   └── BoardHub.cs         # SignalR hub (board sync + WebRTC signaling)
│   ├── Models/                  # Hub-specific models
│   │   ├── ArtifactAdded/      # Real-time artifact event payloads
│   │   ├── BoardSession.cs     # Active session tracking
│   │   ├── PendingSessionRequest.cs
│   │   └── UserInfo.cs         # Connected user info
│   └── Program.cs              # Startup: SignalR, JWT for WebSocket auth
│
│
├── SyncService.Tests/           # SyncService tests (xUnit)
│    ├── Helpers/
│    └── IntegrationTests/
│
│
├── VTA.API/                     # REST API (ASP.NET Core 8 Web API)
│   ├── Controllers/             # 11 API controllers
│   │   ├── AdminController.cs       # Admin-only operations
│   │   ├── ArtefactsController.cs   # Artifact CRUD + TTS generation
│   │   ├── AssetsController.cs      # Image/sound file serving
│   │   ├── BoardsController.cs      # Board CRUD
│   │   ├── CategoriesController.cs  # Category management
│   │   ├── ContactsController.cs    # Contact list management
│   │   ├── MigrationController.cs   # Data migration utilities
│   │   ├── RelationController.cs    # Caregiver-child linking
│   │   ├── SavedArtefactsController.cs # Board artifact placement
│   │   ├── SyncController.cs        # Offline sync endpoints
│   │   └── UsersController.cs       # Auth (login/signup) + user CRUD
│   ├── DTOs/                    # Data transfer objects + converter
│   ├── Extensions/
│   │   └── WebApplicationExtensions.cs
│   ├── Program.cs              # Startup: JWT, Swagger, CORS, DI
│   ├── Services/                # Business logic layer (Controller → Service → Data)
│   │   ├── ArtefactService.cs      # Artefact business logic implementation
│   │   ├── BoardService.cs         # Board business logic implementation
│   │   ├── IArtefactService.cs     # Artefact CRUD + asset management interface
│   │   ├── IBoardService.cs        # Board CRUD + layout management interface
│   │   ├── IImageService.cs        # Image file operations interface
│   │   ├── ImageService.cs         # Wraps ImageUtilities as injectable service
│   │   ├── IRelationService.cs     # Pairing CRUD + contact queries interface
│   │   ├── ISoundService.cs        # Sound file operations interface
│   │   ├── ITtsService.cs          # TTS generation interface
│   │   ├── IUserService.cs         # Auth, registration, user deletion interface
│   │   ├── RelationService.cs      # Pairing/contacts implementation
│   │   ├── SoundService.cs         # Wraps SoundUtilities as injectable service
│   │   ├── TtsService.cs           # ElevenLabs-backed TTS implementation
│   │   └── UserService.cs          # User management implementation
│   └── Utilities/
│       ├── ElevenLabsService.cs    # TTS via ElevenLabs API
│       ├── ImageUtilities.cs       # Image processing
│       ├── MigrationService.cs     # Data migration logic
│       ├── SecretsProvider.cs      # Singleton secrets store
│       └── SoundUtilities.cs       # Sound file handling
│
│
├── VTA.Data/                    # Shared data layer (class library)
│   ├── DbContexts/
│   │   ├── Configurations/     # 7 entity type configurations
│   │   └── VTAContext.cs        # Main EF Core DbContext
│   ├── Extensions/
│   │   └── DbContextExtensions.cs  # DI registration + migration helper
│   └── Models/                  # EF Core entity models (DB-first)
│       ├── Artefact.cs         # Core artifact entity (image + sound)
│       ├── CallStatus.cs       # Video call status enum
│       ├── Category.cs         # Artifact categories
│       ├── Relation.cs         # Caregiver-child relationships
│       ├── SavedArtefact.cs    # Artifacts placed on boards
│       ├── SavedBoard.cs       # Saved board configurations
│       ├── Session.cs          # Active collaboration sessions
│       ├── User.cs             # User entity
│       └── UserRole.cs         # Role enum (Admin, Caregiver, Child)
│
│
└── VTA.Tests/                   # API tests (xUnit + Testcontainers)
    ├── IntegrationTests/       # Full HTTP pipeline tests
    ├── TestHelpers/            # CustomApplicationFactory, test utilities
    └── UnitTests/              # Isolated unit tests
```