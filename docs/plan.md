# VTA Documentation Plan & Progress

> Revised 2025-02-07. Single source of truth.

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

### Phase I: Flutter UI Widgets — PARTIAL
- [x] **Cards:** add_item_popup, option_wheel, talking_mat, linear_board, board_artifact, categories_widget, addPicture, caregiver_request_widget, text_to_speech_widget
- [ ] `summary_simple_widgets.md` (~10 simple widget files)

### Phase J: Flutter UI Screens & Views
- [ ] **Cards:** video_call_screen, artifact_board_screen, incomming_call_screen, remote_board_screen, remote_session_screen, calling_screen
- [ ] **Card:** login_view (check if deprecated first)
- [ ] `summary_simple_screens.md` (6 simple screen files)

### Phase K: Flutter Remaining
- [ ] `summary_settings.md` (3 files)
- [ ] `summary_notifiers_shared_functions.md` (~4 files)
- [ ] `summary_localization.md` (2 files)
- [ ] `summary_root_theme.md` (~6 files: main, app, examples, theme)

### Phase L: Admin Dashboard
- [ ] **Cards:** router/index.ts, store/auth.ts, OverviewView.vue, PairingsView.vue
- [ ] `summary_admin_dashboard.md` (25 simple files)

---

## Step 3: Feature Diagrams
- [ ] Authentication
- [ ] Artifact Management
- [ ] Board System
- [ ] Real-time Collaboration
- [ ] Video Calling
- [ ] Text-to-Speech
- [ ] Admin Panel
- [ ] Data Sync
- [ ] Settings & User Management

## Step 4: Dependency Map
- [ ] docs/architecture/dependency_map.md

## Step 5: Architecture Overview
- [ ] docs/architecture/overview.md

## Step 6: Master Index
- [ ] docs/_index.md

---

## Deferred
- Phase M: Tests documentation
- Phase N: Infrastructure documentation
