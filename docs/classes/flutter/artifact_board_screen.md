# ArtifactBoardScreen Class Documentation

**File:** `Frontend/vta_app/lib/src/ui/screens/artifact_board_screen.dart`

## Overview
The `ArtifactBoardScreen` is the main interactive screen for the "Artifact Board" feature. It displays categories and artifacts, allowing users (typically children) to construct sentences or expressions by selecting artifacts. It integrates heavily with the backend via controllers and services.

## Responsibilities
- **Board Visualization:** Renders the artifact board UI, which typically includes categories (left/top) and selected artifacts (center/bottom).
- **Controller Management:** Lazily initializes and persists the `ArtifactBoardController` using `GetIt` to ensure state is maintained across widget rebuilds.
- **User Context:** Loads and displays the current user context (Child vs. Caregiver).
- **Communication:** Facilitates real-time updates and communication via `SignalRService` (though primarily managed by the controller).
- **Navigation:** Serves as the central hub for the board experience, with routes to settings or other views.

## Key Components & Widgets
- **CategoriesWidget:** Displays the list of available categories.
- **LinearBoard / TalkingMat:** Specific board layouts depending on configuration.
- **QuickChat / QuickAddArtefact:** Helper widgets for rapid interaction.
- **BoardSwitcher:** Allows switching between different board types.

## Key Dependencies
- `ArtefactController`: Manages the data logic for fetching and modifying artifacts.
- `ArtifactBoardController`: Manages the view logic for the board, including selection state and layout.
- `AuthController`: Handles user authentication state.
- `SettingsController`: Provides access to app settings.
- `SignalRService`: Uses SignalR for real-time features.

## State Management
- Uses a "Notify View" pattern where the controller calls a callback (`_notifyView`) to trigger `setState` in the widget.
- Controller lifecycle is managed manually with `GetIt` to survive widget disposal/recreation when navigating temporarily away from the screen.
