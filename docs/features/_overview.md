# Feature-Level Documentation — Overview

> Generated as part of **Step 3: Feature-Level Interaction Diagrams** from [plan.md](../plan.md).
> Each doc contains a summary, Mermaid class diagram (public API surface), sequence diagrams, and architectural concerns.

---

## Feature Index

| # | Feature | Doc | Key Components |
|---|---------|-----|---------------|
| 1 | **Authentication** | [authentication.md](authentication.md) | `UsersController` (login/signup, JWT), Flutter `AuthModel`/`AuthController`, admin `auth.ts` store |
| 2 | **Artifact Management** | [artifact_management.md](artifact_management.md) | `ArtefactsController` (795 LOC), `CategoriesController`, `AssetsController`, Flutter `ArtefactController` |
| 3 | **Board System** | [board_system.md](board_system.md) | `BoardsController` (759 LOC), `SavedArtefactsController`, Flutter `ArtifactBoardController`, `TalkingmatController`, `LinearBoardController` |
| 4 | **Real-time Collaboration** | [realtime_collaboration.md](realtime_collaboration.md) | `BoardHub` (SignalR, 584 LOC), Flutter `SignalRService` (532 LOC), `RemoteArtifactBoardController` (1,209 LOC) |
| 5 | **Video Calling** | [video_calling.md](video_calling.md) | Flutter `WebRTCService`, `CallManager`, `VideoCallManager`; backend `BoardHub` (WebRTC signaling relay) |
| 6 | **Text-to-Speech** | [text_to_speech.md](text_to_speech.md) | Backend `ElevenLabsService` + 4 TTS endpoints in `ArtefactsController`, Flutter `ElevenLabsController`/`ElevenLabsService` |
| 7 | **Admin Panel** | [admin_panel.md](admin_panel.md) | `AdminController`, `RelationController`, Vue 3 dashboard (7 views, 7 API modules) |
| 8 | **Data Synchronisation** | [data_sync.md](data_sync.md) | `SyncController` (4 endpoints), Flutter `SyncService` (1,009 LOC), `SyncTimer`, `SyncMetadataRepository` |
| 9 | **Settings & User Management** | [settings_user_mgmt.md](settings_user_mgmt.md) | `UsersController.PatchUser`, `ContactsController`, Flutter `SettingsController`/`SettingsService` |

---

## Cross-Cutting Concerns

A consolidated list of architectural improvement proposals is at [**improvement_proposals.md**](../improvement_proposals.md), covering:

- God classes (7 files > 450 LOC)
- Missing backend service layer
- Duplicated logic (pairings, contacts, user deletion, TTS)
- Security issues (mock auth, API key exposure, hardcoded credentials)
- Scalability gaps (static state, no pagination, aggressive polling)
- DI & state management inconsistency
- Logging & observability
- Data consistency

---

## Stack Summary

| Layer | Technology | State Management |
|-------|-----------|-----------------|
| **Backend API** | ASP.NET Core 8, EF Core, MySQL | — |
| **Backend Real-time** | SignalR (ASP.NET Core) | Static `ConcurrentDictionary` |
| **Flutter App** | Flutter 3.x, Dart | Provider + ChangeNotifier + ValueNotifier, GetIt DI |
| **Admin Dashboard** | Vue 3, Pinia, TypeScript, Axios | Pinia stores |
| **Infrastructure** | Docker Compose, COTURN (STUN/TURN), ElevenLabs API | — |
