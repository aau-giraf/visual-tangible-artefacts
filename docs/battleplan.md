# Plan: Systematic Documentation of visual-tangible-artefacts

## Context

The visual-tangible-artefacts (VTA) repository is a monorepo containing a Flutter mobile app, a .NET 8 backend (REST API + SignalR real-time service), and a Vue 3 admin dashboard. The codebase has grown organically across multiple student semesters with no structured documentation beyond a README. Following the methodology in `codebase-documentation-guide.md`, we will systematically document every class/component file-by-file, then synthesize feature-level and architecture-level docs.

The guide was written for Flutter/Dart codebases. This project has 3 tech stacks, so each step is adapted accordingly.

---

## Pre-Step: Create CLAUDE.md

**File to create:** `visual-tangible-artefacts/CLAUDE.md`

Content will cover:
- Repository structure (Backend/, Frontend/vta_app/, Frontend/admin-dashboard/)
- Quick commands for each component (build, run, test)
- Architecture summary (3 services: VTA.API on :5192, SyncService on :5133, Flutter app)
- Environment setup (docker-compose, .env, MySQL, TURN server)
- Key conventions (naming, branching: dev-main -> main)
- Testing commands (.NET xUnit with Testcontainers, Flutter test, integration_test)
- Important files and entry points

This is created first so future Claude sessions working in this repo have proper context.

**Note:** The `.gitignore` currently excludes `CLAUDE.md`. We should remove that line so the CLAUDE.md gets committed with the docs.

---

## Step 0: Prepare docs/ Structure

Create the output directory tree:

```
visual-tangible-artefacts/docs/
├── classes/
│   ├── flutter/        # Per-class cards for Dart files
│   ├── backend/        # Per-class cards for C# files
│   └── admin/          # Per-component cards for Vue/TS files
├── features/           # Cross-stack feature diagrams
├── architecture/       # High-level architecture docs
└── _index.md           # Master index (generated last)
```

**Exclusions** (do not document):
- `*.g.dart`, `*.freezed.dart` (none present, but guard against)
- `build/`, `.dart_tool/`, `bin/`, `obj/`
- Platform boilerplate: `android/`, `ios/`, `macos/`, `linux/`, `windows/`, `web/` (Flutter platform dirs)
- `.git/`, `.idea/`, `.vscode/`, `.vite/`
- `node_modules/`, `package-lock.json`, `bun.lock`, `pubspec.lock`
- `Frontend/vta_app/assets/` (binary assets, not code)
- Test files documented separately in a dedicated section

---

## Step 1: Inventory Pass (COMPLETED)

**Goal:** Produced `docs/inventory.json` with a structured map of every class/type across all 3 stacks.

**Schema** (unified, with a `component` field):
```json
{
  "components": {
    "flutter": { "files": [...] },
    "backend": { "files": [...] },
    "admin": { "files": [...] }
  }
}
```

Each file entry follows the guide\'s schema adapted per language:
- **Dart**: classes, enums, mixins, extensions, extends, implements, mixins, methods, fields, internal_imports, notable_packages
- **C#**: classes, enums, interfaces, records, extends, implements, properties, methods, internal_imports, notable_packages
- **Vue/TS**: components, interfaces, enums, types, imports, notable_packages

**Processing order:** Backend VTA.Data -> Backend VTA.API -> Backend SyncService -> Flutter lib/ -> Admin src/

**File counts to process:**
- Flutter lib/: ~80 Dart files (excluding platform dirs, assets, generated)
- Backend: ~50 C# source files (excluding test projects)
- Admin: ~25 Vue/TS source files

---

## Step 2: Per-Class Documentation (folder-by-folder)

**Critical rule from guide:** Work ONE FOLDER at a time. Review output after each folder. Use `/clear` between folders if context gets long.

### Processing Order (dependencies-first)

#### Phase A: Backend VTA.Data (foundation layer)
1. `Backend/VTA.Data/Models/` (8 files: User, UserRole, Artefact, Category, SavedBoard, SavedArtefact, Relation, Session, CallStatus)
2. `Backend/VTA.Data/DbContexts/` (8 files: VTAContext + 7 configurations)
3. `Backend/VTA.Data/Extensions/` (1 file: DbContextExtensions)

#### Phase B: Backend VTA.API (depends on VTA.Data)
4. `Backend/VTA.API/DTOs/` (9 files including DTOConverter)
5. `Backend/VTA.API/Utilities/` (5 files: ImageUtilities, SoundUtilities, ElevenLabsService, MigrationService, SecretsProvider)
6. `Backend/VTA.API/Extensions/` (1 file: WebApplicationExtensions)
7. `Backend/VTA.API/Controllers/` (11 files - split into two passes if needed) (COMPLETED)
   - Pass 7a: UsersController, ArtefactsController, CategoriesController, BoardsController, SavedArtefactsController, AssetsController (COMPLETED)
   - Pass 7b: AdminController, RelationController, ContactsController, SyncController, MigrationController
8. `Backend/VTA.API/Program.cs` (1 file) (COMPLETED)

#### Phase B: Backend VTA.API (depends on VTA.Data) (COMPLETED)

#### Phase C: Backend SyncService (depends on VTA.Data) (COMPLETED)
9. `Backend/SyncService/Models/` (6 files: BoardSession, PendingSessionRequest, UserInfo, ArtifactAdded payloads) (COMPLETED)
10. `Backend/SyncService/Hubs/` (1 file: BoardHub - large, document thoroughly) (COMPLETED)
11. `Backend/SyncService/Program.cs` (1 file) (COMPLETED)

#### Phase D: Flutter Database Layer (foundation) (COMPLETED)
12. `Frontend/vta_app/lib/src/database/models/` (7 files: artefact_db, category_db, saved_board_db, saved_artefact_db, session_meta_db, sync_metadata_db, user_db) (COMPLETED)
13. `Frontend/vta_app/lib/src/database/repositories/` (8 files: artefact_repository, category_repository, relation_repository, saved_artefact_repository, saved_board_repository, session_meta_repository, sync_metadata_repository, user_repository) (COMPLETED)
14. `Frontend/vta_app/lib/src/database/` root (3 files: database.dart, database_helper.dart, database_debug_helper.dart) (COMPLETED)
15. `Frontend/vta_app/lib/src/database/mappers/` (1 file)

#### Phase E: Flutter Models & DTOs
16. `Frontend/vta_app/lib/src/modelsDTOs/` (9 files)
17. `Frontend/vta_app/lib/src/models/` (5 files: artefact_model, auth_model, board_model, board_layout, elevenlabs_model)

#### Phase F: Flutter Utilities & Singletons
18. `Frontend/vta_app/lib/src/singletons/` (2 files: token, user_info)
19. `Frontend/vta_app/lib/src/utilities/api/` (2-3 files: api_provider, elevenlabs_service)
20. `Frontend/vta_app/lib/src/utilities/audio/` (6 files: recorder variants, network_audio variants, artefact_sound_player)
21. `Frontend/vta_app/lib/src/utilities/config/` (2 files)
22. `Frontend/vta_app/lib/src/utilities/data/` (2 files: data_repository, ImageData)
23. `Frontend/vta_app/lib/src/utilities/` remaining (extensions, json, platform_utils, services/camera_service)

#### Phase G: Flutter Services
24. `Frontend/vta_app/lib/src/services/` (10 files - split into two passes)
    - Pass 24a: sync_service, sync_timer, remote_sync_service, board_layout_service, relation_service, notification_service
    - Pass 24b: signalr_service, webrtc_service, call_manager, video_call_manager

#### Phase H: Flutter Controllers
25. `Frontend/vta_app/lib/src/controllers/` (8 files)

#### Phase I: Flutter UI - Widgets
26. `Frontend/vta_app/lib/src/ui/widgets/board/` (11 files)
27. `Frontend/vta_app/lib/src/ui/widgets/categories/` (5 files)
28. `Frontend/vta_app/lib/src/ui/widgets/online_session/` + `video/` + `utilities/` + `text_to_speech_widget.dart` (5-6 files)

#### Phase J: Flutter UI - Screens & Views
29. `Frontend/vta_app/lib/src/ui/screens/` (12 files - split into two passes)
    - Pass 29a: login_screen, signup_screen, welcome_screen, artifact_board_screen, error_screen, take_picture_screen
    - Pass 29b: remote_board_screen, remote_session_screen, calling_screen, incomming_call_screen, video_call_screen, child_accept_session_screen
30. `Frontend/vta_app/lib/src/views/` (4 files: caregiver_dashboard_view, login_view, relational_board_view, splash_view)

#### Phase K: Flutter Remaining
31. `Frontend/vta_app/lib/src/settings/` (3 files)
32. `Frontend/vta_app/lib/src/notifiers/` + `shared/` + `functions/` + `localization/` (7 files)
33. `Frontend/vta_app/lib/` root (main.dart, app.dart, component_viewer.dart, example_board_usage.dart) + `theme/`

#### Phase L: Admin Dashboard
34. `Frontend/admin-dashboard/src/interfaces/` (8 files)
35. `Frontend/admin-dashboard/src/api/` (7 files including axios.ts)
36. `Frontend/admin-dashboard/src/store/` + `router/` (2 files)
37. `Frontend/admin-dashboard/src/views/` (7 files)
38. `Frontend/admin-dashboard/src/layouts/` + `components/` + root files (main.ts, App.vue) (4 files)

#### Phase M: Tests (documented separately)
39. `Backend/VTA.Tests/` (8 test files)
40. `Backend/SyncService.Tests/` (3 test files)
41. `Frontend/vta_app/test/` (4 files) + `integration_test/` (3 files)

#### Phase N: Infrastructure
42. Docker, CI/CD, DB schemas, TURN config (document as a single infrastructure pass)

**After each folder:** Spot-check 3-5 class cards against source. Mark done in `docs/progress.md`.

**Total: ~42 documentation passes** across all components.

---

## Step 3: Feature-Level Interaction Diagrams

**Goal:** Mermaid class diagrams + sequence diagrams per feature, cutting across all 3 stacks.

**Feature definitions** (9 features):

| Feature | Backend Files | Flutter Files | Admin Files |
|---------|--------------|---------------|-------------|\
| **Authentication** | UsersController (login/signup), Program.cs (JWT) | AuthModel, AuthController, login_screen, signup_screen, welcome_screen, artifact_board_screen, error_screen, take_picture_screen, remote_board_screen, remote_session_screen, calling_screen, incomming_call_screen, video_call_screen, child_accept_session_screen, caregiver_dashboard_view, login_view, relational_board_view, splash_view | auth.ts API, auth store, LoginView |
| **Artifact Management** | ArtefactsController, CategoriesController, AssetsController, ImageUtilities, SoundUtilities | ArtifactModel, ArtefactController, categories widgets, add_item_popup | (read-only via interfaces) |
| **Board System** | BoardsController, SavedArtefactsController | ArtifactBoardController, TalkingmatController, LinearBoardController, BoardModel, board widgets, artifact_board_screen, board_layout_service | - |
| **Real-time Collaboration** | SyncService/BoardHub, session models | RemoteArtifactBoardController, SignalRService, remote_board_screen, remote_session_screen, caregiver_request_widget | - |
| **Video Calling** | BoardHub (WebRTC signaling) | WebRTCService, CallManager, VideoCallManager, calling_screen, video_call_screen, incomming_call_screen | - |
| **Text-to-Speech** | ArtefactsController (TTS endpoints), ElevenLabsService | ElevenLabsController, ElevenLabsModel, elevenlabs_service, elevenlabs_config | - |
| **Admin Panel** | AdminController, RelationController | - | All admin views, api files, interfaces |
| **Data Sync** | SyncController | SyncService, SyncTimer, RemoteSyncService, database layer | - |
| **Settings & User Mgmt** | UsersController (PATCH), ContactsController | SettingsController, SettingsService, SettingsView, UserInfo singleton | UsersView |

Each feature gets `docs/features/{feature_name}.md` with:
1. Class diagram (Mermaid) showing cross-stack relationships
2. Sequence diagram for the primary user flow
3. Feature summary paragraph

---

## Step 4: Cross-Feature Dependencies

**Goal:** `docs/architecture/dependency_map.md`

Map which features depend on which:
- All features depend on Authentication
- Board System depends on Artifact Management
- Real-time Collaboration depends on Board System + Authentication
- Video Calling depends on Real-time Collaboration
- Text-to-Speech depends on Artifact Management
- Admin Panel depends on Authentication + Settings & User Mgmt
- Data Sync depends on Artifact Management + Board System

Identify shared services used across 3+ features (ApiProvider, Token singleton, VTAContext, SignalRService).

Flag circular dependencies, god classes, tight coupling.

---

## Step 5: Architecture Overview

**Goal:** `docs/architecture/overview.md`

Sections:
1. **Architecture Style** - Multi-tier client-server with real-time layer
2. **System Diagram** - Mermaid showing Flutter App <-> VTA.API <-> MySQL, Flutter App <-> SyncService (SignalR), Admin Dashboard <-> VTA.API, TURN server for WebRTC
3. **Layer Diagram** - UI -> Controllers -> Models/Services -> API/Database
4. **Navigation Structure** - Flutter app screen flow (Splash -> Login/Welcome -> Board/Remote)
5. **State Management** - Provider + ChangeNotifier + ValueNotifier (Flutter), Pinia (Vue)
6. **Data Flow** - Representative sequence: artifact creation end-to-end
7. **Tech Debt Summary** - Aggregated from all per-class notes
8. **Glossary** - Artefact, Board, TalkingMat, LinearBoard, SavedArtefact, Relation, Session, etc.

---

## Step 6: Master Index

**Goal:** `docs/_index.md` linking to everything, organized by:
1. Architecture overview
2. Dependency map
3. Features (links to each)
4. Classes grouped by component and folder
5. Tests summary
6. Infrastructure docs

---

## Verification

After each step:
- **Step 1:** Validate inventory counts match actual file counts
- **Step 2:** Spot-check 3-5 cards per folder against source code
- **Step 3:** Verify diagram class names match actual code
- **Step 4:** Cross-reference dependency claims against imports
- **Step 5:** Ensure architecture description matches what code actually does
- **Step 6:** Verify all links resolve to existing files

---

## Critical Files to Modify/Create

| File | Action |
|------|--------|
| `visual-tangible-artefacts/CLAUDE.md` | CREATE |
| `visual-tangible-artefacts/docs/` (entire tree) | CREATE |
| `visual-tangible-artefacts/docs/inventory.json` | CREATE (Step 1) |
| `visual-tangible-artefacts/docs/progress.md` | CREATE (Step 2) |
| `visual-tangible-artefacts/docs/classes/**/*.md` | CREATE (Step 2, ~170 files) |
| `visual-tangible-artefacts/docs/skipped_widgets.md` | CREATE (Step 2) |
| `visual-tangible-artefacts/docs/features/*.md` | CREATE (Step 3, 9 files) |
| `visual-tangible-artefacts/docs/architecture/dependency_map.md` | CREATE (Step 4) |
| `visual-tangible-artefacts/docs/architecture/overview.md` | CREATE (Step 5) |
| `visual-tangible-artefacts/docs/_index.md` | CREATE (Step 6) |

---

## Execution Notes

- Each Step 2 pass should be its own conversation turn or use `/clear` between passes
- The guide\'s "folder-by-folder approach is non-negotiable" - never batch multiple folders
- Read every source file before documenting - never infer from filenames alone
- Commit after each major step (Step 0, Step 1, after each Phase in Step 2, etc.)
- Total estimated documentation cards: ~170 across all components