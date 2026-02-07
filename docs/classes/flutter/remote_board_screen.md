# RemoteBoardScreen Class Documentation

**File:** `Frontend/vta_app/lib/src/ui/screens/remote_board_screen.dart`

## Overview
The `RemoteBoardScreen` represents the shared session view. It is used during a real-time session between a caregiver and a child. For the "owner" of the board (usually the child), it behaves similarly to the local board but with sync capabilities. For the "remote" user (caregiver), it mirrors the child's board.

## Responsibilities
- **Session Context:** Initializes with a `sessionId` and `boardId` to connect to the specific real-time session.
- **Role Determination:** Determines if the current user is the "Owner" (controller of the board) or a "Viewer" (remote participant), likely based on the `SignalRService` session initiator data.
- **Controller Setup:** Initializes `RemoteArtifactBoardController`. If the user is the owner, it may wrap or reuse the existing `ArtifactBoardController`; otherwise, it sets up a controller for remote synchronization.
- **Video Integration:** Hosts the `PipVideoWidget` (Picture-in-Picture) to show the video call overlay on top of the board content.
- **Lifecycle Management:**Listens for session end events to tear down the view and return to the main menu.

## Key Properties
- `sessionId`: The ID of the active SignalR session.
- `boardId`: The ID of the board being viewed/shared.
- `isOwner`: Boolean flag determining interaction rights and data flow direction.

## Dependencies
- `RemoteArtifactBoardController`: The specific controller logic for handling shared state.
- `SignalRService`: Core transport for session events.
- `VideoCallManager`: Manages the associated video call state.
- `PipVideoWidget`: Widget for displaying the video feed.
