# Improvement Proposals

> Consolidated architectural concerns identified during Step 3 (Feature-Level Interaction Diagrams).
> Each proposal references the feature doc(s) where it was first identified.
> Severity legend: 🔴 Critical · 🟠 High · 🟡 Medium · 🟢 Low

---

## Table of Contents

1. [God Classes](#1-god-classes)
2. [Missing Backend Service Layer](#2-missing-backend-service-layer)
3. [Duplicated Logic](#3-duplicated-logic)
4. [Security & Authentication](#4-security--authentication)
5. [Scalability & Reliability](#5-scalability--reliability)
6. [Tight Coupling & DI Patterns](#6-tight-coupling--di-patterns)
7. [Logging & Observability](#7-logging--observability)
8. [Data Consistency](#8-data-consistency)

---

## 1. God Classes

Several files far exceed reasonable single-responsibility boundaries.

| File | Lines | Feature Doc | What It Does |
|------|-------|-------------|-------------|
| `RemoteArtifactBoardController` | 1,209 | [Real-time Collaboration](features/realtime_collaboration.md) | SignalR event dispatch + board state + UI coordination |
| `SyncService` (Dart) | 1,009 | [Data Sync](features/data_sync.md) | API calls + file I/O + DB ops + conflict resolution + asset downloading |
| `ArtefactsController.cs` | 795 | [Artifact Management](features/artifact_management.md) | CRUD + image resize + sound conversion + TTS + category management |
| `BoardsController.cs` | 759 | [Board System](features/board_system.md) | Board CRUD + saved artefact management + layout duplication |
| `BoardHub.cs` | 584 | [Real-time Collaboration](features/realtime_collaboration.md) | SignalR hub + session state + WebRTC signaling + pairing validation |
| `SignalRService` (Dart) | 532 | [Real-time Collaboration](features/realtime_collaboration.md) | Connection management + all event handlers |
| `UsersController.cs` | 458 | [Authentication](features/authentication.md), [Settings](features/settings_user_mgmt.md) | Auth + CRUD + contacts + settings + JWT generation |

### Proposal

**Split each god class** along responsibility boundaries:

- `ArtefactsController` → `ArtefactCrudController` + `ArtefactAssetController` + `ArtefactTtsController`
- `SyncService` → `SyncDownloader` + `SyncUploader` + `SyncConflictResolver` + `AssetDownloadManager`
- `RemoteArtifactBoardController` → `RemoteBoardStateManager` + `RemoteBoardEventHandler` + `RemoteBoardUICoordinator`
- `BoardHub` → Extract session management into `BoardSessionManager`, WebRTC signaling into `SignalingRelay`
- `UsersController` → `AuthController` + `UserCrudController` + `UserSettingsController`

---

## 2. Missing Backend Service Layer

**Severity: 🔴 Critical**

All backend controllers inject `VTAContext` (EF Core DbContext) directly and contain business logic inline. There is **no service layer**.

**Impact:**
- Business rules embedded in HTTP handlers cannot be reused
- Unit testing requires spinning up the full ASP.NET pipeline
- Domain logic is scattered across controllers that overlap (e.g., pairing validation in both `AdminController` and `RelationController`)

### Proposal

Introduce service classes with interfaces:

```
Controllers/           → HTTP concerns only (model binding, auth, response codes)
Services/
  IArtefactService     → Artefact CRUD, image processing
  IBoardService        → Board CRUD, layout management
  IUserService         → Auth, user CRUD, settings
  IRelationService     → Pairing CRUD (single source of truth)
  ISyncService         → Change tracking queries
  ITtsService          → ElevenLabs integration
```

Register via DI: `builder.Services.AddScoped<IArtefactService, ArtefactService>();`

---

## 3. Duplicated Logic

| What's Duplicated | Where | Feature Doc | Severity |
|-------------------|-------|-------------|----------|
| **Pairing CRUD** | `AdminController` (9 lines, filters IsActive, anonymous DTOs) vs `RelationController` (different DTOs, returns all) | [Admin Panel](features/admin_panel.md) | 🔴 |
| **Contacts endpoint** | `ContactsController.GetContacts()` vs `UsersController.GetRelatedContacts()` — nearly identical role-based lookup | [Settings](features/settings_user_mgmt.md) | 🟠 |
| ~~**User deletion**~~ | ✅ Resolved | [Admin Panel](features/admin_panel.md) | Fixed in Phase 1.4 — shared `UserCleanupHelper.DeleteUserWithAssets()` used by both controllers. |
| ~~**TTS API calls (dual path)**~~ | ✅ Resolved | [Text-to-Speech](features/text_to_speech.md) | Fixed in Phase 1.5 — Flutter TTS now proxies through backend only. 4 overlapping backend endpoints remain (Phase 2 target). |
| **Auth token management** | Flutter `Token` singleton vs `AuthModel` vs `functions/auth.dart` (legacy) — three parallel auth representations | [Authentication](features/authentication.md) | 🟡 |

### Proposal

- **Pairings:** Delete `AdminController` pairing methods. Have admin dashboard call `RelationController` exclusively. Add `IsActive` filtering as an optional query parameter.
- **Contacts:** Delete one endpoint. Recommend keeping `ContactsController` and removing `UsersController.GetRelatedContacts()`.
- ~~**User deletion:**~~ ✅ Done (Phase 1.4) — extracted into `UserCleanupHelper.DeleteUserWithAssets()`. Both controllers use it.
- ~~**TTS:**~~ ✅ Done (Phase 1.5) — client-side ElevenLabs removed. All TTS goes through backend.
- **Auth:** Remove `functions/auth.dart`. Consolidate on `Token` + `UserInfo` singletons.

---

## 4. Security & Authentication

| Concern | Severity | Feature Doc | Detail |
|---------|----------|-------------|--------|
| ~~**Mock auth bypass in admin dashboard**~~ | ✅ Resolved | [Admin Panel](features/admin_panel.md) | Fixed in Phase 1.3 — mock token block deleted from `store/auth.ts`. Real API login now executes. |
| ~~**ElevenLabs API key on client device**~~ | ✅ Resolved | [Text-to-Speech](features/text_to_speech.md) | Fixed in Phase 1.5 — Flutter TTS now proxies through backend. API key removed from client. `ElevenLabsConfig` stores only voice-ID preferences. |
| **Hardcoded TURN server credentials** | 🟠 | [Video Calling](features/video_calling.md) | `WebRTCService` has `username: 'user'`, `credential: 'pass'` in source code. |
| **JWT secret in appsettings.json** | 🟠 | [Authentication](features/authentication.md) | Signing key committed to source control. Should use environment variables or secret manager. |
| **30-day token expiry, no refresh** | 🟡 | [Authentication](features/authentication.md) | Long-lived tokens with no refresh mechanism. Compromise has a wide blast radius. |
| **`GetUsers` returns all users** | 🟡 | [Settings](features/settings_user_mgmt.md) | Any authenticated user can list all users. No role-based filtering. |
| **PUT user accepts raw entity** | 🟡 | [Settings](features/settings_user_mgmt.md) | `PutUser` binds a full `User` entity — overposting risk (role, password hash). |

### Proposal

1. ~~**Admin mock auth:**~~ ✅ Done (Phase 1.3) — mock block deleted.
2. ~~**API keys:**~~ ✅ Done (Phase 1.5) — all TTS proxied through backend, client key storage removed.
3. **TURN creds:** Move to environment config, loaded at runtime.
4. **JWT secret:** Use `dotnet user-secrets` in dev, environment variables in production.
5. **Token refresh:** Implement short-lived access tokens (15 min) + refresh tokens.
6. **Endpoint access:** Add `[Authorize(Roles = "Admin")]` to `GetUsers` or scope to related users only.
7. **PUT overposting:** Replace with a `UserUpdateDTO` that excludes `Role`, `PasswordHash`, `Id`.

---

## 5. Scalability & Reliability

| Concern | Severity | Feature Doc | Detail |
|---------|----------|-------------|--------|
| **BoardHub uses static mutable state** | 🔴 | [Real-time Collaboration](features/realtime_collaboration.md) | `static ConcurrentDictionary` for sessions — not shared across server instances. Blocks horizontal scaling. |
| **No pagination anywhere** | 🟠 | [Admin Panel](features/admin_panel.md), [Data Sync](features/data_sync.md), [Artifact Management](features/artifact_management.md) | All list endpoints return complete result sets. |
| **SyncTimer: 30s interval, no backoff** | 🟠 | [Data Sync](features/data_sync.md) | Hammers the server every 30 seconds per device, even on failures or no connectivity. |
| **No retry logic on sync** | 🟠 | [Data Sync](features/data_sync.md) | Failed asset downloads/uploads silently dropped. No retry queue. |
| **No transaction safety in sync** | 🔴 | [Data Sync](features/data_sync.md) | Partial sync failure leaves local DB inconsistent. No rollback. |
| **Video call: single-peer only** | 🟡 | [Video Calling](features/video_calling.md) | Architecture assumes 1:1 calls. Group calls would need SFU. |

### Proposal

1. **BoardHub:** Move session state to Redis. Use SignalR's Redis backplane (`AddStackExchangeRedis`).
2. **Pagination:** Add `skip`/`take` parameters to all list endpoints. Return `X-Total-Count` header.
3. **SyncTimer:** Implement exponential backoff (30s → 60s → 120s → ...) on failure. Check `Connectivity` before attempting.
4. **Retry queue:** Use a local queue (SQLite table) for failed uploads. Process on next successful sync.
5. **Transactions:** Wrap each entity sync in a SQLite transaction. Commit only on full success.

---

## 6. Tight Coupling & DI Patterns

| Concern | Severity | Feature Doc | Detail |
|---------|----------|-------------|--------|
| **CallManager coupled to `MyApp` widget** | 🟠 | [Video Calling](features/video_calling.md) | Calls `MyApp.navigatorKey.currentState!.push()` — direct widget tree coupling. |
| **Singletons via GetIt + manual construction** | 🟡 | [Data Sync](features/data_sync.md), [Authentication](features/authentication.md) | `SyncService` constructor does `?? GetIt.instance.get<>()` for 8 dependencies. Mix of constructor injection and service locator. |
| **Multiple singleton patterns** | 🟡 | Various | `SyncTimer` uses factory constructor pattern, `RemoteSyncService` uses `._()` + `static final`, `Token`/`UserInfo` use GetIt registration. Three different singleton styles. |
| **Flutter state: Provider + ChangeNotifier + ValueNotifier** | 🟡 | Various | Three state management patterns coexist. Inconsistent for new developers. |

### Proposal

1. **Navigation:** Use a `NavigationService` registered in GetIt instead of accessing `MyApp.navigatorKey`.
2. **DI consistency:** Standardise on GetIt constructor injection everywhere. Remove optional fallbacks (`?? GetIt.I.get<>()`).
3. **Singleton style:** Pick one pattern (recommend GetIt `registerSingleton`) and migrate all singletons.
4. **State management:** Gradually consolidate on one pattern (recommend `ChangeNotifier` + `Provider` since it's already dominant).

---

## 7. Logging & Observability

| Concern | Severity | Feature Doc | Detail |
|---------|----------|-------------|--------|
| **~40 `Console.WriteLine` in SyncController** | 🟠 | [Data Sync](features/data_sync.md) | Production debug logging via stdout. |
| **`print()` throughout Flutter** | 🟡 | Multiple | SyncService, SyncTimer, UserRepository, etc. all use `print()` instead of a logging framework. |
| **Empty catch blocks in SettingsService** | 🟡 | [Settings](features/settings_user_mgmt.md) | Exceptions swallowed silently. |
| **No structured logging** | 🟡 | All | Backend has `ILogger` injected in some controllers but `Console.WriteLine` in others. No consistent pattern. |

### Proposal

1. **Backend:** Replace all `Console.WriteLine` with `ILogger` calls. Configure Serilog or built-in logging with structured output.
2. **Flutter:** Adopt the `logging` package or `logger` package. Remove all `print()` calls.
3. **Error handling:** Replace empty catch blocks with proper error logging and user-facing error states.

---

## 8. Data Consistency

| Concern | Severity | Feature Doc | Detail |
|---------|----------|-------------|--------|
| ~~**`AdminController.DeleteUser` orphans assets**~~ | ✅ Resolved | [Admin Panel](features/admin_panel.md) | Fixed in Phase 1.4 — both controllers now use shared `UserCleanupHelper.DeleteUserWithAssets()`. |
| **Soft delete vs. hard delete inconsistency** | 🟡 | [Admin Panel](features/admin_panel.md) | `AdminController.DeletePairing` does soft delete (`IsActive = false`). `RelationController.RemovePairing` does hard delete (`Relations.Remove()`). |
| **`FileType` as string, not enum** | 🟡 | [Data Sync](features/data_sync.md) | `FileChangeDTO.FileType` is a raw string. Typo risk between "artefact" and "artifact". |
| **Anonymous DTOs in AdminController** | 🟡 | [Admin Panel](features/admin_panel.md) | `GetPairings` returns `Select(p => new { ... })` instead of a typed DTO. |
| **Profile picture local-only** | 🟡 | [Settings](features/settings_user_mgmt.md) | Profile images stored as base64 in SharedPreferences. Lost on device switch. |

### Proposal

1. ~~**Unified delete:**~~ ✅ Done (Phase 1.4) — `UserCleanupHelper.DeleteUserWithAssets()` handles cascade cleanup for both controllers.
2. **Delete strategy:** Decide project-wide: soft delete everywhere (recommended for audit trail) or hard delete everywhere. Currently mixed.
3. **Enums:** Replace string `FileType` with a C# enum and serialise as string via `[JsonConverter]`.
4. **DTOs:** Use typed DTOs for all API responses. Never return anonymous objects.
5. **Profile sync:** Add profile image upload to the backend (`/api/Users/profile-image`), store in the assets folder like artefact images.

---

## Priority Matrix

| Priority | Proposals | Estimated Effort |
|----------|-----------|-----------------|
| **P0 — Now** | ~~Mock auth bypass~~ ✅, ~~API key on client~~ ✅, ~~orphaned assets on admin delete~~ ✅, Board hub static state | Small–Medium (3/4 done) |
| **P1 — Next Sprint** | Backend service layer, god class splits, duplicate logic consolidation | Large |
| **P2 — Soon** | Pagination, sync reliability (backoff, retry, transactions), structured logging | Medium |
| **P3 — Backlog** | Token refresh, DI consistency, state management consolidation, profile picture sync | Medium–Large |
