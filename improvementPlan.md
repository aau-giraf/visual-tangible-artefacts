# VTA Improvement Roadmap

> Concrete plan for stabilising the codebase before adding features.
> For detailed architectural analysis see `docs/improvement_proposals.md`.
> its KEY that you FIRST plan and then execute
> ensure that each logically clustered improvement is its own feature branch

## Status (7 Feb 2026)

| Phase | Status | Branch | Tests |
|-------|--------|--------|-------|
| Phase 1 — Stop the Bleeding | ✅ Merged to `dev-main` | `feature/phase1-stabilise` | 98/98 ✅ |
| Phase 2 — Backend Service Layer | ✅ Merged to `dev-main` | `feature/phase2-service-layer` | 98/98 ✅ |
| Phase 3 — God Class Splits | ✅ Completed | `feature/phase3-god-class-splits` | 25/25 + 98/98 + 13/13 ✅ |
| Phase 4 — Reliability & Observability | � In progress | `feature/phase4-logging` | — |
| Phase 5 — Backlog | 📋 Planned | — | — |

**Phase 3 progress:**
- ✅ **3.1 BoardHub.cs split** — Extracted 3 services (`PresenceService`, `SessionService`, `BoardSyncRelay`). Hub reduced from 584→290 LOC. All 25 SyncService tests + 98 VTA tests pass.
- ✅ **3.2 RemoteArtifactBoardController split** — Extracted `RemoteBoardSyncSender` (~310 LOC) and `RemoteBoardSyncReceiver` (~340 LOC). Controller reduced from 1,209→~290 LOC. All 13 Flutter tests pass.
- ✅ **3.3 SyncService split** — Extracted `SyncChangeDetector` (~234 LOC), `SyncDownloader` (~374 LOC), `SyncUploader` (~217 LOC), and `sync_models.dart` (~103 LOC). Orchestrator reduced from 1,009→~160 LOC. All 13 Flutter tests pass.
- ✅ **3.4 SignalRService split** — Extracted `SignalRConnectionManager` (~58 LOC), `SignalREventRouter` (~286 LOC), and `OnlineStatusTracker` (~47 LOC). Facade reduced from 532→~320 LOC. All 16 consumers unchanged. All 13 Flutter tests pass.

---

## Phase 1 — Stop the Bleeding (1–2 weeks) ✅ COMPLETED

Goal: CI catches real problems, tests pass, critical security holes are closed.


### 1.1 Fix the 14 failing backend tests ✅

**All 13 integration test failures share one root cause: a route conflict between `UsersController` and `BoardsController`.**

`UsersController` uses `[Route("api/[controller]")]` = `api/Users`.
`BoardsController` uses `[Route("api/Users/Boards")]`.

When a test POSTs to `/api/Users/Boards`, ASP.NET sees an ambiguous match — `UsersController` thinks `Boards` is a route parameter, and returns 405 MethodNotAllowed. Every test that calls `CreateBoard()` in the test helpers fails, and every test downstream of that fails with empty JSON deserialization errors.

**Fix:** Change the `BoardsController` route to something unambiguous (e.g. `[Route("api/boards")]`) and update tests + Flutter API calls to match. Alternatively, add explicit route constraints on `UsersController` to prevent the collision.

The 1 remaining unit test failure (`BoardArtefactLayoutDTO_DefaultValues_ShouldBeCorrect`) should pass on a clean `dotnet build && dotnet test` — the DTO defaults are correct in source, the test was run against a stale binary.

**Files to touch:**
- `Backend/VTA.API/Controllers/BoardsController.cs` — route attribute
- `Backend/VTA.API/Controllers/SavedArtefactsController.cs` — route attribute (if it also nests under `api/Users/`)
- `Backend/VTA.Tests/` — update any hardcoded URL strings in test helpers
- `Frontend/vta_app/` — update API URL paths in board-related model/service files
- `Frontend/admin-dashboard/` — update API URL paths if boards are admin-managed

### 1.2 Add Flutter and admin-dashboard CI jobs ✅

The CI workflow at `.github/workflows/dotnet-desktop.yml` only runs `dotnet test`. The Flutter app and admin dashboard have zero CI — broken builds can merge to `dev-main` undetected.

Add two jobs to the existing workflow:

**Flutter job:**
```yaml
flutter-ci:
  runs-on: ubuntu-latest
  defaults:
    run:
      working-directory: Frontend/vta_app
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.x'
    - run: flutter pub get
    - run: flutter analyze --fatal-infos
    - run: flutter test
```

**Admin dashboard job:**
```yaml
admin-ci:
  runs-on: ubuntu-latest
  defaults:
    run:
      working-directory: Frontend/admin-dashboard
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: '20'
    - run: npm ci
    - run: npm run build  # runs vue-tsc + vite build
```

**File to touch:** `.github/workflows/dotnet-desktop.yml`

### 1.3 Remove admin dashboard mock auth bypass ✅

The login function in `Frontend/admin-dashboard/src/stores/auth.ts` has a mock block (lines 14–21) that sets a fake token, marks the user as authenticated, and `return`s before ever calling the real API. The admin dashboard never actually authenticates.

```typescript
// This entire block must be deleted:
token.value = 'local-mock-token';
user.value = { id: 'local-user-id' };
isAuthenticated.value = true;
localStorage.setItem('token', token.value);
localStorage.setItem('user', JSON.stringify(user.value));
router.push('/dashboard');
return;
```

The real login logic already exists below it (lines 24–35) and will work once this block is removed.

**File to touch:** `Frontend/admin-dashboard/src/stores/auth.ts` — delete lines 14–21.

### 1.4 Fix admin user deletion orphaning assets ✅

`AdminController.DeleteUser()` calls `Users.Remove()` without cleaning up filesystem assets (images, sounds, board snapshots). Database rows cascade-delete via MySQL foreign keys, but files on disk are orphaned permanently.

`UsersController.DeleteUser()` (lines 310–370) already does this correctly — it eager-loads artefacts and boards, deletes images/sounds/snapshots from disk, then removes DB entities.

**Fix:** Extract the cascade-delete logic from `UsersController.DeleteUser()` into a shared static helper (or a service method — this seeds Phase 2), and call it from both controllers.

**Files to touch:**
- `Backend/VTA.API/Controllers/UsersController.cs` — extract delete logic
- `Backend/VTA.API/Controllers/AdminController.cs` — call shared delete logic

### 1.5 Stop exposing the ElevenLabs API key to client devices ✅

The Flutter app stores the ElevenLabs API key in `SharedPreferences` and calls `api.elevenlabs.io` directly from the user's device. The key is extractable.

The backend already has a working TTS proxy — `ElevenLabsService` in `Backend/VTA.API/Utilities/ElevenLabsService.cs` with endpoints on `ArtefactsController` (`GenerateSpeechSimple`, `GenerateSpeechAndSave`).

**Fix:** Rewrite Flutter's `ElevenLabsService` to call the backend TTS endpoints instead of `api.elevenlabs.io`. Remove the API key input UI and client-side key storage.

**Files to touch:**
- `Frontend/vta_app/lib/src/utilities/elevenlabs_service.dart` — rewrite to call backend
- `Frontend/vta_app/lib/src/utilities/config/elevenlabs_config.dart` — delete
- `Frontend/vta_app/lib/src/controllers/elevenlabs_controller.dart` — remove API key management
- `Frontend/vta_app/lib/src/ui/widgets/text_to_speech_widget.dart` — remove API key input UI

---

## Phase 2 — Backend Service Layer ✅

> **Architecture pattern:** Standard ASP.NET Core **Controller → Service → Data** layering.
> Controllers handle HTTP concerns only (routing, model binding, auth attributes, status codes).
> Services own business logic and `VTAContext`. Registered via `builder.Services.AddScoped<IService, Service>()`.
> `DTOConverter` stays static per project convention.

### Current state

All 8 services implemented and DI-registered in `Program.cs`. All controllers refactored to delegate to services.

### 2.1 Wire existing services into controllers ✅

Injected the three original services and deleted inline duplicates from 5 controllers.

| Service | Injected into | Replaced |
|---------|-------------|----------|
| `ITtsService` | `ArtefactsController` | 4× manual `ElevenLabsService` instantiation via service locator |
| `IRelationService` | `AdminController`, `RelationController`, `ContactsController` | 3-way duplicated pairing CRUD + 2× duplicated contact queries |
| `IUserService` | `UsersController`, `AdminController` | Duplicated auth/registration/JWT/deletion logic |

### 2.2 Create `IArtefactService` / `ArtefactService` ✅

Extracted CRUD and asset management from `ArtefactsController` (592 LOC → ~330 LOC controller + service).

**Methods extracted:**
- `GetArtefactsForUserAsync(userId)` — query by user
- `GetArtefactByIdAsync(artefactId, userId)` — single fetch scoped to user
- `CreateOrUpdateArtefactAsync(...)` — upsert logic, image/sound saving, GUID generation
- `PatchArtefactAsync(...)` — partial field updates + category image sync
- `DeleteArtefactAsync(artefactId, userId)` — entity removal + filesystem cascade
- `BulkUpdateNameShownAsync(userId, nameShown)` — batch update
- `GetArtefactForAudioAsync(artefactId, userId)` — for play-audio endpoint

**What stays in the controller:** `[FromForm]` model binding, `IFormFile` handling, `User.FindFirst("id")` extraction, `DTOConverter.MapArtefactToArtefactGetDTO(artefact, Request.Scheme, Request.Host)`, HTTP status code returns.

**Files touched:**
- `Services/IArtefactService.cs` — new interface (7 methods)
- `Services/ArtefactService.cs` — new implementation
- `Controllers/ArtefactsController.cs` — inject and delegate
- `Program.cs` — register `AddScoped<IArtefactService, ArtefactService>()`

### 2.3 Create `IBoardService` / `BoardService` ✅

Extracted board and layout logic from `BoardsController` (759 LOC → ~280 LOC controller) and unified shared logic from `SavedArtefactsController` (222 LOC → ~95 LOC controller). Both controllers now delegate to the same service.

**Methods extracted:**
- `GetBoardsForUserAsync(userId)` — full boards with navigation
- `GetBoardListAsync(userId)` — lightweight list
- `GetBoardAsync(boardId, userId)` — single board with artefacts
- `CreateBoardAsync(userId, name, artefacts?)` — simple or rich creation with transaction
- `UpdateBoardAsync(boardId, userId, name, artefacts)` — PUT semantics with transaction
- `PatchBoardAsync(boardId, userId, name?, snapshotPath?)` — partial updates
- `UpdateArtefactLayoutAsync(boardId, userId, request)` — upsert for BoardsController
- `UpdateSavedArtefactLayoutAsync(boardId, userId, request)` — strict PATCH for SavedArtefactsController
- `RemoveArtefactFromBoardAsync(boardId, savedArtefactId, userId)` — with JSON list rebuild
- `ClearBoardAsync(boardId, userId, deleteSessionArtefacts)` — unified clearing with optional Session-Artefact deletion
- `DeleteBoardAsync(boardId, userId)` — cascade delete

**Files touched:**
- `Services/IBoardService.cs` — new interface (11 methods)
- `Services/BoardService.cs` — new implementation
- `Controllers/BoardsController.cs` — inject `IBoardService`, replace `VTAContext`
- `Controllers/SavedArtefactsController.cs` — inject `IBoardService`, replace `VTAContext`
- `Program.cs` — register `AddScoped<IBoardService, BoardService>()`

### 2.4 Wrap static file-I/O utilities as injectable services ✅

Created thin injectable wrappers around existing static classes, enabling mockability in tests.

| Static class | New service | Status |
|-------------|-------------|--------|
| `ImageUtilities` | `IImageService` / `ImageService` | ✅ Registered in DI |
| `SoundUtilities` | `ISoundService` / `SoundService` | ✅ Registered in DI |

**Files touched:**
- `Services/IImageService.cs` — 2 methods (`AddImageAsync`, `DeleteImage`)
- `Services/ImageService.cs` — delegates to `ImageUtilities`
- `Services/ISoundService.cs` — 3 methods (2× `AddSoundAsync` overloads, `DeleteSound`)
- `Services/SoundService.cs` — delegates to `SoundUtilities`
- `Program.cs` — register both as `AddScoped`

**Keep static:** `DTOConverter` (pure functions, project convention) and `ElevenLabsService` (internal detail of `TtsService`, not directly consumed).

**Consider removing (future):** `SecretsProvider` singleton — partially dead, `IConfiguration` already serves its purpose.

### 2.5 Update documentation ✅

- Fixed JWT claim name in `.github/copilot-instructions.md`: `"userId"` → `"id"` (matches all actual code)
- Changed "No backend service layer" to describe the new `Services/` pattern
- Updated `Backend/CLAUDE-backend.md` to document the Controller → Service → Data layering and list all 16 service files

### Not in scope for Phase 2

| Item | Reason |
|------|--------|
| `CategoriesController` (355 LOC) service extraction | Lower priority — no duplication, can be done in Phase 3 alongside god-class splits |
| `SyncController` (253 LOC) — 35 `_context` calls | Phase 4 plans to rework SyncService entirely |
| `AssetsController` (68 LOC), `SettingsController` (55 LOC) | Already thin (<70 LOC), negligible refactoring value |

### Test strategy

All existing tests are HTTP integration tests via `CustomApplicationFactory` + Testcontainers. Service extraction **does not break any existing test** — tests hit HTTP endpoints, and services are auto-resolved by DI. Run `dotnet test Backend/VTA.Tests/` after each controller refactor to confirm.

## Phase 3 — God Class Splits (2–4 weeks)

Phase 2 already reduced the three backend controllers below 400 LOC. The remaining god classes are:

| File | LOC | Project | Test coverage |
|------|-----|---------|---------------|
| `BoardHub.cs` | 583 | SyncService | ✅ BoardHubTests (unit/integration) |
| `remote_artifact_board_controller.dart` | 1,209 | Flutter | ⚠️ Minimal (no direct tests) |
| `sync_service.dart` | 1,008 | Flutter | ⚠️ 1 test file, limited |
| `signalr_service.dart` | 531 | Flutter | ⚠️ None |

**Strategy:** Start with `BoardHub.cs` (backend, tested). Flutter splits follow in 3.2–3.4 with manual verification.

### 3.1 Split `BoardHub.cs` into focused services ✅ COMPLETED

Extract responsibility groups into injectable services. Hub stays as a thin dispatcher (~100 LOC).

| New service | Responsibility | Methods | ~Lines |
|-------------|---------------|---------|--------|
| `IPresenceService` / `PresenceService` | Connection↔user tracking, online status, contact notification | `RegisterUser`, `GetOnlineUsers`, `GetAllOnlineUserIds`, cleanup on disconnect | ~50 |
| `ISessionService` / `SessionService` | Session request/accept/reject/end, timeout, DB logging | `RequestSession`, `AcceptSession`, `RejectSession`, `EndSession`, session cleanup on disconnect | ~230 |
| `IBoardSyncRelay` / `BoardSyncRelay` | Relay board/artifact deltas to session peers | `ArtifactAdded`, `ArtifactRemoved`, `ArtifactMoved`, `ArtifactResized`, `LayoutChanged`, `FieldCountChanged`, `UpdateBoard` | ~155 |
| *(WebRTC relay stays in hub — only 3 methods, ~30 LOC)* | | | |

**State ownership:** `_connectedUsers`, `_userConnections`, `_connectionUserMap` → `PresenceService`. `_sessions`, `_pendingRequests` → `SessionService`.

**Key detail:** Services need `IHubContext<BoardHub>` or accept `IHubCallerClients`/`IGroupManager` as parameters since they can't inherit from `Hub`.

**Files to create:**
- `SyncService/Services/IPresenceService.cs` + `PresenceService.cs`
- `SyncService/Services/ISessionService.cs` + `SessionService.cs`
- `SyncService/Services/IBoardSyncRelay.cs` + `BoardSyncRelay.cs`
- `SyncService/Program.cs` — register 3 services

**Files to modify:**
- `SyncService/Hubs/BoardHub.cs` — inject services, delegate
- `SyncService.Tests/` — update test setup if constructor changes

### 3.2 Split `RemoteArtifactBoardController` (Flutter, 1,209 LOC) ✅ COMPLETED

Extracted outbound and inbound sync logic into separate classes. Controller reduced to ~290 LOC orchestrator.

| New class | Responsibility | ~Lines |
|-----------|---------------|--------|
| `RemoteBoardSyncSender` | Serialize & push deltas/snapshots to SignalR (`_push*` methods, `_buildBoardSnapshot`) | ~250 |
| `RemoteBoardSyncReceiver` | Deserialize & apply incoming SignalR events (`_handle*` methods) | ~400 |

**Files to create:**
- `lib/src/services/remote_board_sync_sender.dart`
- `lib/src/services/remote_board_sync_receiver.dart`

**Files to modify:**
- `lib/src/controllers/remote_artifact_board_controller.dart` — inject sender + receiver, delegate

### 3.3 Split `SyncService` (Flutter, 1,008 LOC) ✅ COMPLETED

Extracted change detection, downloading, and uploading into focused classes. Orchestrator reduced to ~160 LOC.

| New class | Responsibility | ~Lines |
|-----------|---------------|--------|
| `SyncChangeDetector` | Query API/local DB for change records | ~180 |
| `SyncDownloader` | Download entities + assets from API to local SQLite | ~280 |
| `SyncUploader` | Upload entities + assets from local DB to API | ~200 |
| `sync_models.dart` | Extract inline `FileChangeRecord` + `SyncCheckResponse` model classes | ~116 |

**Files to create:**
- `lib/src/services/sync_change_detector.dart`
- `lib/src/services/sync_downloader.dart`
- `lib/src/services/sync_uploader.dart`
- `lib/src/models/sync_models.dart`

**Files to modify:**
- `lib/src/services/sync_service.dart` — thin orchestrator

### 3.4 Split `SignalRService` (Flutter, 531 LOC) ✅ COMPLETED

Decomposed the monolithic singleton into focused services. Facade preserved identical public API for all 16 consumers.

| New class | Responsibility | ~Lines |
|-----------|---------------|--------|
| `SignalRConnectionManager` | Hub connection lifecycle (connect/disconnect/reconnect, URL) | ~80 |
| `SignalREventRouter` | The 150-line `_registerEvents()` — all `.on()` handler registrations | ~160 |
| `OnlineStatusTracker` | Track/refresh/query online users | ~40 |

Session API, board sync API, and WebRTC relay methods stay in `SignalRService` (they're thin invoke wrappers, ~30 LOC each).

**Files to create:**
- `lib/src/services/signalr_connection_manager.dart`
- `lib/src/services/signalr_event_router.dart`
- `lib/src/services/online_status_tracker.dart`

**Files to modify:**
- `lib/src/services/signalr_service.dart` — delegate to extracted classes

## Phase 4 — Reliability & Observability

### 4.1 Replace `Console.WriteLine` with `ILogger` in backend (91 occurrences) ⬜

Inject `ILogger<T>` into the 7 files that use `Console.Write*`. Map each call to the appropriate log level (`LogInformation`, `LogWarning`, `LogError`). Wire up the 3 services that already have `ILogger` injected but don't use it.

| File | Count | Notes |
|------|-------|-------|
| `SyncController.cs` | 35 | Sync endpoint debug logging |
| `MigrationService.cs` | 21 | Schema migration progress |
| `BoardHub.cs` | 20 | Already uses `[Hub]` prefix convention |
| `ElevenLabsService.cs` | 9 | TTS API call logging |
| `CategoriesController.cs` | 1 | |
| `WebApplicationExtensions.cs` | 1 | |
| `DbContextExtensions.cs` | 1 | |
| Unused `ILogger` fields | 3 services | `PresenceService`, `SessionService`, `BoardSyncRelay` — injected but never called |

### 4.2 Replace `print()`/`debugPrint()` with `package:logging` in Flutter (334+ calls) ⬜

Use Dart SDK built-in `package:logging`. Create a shared `AppLogger` utility with named loggers per file. Replace all `print()`/`debugPrint()` calls. Remove `// ignore_for_file: avoid_print` directives.

### 4.3 Fix 28 empty catch blocks in Flutter ⬜

Add `logger.warning()`/`logger.severe()` calls inside all 28 empty `catch` blocks across 8 files. Dispose/cleanup catches → `logger.fine()`. Silenced real errors → `logger.severe()`.

### 4.4 Add sync retry logic and transaction safety ⬜

Create a `RetryHelper` utility with exponential backoff for HTTP calls. Apply in `sync_downloader.dart` and `sync_uploader.dart`. Wrap per-entity-type sync in SQLite batch transactions. Change `syncFromServer` return type from `bool` to a `SyncResult` with error details.

### 4.5 Add backend pagination to list endpoints ⬜

Add `skip`/`take` query params with sensible defaults (e.g., `take=50`) to admin user listings, artefact listing, board listing, and sync endpoints. Add `PaginatedResponse<T>` DTO with `items`, `totalCount`, `skip`, `take`. Backward-compatible — callers that don't pass params get the default page size.

## Phase 5 — Backlog

- Token refresh flow
- DI consistency in Flutter
- State management consolidation
- Profile picture sync to backend
- Redis backplane for SyncService (only when horizontal scaling is needed)

## Deferred

Items that are planned but not yet scheduled into a phase:

- **Flutter pagination support** — Update `ApiProvider` and sync callers to pass `skip`/`take` params, add infinite scroll to list views
- **Admin dashboard pagination** — Update admin API modules to use paginated endpoints, add pagination UI components
- **Sync endpoint batching (client)** — Batch large sync payloads into pages to avoid timeouts on large datasets
