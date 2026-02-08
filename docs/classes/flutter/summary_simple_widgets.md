# Summary of Simple Flutter Widgets

This document provides a summary of simple, mostly stateless widgets used across the VTA Flutter application. For more complex, stateful, or interactive widgets, please refer to their individual documentation cards.

## Overview

The widgets summarized here are primarily for display, simple interactions, or minor layout purposes. They are grouped by their location in the `lib/src/ui/widgets/` directory.

## Simple Widgets in `board/`

### RelationalBoardButton
- **File:** `relational_board_button.dart`
- **Description:** A simple floating action button with customizable icon and action.

### QuickChatButton
- **File:** `quickchat.dart`
- **Description:** A button that toggles a quick chat popup with predefined audio options.

### QuickAddArtefactButton
- **File:** `quick_add_artefact.dart`
- **Description:** A floating action button for quickly adding a new artefact to the board.

### Categories Widgets

1. **addPicture.dart**: A widget for adding pictures using AI or uploading from the gallery. It includes basic UI elements like buttons and dialogs.
2. **categories_edit.dart**: A widget for editing categories with a simple UI for displaying and editing category details.
3. **category.dart**: A basic data model for categories with minimal UI.

### Online Session Widgets

1. **caregiver_request_widget.dart**: A widget for caregivers to request shared sessions with children. It includes a sidebar with a list of children, session request functionality, and dynamic UI updates based on connection and request states.

### Utilities Widgets

1. **custom_delay_drag_listener.dart**: A utility widget that extends `ReorderableDelayedDragStartListener` to add a customizable delay before initiating a drag gesture.

### Video Widgets

1. **pip_video_widget.dart**: A picture-in-picture video widget that displays a remote video feed in a movable and resizable window. It includes features like audio and video status indicators, drag-and-drop functionality, and a placeholder for when no video is available.
