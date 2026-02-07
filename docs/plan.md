# VTA Documentation Plan & Progress

> Revised 2026-02-07. Single source of truth.

## Approach

Document COMPLEX files individually (class cards). Group SIMPLE files into per-folder summaries. Then synthesize feature diagrams and architecture docs.

| Component | Source Files | Complex Cards | Summary Docs | Done |
|-----------|-------------|---------------|-------------|------|
| Backend | 54 | 53 (done) | — | ✅ |
| Flutter | 119 | 33 done + 11 remaining | 8 done + 4 remaining | partial |
| Admin | 29 | 4 remaining | 1 remaining | ❌ |

---

## Step 2: Per-Class Documentation

### Phases A–C: Backend — DONE
- [x] Phase A: VTA.Data (18 cards)
- [x] Phase B: VTA.API (27 cards)
- [x] Phase C: SyncService (8 cards)

### Phase D: Flutter Database Layer — DONE
- [x] database/models/ (7 cards)
- [x] database/repositories/ (8 cards)
- [x] database/ root (3 cards)
- [x] `summary_database_mappers.md` (1 file)

### Phase E: Flutter Models & DTOs — DONE
- [x] **Cards:** artefact_model, auth_model
- [x] `summary_models_simple.md` (board_layout, board_model, elevenlabs_model — data classes)
- [x] `summary_modelsDTOs.md` (9 simple DTO files)

### Phase F: Flutter Utilities & Singletons — DONE
- [x] **Cards:** api_provider, elevenlabs_service, data_repository
- [x] `summary_singletons.md` (2 trivial files)
- [x] `summary_utilities_audio.md` (7 files)
- [x] `summary_utilities_misc.md` (~7 files incl. elevenlabs_config — SharedPreferences wrapper, not complex)

### Phase G: Flutter Services — DONE
- [x] **Cards:** sync_service, signalr_service, webrtc_service, call_manager, board_layout_service
- [x] `summary_simple_services.md` (5 simple services)

### Phase H: Flutter Controllers — DONE
- [x] **Cards:** remote_artifact_board_controller, artifact_board_controller, artifact_controller, auth_controller, elevenlabs_controller, talkingmat_controller
- [x] `summary_simple_controllers.md` (board_controller — empty, linear_board_controller)

### Phase I: Flutter UI Widgets — COMPLETED
- [x] **Cards:** add_item_popup, option_wheel, talking_mat, linear_board, board_artifact, categories_widget, addPicture, caregiver_request_widget, text_to_speech_widget
- [x] `summary_simple_widgets.md` (~10 simple widget files)

### Phase J: Flutter UI Screens & Views — COMPLETED
- [x] **Cards:** video_call_screen, artifact_board_screen, incomming_call_screen, remote_board_screen, remote_session_screen, calling_screen
- [x] **Card:** login_view (check if deprecated first)
- [x] `summary_simple_screens.md` (6 simple screen files)

### Phase K: Flutter Remaining — DONE
- [x] `summary_settings.md` (3 files)
- [x] `summary_notifiers_shared_functions.md` (~4 files)
- [x] `summary_localization.md` (2 files)
- [x] `summary_root_theme.md` (~6 files: main, app, examples, theme)

### Phase L: Admin Dashboard — DONE
- [x] **Cards:** router/index.ts, store/auth.ts, OverviewView.vue, PairingsView.vue
- [x] `summary_admin_dashboard.md` (25 simple files)

---

## Step 3: Feature Diagrams — DONE ✅
- [x] Authentication → `docs/features/authentication.md`
- [x] Artifact Management → `docs/features/artifact_management.md`
- [x] Board System → `docs/features/board_system.md`
- [x] Real-time Collaboration → `docs/features/realtime_collaboration.md`
- [x] Video Calling → `docs/features/video_calling.md`
- [x] Text-to-Speech → `docs/features/text_to_speech.md`
- [x] Admin Panel → `docs/features/admin_panel.md`
- [x] Data Sync → `docs/features/data_sync.md`
- [x] Settings & User Management → `docs/features/settings_user_mgmt.md`
- [x] Overview index → `docs/features/_overview.md`
- [x] Improvement proposals → `docs/improvement_proposals.md`

## Step 4: Dependency Map — DONE ✅
- [x] docs/architecture/dependency_map.md — feature dependency graph, shared services heat map, 3 circular dependencies (1 compile-time, 2 runtime), backend coupling analysis, coupling hotspots

## Step 5: Architecture Overview — DONE ✅
- [x] docs/architecture/overview.md — architecture style, system diagram, layer diagram, navigation structure, state management, data flow, tech debt summary, glossary

## Step 6: Master Index — DONE ✅
- [x] docs/_index.md — links to all architecture, feature, class, and infrastructure docs

## Step 7: Verify Architecture Docs — DONE ✅
- [x] Cross-checked `docs/architecture/overview.md` against source code — fixed 3 incorrect route strings (`/splash`→`/`, `/artifact-board`→`/boardview`, `/remote-session`→`/remote`)
- [x] Cross-checked `docs/architecture/dependency_map.md` against source code — fixed `ElevenLabsService` DI claim (not registered, newed inline) and BoardHub collection types (`Dictionary<>` not `ConcurrentDictionary`)
- [x] Verified import counts (Token=19, SignalR=14, ApiProvider=14), all circular dependency chains, GetIt registrations (4), controller count (11), port mappings
- [x] Confirmed all cross-reference links between overview, dependency map, feature docs, and improvement proposals resolve correctly

---

## Deferred
- Phase M: Tests documentation

## Completed (formerly deferred)
- Phase N: Infrastructure documentation → [docs/architecture/infrastructure.md](architecture/infrastructure.md) ✅
