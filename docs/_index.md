# VTA Documentation — Master Index

> Auto-generated index of all project documentation.  
> Last updated: 2025-06-24.

---

## Architecture

| Document | Description |
|----------|-------------|
| [Architecture Overview](architecture/overview.md) | System diagram, layers, navigation, state management, data flow, tech debt, glossary |
| [Dependency Map](architecture/dependency_map.md) | Feature dependency graph, shared-services heat map, circular dependencies, coupling hotspots |
| [Infrastructure](architecture/infrastructure.md) | Docker Compose, Dockerfiles, COTURN, database schemas, nginx, secrets |

---

## Features

| Document | Description |
|----------|-------------|
| [Features Overview](features/_overview.md) | 9-feature matrix with stack coverage |
| [Authentication](features/authentication.md) | Login, JWT, guardian-key pairing, admin bypass |
| [Artifact Management](features/artifact_management.md) | CRUD, categories, images, sounds |
| [Board System](features/board_system.md) | Board canvas, layout persistence, artefact placement |
| [Real-time Collaboration](features/realtime_collaboration.md) | SignalR sessions, board sync, lock management |
| [Video Calling](features/video_calling.md) | WebRTC, STUN/TURN, call lifecycle |
| [Text-to-Speech](features/text_to_speech.md) | ElevenLabs integration, audio playback |
| [Admin Panel](features/admin_panel.md) | Vue 3 dashboard, user/artefact management |
| [Data Sync](features/data_sync.md) | Offline-first, conflict resolution, sync metadata |
| [Settings & User Management](features/settings_user_mgmt.md) | User profile, preferences, guardian keys |

---

## Improvement Proposals

| Document | Description |
|----------|-------------|
| [Improvement Proposals](improvement_proposals.md) | 8 proposals (P0–P3): secret management, DI cleanup, concurrency, error handling, auth hardening, sync conflicts, test coverage, admin security |

---

## Class Documentation

### Backend — VTA.API  (45 cards)

| Card | Source File |
|------|------------|
| [AdminController](classes/backend/AdminController.md) | `Controllers/AdminController.cs` |
| [AdminDTO](classes/backend/AdminDTO.md) | `DTOs/AdminDTO.cs` |
| [Artefact](classes/backend/Artefact.md) | `VTA.Data/Models/Artefact.cs` |
| [ArtefactConfiguration](classes/backend/ArtefactConfiguration.md) | `VTA.Data/Configuration/ArtefactConfiguration.cs` |
| [ArtefactDTO](classes/backend/ArtefactDTO.md) | `DTOs/ArtefactDTO.cs` |
| [ArtefactsController](classes/backend/ArtefactsController.md) | `Controllers/ArtefactsController.cs` |
| [AssetsController](classes/backend/AssetsController.md) | `Controllers/AssetsController.cs` |
| [BoardDTO](classes/backend/BoardDTO.md) | `DTOs/BoardDTO.cs` |
| [BoardLayoutDTO](classes/backend/BoardLayoutDTO.md) | `DTOs/BoardLayoutDTO.cs` |
| [BoardsController](classes/backend/BoardsController.md) | `Controllers/BoardsController.cs` |
| [CallStatus](classes/backend/CallStatus.md) | `VTA.Data/Models/CallStatus.cs` |
| [CategoriesController](classes/backend/CategoriesController.md) | `Controllers/CategoriesController.cs` |
| [Category](classes/backend/Category.md) | `VTA.Data/Models/Category.cs` |
| [CategoryConfiguration](classes/backend/CategoryConfiguration.md) | `VTA.Data/Configuration/CategoryConfiguration.cs` |
| [CategoryDTO](classes/backend/CategoryDTO.md) | `DTOs/CategoryDTO.cs` |
| [ContactsController](classes/backend/ContactsController.md) | `Controllers/ContactsController.cs` |
| [DbContextExtensions](classes/backend/DbContextExtensions.md) | `VTA.Data/DbContextExtensions.cs` |
| [DTOConverter](classes/backend/DTOConverter.md) | `DTOs/DTOConverter.cs` |
| [ElevenLabsService](classes/backend/ElevenLabsService.md) | `Utilities/ElevenLabsService.cs` |
| [ImageUtilities](classes/backend/ImageUtilities.md) | `Utilities/ImageUtilities.cs` |
| [MigrationController](classes/backend/MigrationController.md) | `Controllers/MigrationController.cs` |
| [MigrationService](classes/backend/MigrationService.md) | `Utilities/MigrationService.cs` |
| [Program](classes/backend/Program.md) | `VTA.API/Program.cs` |
| [Relation](classes/backend/Relation.md) | `VTA.Data/Models/Relation.cs` |
| [RelationConfiguration](classes/backend/RelationConfiguration.md) | `VTA.Data/Configuration/RelationConfiguration.cs` |
| [RelationController](classes/backend/RelationController.md) | `Controllers/RelationController.cs` |
| [RelationDTO](classes/backend/RelationDTO.md) | `DTOs/RelationDTO.cs` |
| [SavedArtefact](classes/backend/SavedArtefact.md) | `VTA.Data/Models/SavedArtefact.cs` |
| [SavedArtefactConfiguration](classes/backend/SavedArtefactConfiguration.md) | `VTA.Data/Configuration/SavedArtefactConfiguration.cs` |
| [SavedArtefactsController](classes/backend/SavedArtefactsController.md) | `Controllers/SavedArtefactsController.cs` |
| [SavedBoard](classes/backend/SavedBoard.md) | `VTA.Data/Models/SavedBoard.cs` |
| [SavedBoardConfiguration](classes/backend/SavedBoardConfiguration.md) | `VTA.Data/Configuration/SavedBoardConfiguration.cs` |
| [SecretsProvider](classes/backend/SecretsProvider.md) | `Utilities/SecretsProvider.cs` |
| [Session](classes/backend/Session.md) | `VTA.Data/Models/Session.cs` |
| [SessionConfiguration](classes/backend/SessionConfiguration.md) | `VTA.Data/Configuration/SessionConfiguration.cs` |
| [SoundUtilities](classes/backend/SoundUtilities.md) | `Utilities/SoundUtilities.cs` |
| [SyncController](classes/backend/SyncController.md) | `Controllers/SyncController.cs` |
| [SyncDTO](classes/backend/SyncDTO.md) | `DTOs/SyncDTO.cs` |
| [User](classes/backend/User.md) | `VTA.Data/Models/User.cs` |
| [UserConfiguration](classes/backend/UserConfiguration.md) | `VTA.Data/Configuration/UserConfiguration.cs` |
| [UserDTO](classes/backend/UserDTO.md) | `DTOs/UserDTO.cs` |
| [UserRole](classes/backend/UserRole.md) | `VTA.Data/Models/UserRole.cs` |
| [UsersController](classes/backend/UsersController.md) | `Controllers/UsersController.cs` |
| [VTAContext](classes/backend/VTAContext.md) | `VTA.Data/VTAContext.cs` |
| [WebApplicationExtensions](classes/backend/WebApplicationExtensions.md) | `Extensions/WebApplicationExtensions.cs` |

### Backend — SyncService  (8 cards)

| Card | Source File |
|------|------------|
| [AddArtefactArgs](classes/backend/syncservice/AddArtefactArgs.md) | `Models/ArtifactAdded/AddArtefactArgs.cs` |
| [ArtifactAddedEvent](classes/backend/syncservice/ArtifactAddedEvent.md) | `Models/ArtifactAdded/ArtifactAddedEvent.cs` |
| [ArtifactAddedPayload](classes/backend/syncservice/ArtifactAddedPayload.md) | `Models/ArtifactAdded/ArtifactAddedPayload.cs` |
| [BoardHub](classes/backend/syncservice/BoardHub.md) | `Hubs/BoardHub.cs` |
| [BoardSession](classes/backend/syncservice/BoardSession.md) | `Models/BoardSession.cs` |
| [PendingSessionRequest](classes/backend/syncservice/PendingSessionRequest.md) | `Models/PendingSessionRequest.cs` |
| [Program](classes/backend/syncservice/Program.md) | `SyncService/Program.cs` |
| [UserInfo](classes/backend/syncservice/UserInfo.md) | `Models/UserInfo.cs` |

### Flutter  (33 cards + 14 summaries)

#### Cards

| Card | Source File |
|------|------------|
| [addPicture](classes/flutter/addPicture.md) | `lib/widgets/addPicture.dart` |
| [add_item_popup](classes/flutter/add_item_popup.md) | `lib/widgets/add_item_popup.dart` |
| [api_provider](classes/flutter/api_provider.md) | `lib/utilities/api_provider.dart` |
| [artefact_db](classes/flutter/artefact_db.md) | `lib/database/models/artefact_db.dart` |
| [artefact_model](classes/flutter/artefact_model.md) | `lib/models/artefact_model.dart` |
| [artefact_repository](classes/flutter/artefact_repository.md) | `lib/database/repositories/artefact_repository.dart` |
| [artifact_board_controller](classes/flutter/artifact_board_controller.md) | `lib/controllers/artifact_board_controller.dart` |
| [artifact_board_screen](classes/flutter/artifact_board_screen.md) | `lib/screens/artifact_board_screen.dart` |
| [artifact_controller](classes/flutter/artifact_controller.md) | `lib/controllers/artifact_controller.dart` |
| [auth_controller](classes/flutter/auth_controller.md) | `lib/controllers/auth_controller.dart` |
| [auth_model](classes/flutter/auth_model.md) | `lib/models/auth_model.dart` |
| [board_artifact](classes/flutter/board_artifact.md) | `lib/widgets/board_artifact.dart` |
| [board_layout_service](classes/flutter/board_layout_service.md) | `lib/services/board_layout_service.dart` |
| [call_manager](classes/flutter/call_manager.md) | `lib/services/call_manager.dart` |
| [calling_screen](classes/flutter/calling_screen.md) | `lib/screens/calling_screen.dart` |
| [caregiver_request_widget](classes/flutter/caregiver_request_widget.md) | `lib/widgets/caregiver_request_widget.dart` |
| [categories_widget](classes/flutter/categories_widget.md) | `lib/widgets/categories_widget.dart` |
| [category_db](classes/flutter/category_db.md) | `lib/database/models/category_db.dart` |
| [category_repository](classes/flutter/category_repository.md) | `lib/database/repositories/category_repository.dart` |
| [data_repository](classes/flutter/data_repository.md) | `lib/utilities/data_repository.dart` |
| [database](classes/flutter/database.md) | `lib/database/database.dart` |
| [database_debug_helper](classes/flutter/database_debug_helper.md) | `lib/database/database_debug_helper.dart` |
| [database_helper](classes/flutter/database_helper.md) | `lib/database/database_helper.dart` |
| [elevenlabs_controller](classes/flutter/elevenlabs_controller.md) | `lib/controllers/elevenlabs_controller.dart` |
| [elevenlabs_service](classes/flutter/elevenlabs_service.md) | `lib/utilities/elevenlabs_service.dart` |
| [incomming_call_screen](classes/flutter/incomming_call_screen.md) | `lib/screens/incomming_call_screen.dart` |
| [linear_board](classes/flutter/linear_board.md) | `lib/widgets/linear_board.dart` |
| [option_wheel](classes/flutter/option_wheel.md) | `lib/widgets/option_wheel.dart` |
| [relation_repository](classes/flutter/relation_repository.md) | `lib/database/repositories/relation_repository.dart` |
| [remote_artifact_board_controller](classes/flutter/remote_artifact_board_controller.md) | `lib/controllers/remote_artifact_board_controller.dart` |
| [remote_board_screen](classes/flutter/remote_board_screen.md) | `lib/screens/remote_board_screen.dart` |
| [remote_session_screen](classes/flutter/remote_session_screen.md) | `lib/screens/remote_session_screen.dart` |
| [saved_artefact_db](classes/flutter/saved_artefact_db.md) | `lib/database/models/saved_artefact_db.dart` |
| [saved_artefact_repository](classes/flutter/saved_artefact_repository.md) | `lib/database/repositories/saved_artefact_repository.dart` |
| [saved_board_db](classes/flutter/saved_board_db.md) | `lib/database/models/saved_board_db.dart` |
| [saved_board_repository](classes/flutter/saved_board_repository.md) | `lib/database/repositories/saved_board_repository.dart` |
| [session_meta_db](classes/flutter/session_meta_db.md) | `lib/database/models/session_meta_db.dart` |
| [session_meta_repository](classes/flutter/session_meta_repository.md) | `lib/database/repositories/session_meta_repository.dart` |
| [signalr_service](classes/flutter/signalr_service.md) | `lib/services/signalr_service.dart` |
| [sync_metadata_db](classes/flutter/sync_metadata_db.md) | `lib/database/models/sync_metadata_db.dart` |
| [sync_metadata_repository](classes/flutter/sync_metadata_repository.md) | `lib/database/repositories/sync_metadata_repository.dart` |
| [sync_service](classes/flutter/sync_service.md) | `lib/services/sync_service.dart` |
| [talking_mat](classes/flutter/talking_mat.md) | `lib/widgets/talking_mat.dart` |
| [talkingmat_controller](classes/flutter/talkingmat_controller.md) | `lib/controllers/talkingmat_controller.dart` |
| [text_to_speech_widget](classes/flutter/text_to_speech_widget.md) | `lib/widgets/text_to_speech_widget.dart` |
| [user_db](classes/flutter/user_db.md) | `lib/database/models/user_db.dart` |
| [user_repository](classes/flutter/user_repository.md) | `lib/database/repositories/user_repository.dart` |
| [video_call_screen](classes/flutter/video_call_screen.md) | `lib/screens/video_call_screen.dart` |
| [webrtc_service](classes/flutter/webrtc_service.md) | `lib/services/webrtc_service.dart` |

#### Summaries

| Summary | Covers |
|---------|--------|
| [summary_database_mappers](classes/flutter/summary_database_mappers.md) | Database mapper functions |
| [summary_localization](classes/flutter/summary_localization.md) | l10n / ARB files |
| [summary_modelsDTOs](classes/flutter/summary_modelsDTOs.md) | 9 simple DTO files |
| [summary_models_simple](classes/flutter/summary_models_simple.md) | board_layout, board_model, elevenlabs_model |
| [summary_notifiers_shared_functions](classes/flutter/summary_notifiers_shared_functions.md) | Notifiers and shared functions |
| [summary_root_theme](classes/flutter/summary_root_theme.md) | main.dart, app.dart, theme, examples |
| [summary_settings](classes/flutter/summary_settings.md) | Settings-related files |
| [summary_simple_controllers](classes/flutter/summary_simple_controllers.md) | board_controller, linear_board_controller |
| [summary_simple_screens](classes/flutter/summary_simple_screens.md) | 6 simple screen files |
| [summary_simple_services](classes/flutter/summary_simple_services.md) | 5 simple services |
| [summary_simple_widgets](classes/flutter/summary_simple_widgets.md) | ~10 simple widget files |
| [summary_singletons](classes/flutter/summary_singletons.md) | 2 trivial singletons |
| [summary_utilities_audio](classes/flutter/summary_utilities_audio.md) | 7 audio utility files |
| [summary_utilities_misc](classes/flutter/summary_utilities_misc.md) | ~7 misc utility files |

### Admin Dashboard  (4 cards + 1 summary)

| Card | Source File |
|------|------------|
| [OverviewView](classes/admin/OverviewView.md) | `src/views/OverviewView.vue` |
| [PairingsView](classes/admin/PairingsView.md) | `src/views/PairingsView.vue` |
| [router](classes/admin/router.md) | `src/router/index.ts` |
| [store_auth](classes/admin/store_auth.md) | `src/stores/auth.ts` |
| [summary_admin_dashboard](classes/admin/summary_admin_dashboard.md) | 25 simple files |

---

## Project Meta

| Document | Description |
|----------|-------------|
| [Documentation Plan](plan.md) | Step-by-step progress tracker |
| [Battleplan](battleplan.md) | Original documentation strategy |
| [Documentation Guide](codebase-documentation-guide.md) | Templates and conventions for class cards |
