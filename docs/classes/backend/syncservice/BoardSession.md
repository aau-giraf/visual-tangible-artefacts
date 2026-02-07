# Class: BoardSession

**Path:** `Backend/SyncService/Models/BoardSession.cs`

## Overview
The `BoardSession` class represents an active real-time collaboration session on a board between two users. It stores essential identifiers for the session, the participating users, the board being used, and tracks the SignalR connection IDs associated with the session.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `SessionId` (string, required, init-only): A unique identifier for the collaboration session. `init` means it can only be set during object initialization.
- `User1Id` (string, required, init-only): The unique identifier of the first user participating in the session. `init` means it can only be set during object initialization.
- `User2Id` (string, required, init-only): The unique identifier of the second user participating in the session. `init` means it can only be set during object initialization.
- `BoardId` (string, required, init-only): The unique identifier of the board being used in the session. `init` means it can only be set during object initialization.
- `Connections` (`HashSet<string>`): A collection of SignalR connection IDs currently associated with this session. Initialized as an empty `HashSet`.

## Methods
*(None explicitly defined)*

## Internal Imports
*(None apparent from the snippet)*

## Notable Packages
- `System.Collections.Generic` (for `HashSet`)
