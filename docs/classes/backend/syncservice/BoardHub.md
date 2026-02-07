# Class: BoardHub

**Path:** `Backend/SyncService/Hubs/BoardHub.cs`

## Overview
The `BoardHub` is a SignalR Hub that facilitates real-time collaboration and communication between users in the Visual Tangible Artefacts (VTA) application. It manages user connections, active board sessions, session requests, and propagates real-time updates related to board changes, artefact manipulations, and WebRTC signaling for video calls.

## Extends
- `Hub` (from `Microsoft.AspNetCore.SignalR`)

## Implements
*(None)*

## Static Fields (Application State)

- `UserConnections` (`Dictionary<string, string>`): Maps `UserId` to `ConnectionId`. Tracks which user is connected with which SignalR connection.
- `BoardSessions` (`Dictionary<string, BoardSession>`): Maps `SessionId` to `BoardSession` objects. Stores details about active collaboration sessions.
- `OnlineUsers` (`HashSet<string>`): A set of `UserId`s for users currently online.
- `UserContactsMap` (`Dictionary<string, List<string>>`): Maps `UserId` to a list of their contact `UserId`s. Used to notify relevant contacts about status changes.
- `UserInfoMap` (`Dictionary<string, UserInfo>`): Maps `UserId` to `UserInfo` objects, storing basic user details (name) for quick lookup.
- `PendingRequests` (`Dictionary<string, PendingSessionRequest>`): Maps a unique request key (e.g., `fromUserId_toUserId_timestamp`) to `PendingSessionRequest` objects. Manages incoming session requests and their timeouts.

## Constructor

### `BoardHub(VTAContext context)`
- **Purpose**: Initializes a new instance of the `BoardHub`.
- **Parameters**:
  - `context` (`VTAContext`): The Entity Framework Core database context, used for logging sessions and accessing user/artefact data.

## Methods

### `RegisterUser(string userId, List<string> contactIds)`
- **Purpose**: Registers a user's SignalR connection and initializes their online status.
- **Parameters**:
  - `userId` (string): The unique identifier of the user.
  - `contactIds` (`List<string>`): A list of user IDs that are contacts of this user.
- **Functionality**:
  - Stores the `ConnectionId` for the `userId` in `UserConnections`.
  - Adds the `userId` to `OnlineUsers`.
  - Populates `UserContactsMap` and `UserInfoMap` for the user.
  - Calls `NotifyContactsOfStatusChange` to inform contacts that this user is now online.

### `NotifyContactsOfStatusChange(string userId, bool isOnline)` (private)
- **Purpose**: Notifies a user's contacts about their online/offline status change.
- **Parameters**:
  - `userId` (string): The user whose status has changed.
  - `isOnline` (bool): `true` if the user came online, `false` if they went offline.
- **Functionality**:
  - Iterates through the `contactIds` associated with the `userId`.
  - For each online contact, sends a "UserOnlineStatusChanged" message to their client.

### `GetOnlineUsers()`
- **Purpose**: Returns a list of all currently online user IDs.
- **Returns**: `List<string>` - A list of user IDs.

### `IsUserOnline(string userId)`
- **Purpose**: Checks if a specific user is currently online.
- **Parameters**:
  - `userId` (string): The ID of the user to check.
- **Returns**: `bool` - `true` if the user is online, `false` otherwise.

### `RequestSession(string fromUserId, string toUserId)`
- **Purpose**: Initiates a session request from `fromUserId` to `toUserId`.
- **Parameters**:
  - `fromUserId` (string): The ID of the user requesting the session.
  - `toUserId` (string): The ID of the user being requested for a session.
- **Functionality**:
  - Creates a `PendingSessionRequest` and stores it.
  - Sends a "SessionRequested" message to the `toUserId`'s client.
  - Starts a 30-second timeout for the request. If the request isn't accepted/rejected within this time, a "MissedCall" message is sent to the `toUserId`.

### `GetUserName(string userId)` (private)
- **Purpose**: Retrieves the name of a user from `UserInfoMap`.
- **Parameters**:
  - `userId` (string): The ID of the user.
- **Returns**: `string` - The user's name or "User" if not found.

### `AcceptSession(string sessionId, string fromUserId, string toUserId, string boardId)`
- **Purpose**: Accepts a pending session request and establishes a new board collaboration session.
- **Parameters**:
  - `sessionId` (string): The unique ID for the new session.
  - `fromUserId` (string): The ID of the user who initiated the request.
  - `toUserId` (string): The ID of the user who accepted the request.
  - `boardId` (string): The ID of the board to be used in the session.
- **Functionality**:
  - Cancels any pending timeout for the session request in `PendingRequests`.
  - Creates a `BoardSession` object.
  - Adds both `fromUserId` and `toUserId` to a SignalR group identified by `sessionId`.
  - Logs the session to the database with `CallStatus.Accepted`.
  - Broadcasts a "SessionStarted" message to both users in the session group.

### `RejectSession(string fromUserId)`
- **Purpose**: Rejects a pending session request.
- **Parameters**:
  - `fromUserId` (string): The ID of the user whose session request is being rejected.
- **Functionality**:
  - Logs the rejected session to the database with `CallStatus.Rejected`.
  - Cancels any pending timeout for the session request.
  - Sends a "SessionRejected" message to the `fromUserId`'s client.

### `UpdateBoard(string sessionId, object boardData)`
- **Purpose**: Propagates board data updates to all other participants in a session.
- **Parameters**:
  - `sessionId` (string): The ID of the active session.
  - `boardData` (object): The updated board data (type is `object` to allow flexible data transfer, likely JSON).
- **Functionality**:
  - Sends a "BoardUpdated" message to all clients in the `sessionId` group, excluding the caller.

### `ArtifactAdded(JsonElement data)`
- **Purpose**: Propagates information about an added artefact to other participants in a session, after verifying the artefact.
- **Parameters**:
  - `data` (`JsonElement`): Raw JSON data representing the `ArtifactAddedPayload`.
- **Functionality**:
  - Deserializes the `JsonElement` to `ArtifactAddedPayload`.
  - Extracts `userId` from the current context and verifies artefact ownership.
  - Verifies image and sound URLs against the database to prevent data manipulation.
  - If valid, broadcasts an "ArtifactAdded" message to all clients in the `sessionId` group, excluding the caller.
  - If verification fails, sends an "ArtifactRejected" message to the caller.

### `ArtifactRemoved(JsonElement data)`
- **Purpose**: Propagates information about a removed artefact to other participants in a session.
- **Parameters**:
  - `data` (`JsonElement`): Raw JSON data containing the `sessionId` and artefact details.
- **Functionality**:
  - Extracts `sessionId` from the provided data.
  - Sends an "ArtifactRemoved" message to all clients in the `sessionId` group, excluding the caller.

### `ArtifactMoved(JsonElement data)`
- **Purpose**: Propagates information about a moved artefact to other participants in a session.
- **Parameters**:
  - `data` (`JsonElement`): Raw JSON data containing the `sessionId` and artefact movement details.
- **Functionality**:
  - Extracts `sessionId` from the provided data.
  - Sends an "ArtifactMoved" message to all clients in the `sessionId` group, excluding the caller.

### `ArtifactResized(JsonElement data)`
- **Purpose**: Propagates information about a resized artefact to other participants in a session.
- **Parameters**:
  - `data` (`JsonElement`): Raw JSON data containing the `sessionId` and artefact resizing details.
- **Functionality**:
  - Extracts `sessionId` from the provided data.
  - Sends an "ArtifactResized" message to all clients in the `sessionId` group, excluding the caller.

### `LayoutChanged(JsonElement data)`
- **Purpose**: Propagates general layout changes to other participants in a session.
- **Parameters**:
  - `data` (`JsonElement`): Raw JSON data containing the `sessionId` and layout change details.
- **Functionality**:
  - Extracts `sessionId` from the provided data.
  - Sends a "LayoutChanged" message to all clients in the `sessionId` group, excluding the caller.

### `FieldCountChanged(JsonElement data)`
- **Purpose**: Propagates changes to the field count (e.g., grid layout configuration) to other participants in a session.
- **Parameters**:
  - `data` (`JsonElement`): Raw JSON data containing the `sessionId` and field count details.
- **Functionality**:
  - Extracts `sessionId` and `count` from the provided data.
  - Sends a "FieldCountChanged" message to all clients in the `sessionId` group, excluding the caller.

### `EndSession(string sessionId)`
- **Purpose**: Ends an active collaboration session.
- **Parameters**:
  - `sessionId` (string): The ID of the session to end.
- **Functionality**:
  - Finds the `BoardSession` in `BoardSessions`.
  - Updates the corresponding database `Session` entry with `EndTime` and `CallStatus.Completed`.
  - Broadcasts a "SessionEnded" message to all clients in the session group.
  - Removes the `BoardSession` from `BoardSessions`.

### `OnDisconnectedAsync(Exception? exception)` (Overridden)
- **Purpose**: Handles actions when a client disconnects from the SignalR hub.
- **Parameters**:
  - `exception` (`Exception?`): The exception that caused the disconnection, if any.
- **Functionality**:
  - Identifies the `userId` of the disconnected client.
  - Iterates through any active `BoardSessions` involving this user:
    - Marks the corresponding database `Session` as `CallStatus.Failed`.
    - Removes the `BoardSession` from `BoardSessions`.
  - Calls `NotifyContactsOfStatusChange` to inform contacts that the user is now offline.
  - Removes the user's data from `UserConnections`, `OnlineUsers`, `UserContactsMap`, and `UserInfoMap`.

### `SendOffer(string sessionId, string targetUserId, object sdpOffer)`
- **Purpose**: Sends a WebRTC Session Description Protocol (SDP) offer to a target user within a session.
- **Parameters**:
  - `sessionId` (string): The ID of the session.
  - `targetUserId` (string): The ID of the user to send the offer to.
  - `sdpOffer` (object): The SDP offer data (likely JSON).
- **Functionality**:
  - Finds the target user's connection ID.
  - Sends a "ReceiveOffer" message to the target client.

### `SendAnswer(string sessionId, string targetUserId, object sdpAnswer)`
- **Purpose**: Sends a WebRTC SDP answer to a target user within a session.
- **Parameters**:
  - `sessionId` (string): The ID of the session.
  - `targetUserId` (string): The ID of the user to send the answer to.
  - `sdpAnswer` (object): The SDP answer data (likely JSON).
- **Functionality**:
  - Finds the target user's connection ID.
  - Sends a "ReceiveAnswer" message to the target client.

### `SendIceCandidate(string sessionId, string targetUserId, object candidate)`
- **Purpose**: Sends a WebRTC Interactive Connectivity Establishment (ICE) candidate to a target user within a session.
- **Parameters**:
  - `sessionId` (string): The ID of the session.
  - `targetUserId` (string): The ID of the user to send the candidate to.
  - `candidate` (object): The ICE candidate data (likely JSON).
- **Functionality**:
  - Finds the target user's connection ID.
  - Sends a "ReceiveIceCandidate" message to the target client.

## Internal Imports
- `SyncService.Models`
- `SyncService.Models.ArtifactAdded`
- `VTA.Data.DbContexts`
- `VTA.Data.Models`

## Notable Packages
- `Microsoft.AspNetCore.Authorization`
- `Microsoft.AspNetCore.SignalR`
- `System.Text.Json`
- `Microsoft.EntityFrameworkCore`
- `System.Threading` (for `CancellationTokenSource` within `RequestSession`)
