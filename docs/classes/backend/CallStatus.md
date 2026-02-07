# Enum: CallStatus

**Path:** `Backend/VTA.Data/Models/CallStatus.cs`

## Overview
The `CallStatus` enum defines the possible states or outcomes of a communication session (e.g., a call or a real-time connection).

## Members
- `Pending`: The session request has been initiated but not yet acted upon.
- `Accepted`: The session request has been accepted by the callee.
- `Rejected`: The session request has been rejected by the callee.
- `InProgress`: The session is currently active.
- `Completed`: The session has finished successfully.
- `Failed`: The session failed to establish or was interrupted.

## Internal Imports
- `VTA.Data.Models` (namespace)

## Notable Packages
*(None beyond standard C# libraries)*
