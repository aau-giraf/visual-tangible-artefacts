# Class: Session

**Path:** `Backend/VTA.Data/Models/Session.cs`

## Overview
The `Session` class represents a communication session between two users (a caller and a callee). It tracks the status, duration, and participants of a session.

## Properties
- `Id` (int): A unique integer identifier for the session.
- `CallerId` (string, required): The ID of the user who initiated the session (caller).
- `CalleeId` (string, required): The ID of the user who is the recipient of the session (callee).
- `StartTime` (DateTime, nullable): The date and time when the session started.
- `EndTime` (DateTime, nullable): The date and time when the session ended.
- `Duration` (TimeSpan, nullable): The total duration of the session.
- `CallStatus` (CallStatus): The current status of the call (e.g., InProgress, Completed, Missed).
- `Caller` (`virtual User`): Navigation property to the `User` object representing the caller.
- `Callee` (`virtual User`): Navigation property to the `User` object representing the callee.

## Methods
*(None explicitly defined beyond property accessors)*

## Relationships
- Extends: None
- Implements: None
- Associated Enums: `CallStatus`
- Associated Classes: `User`

## Internal Imports
- `VTA.Data.Models` (namespace)

## Notable Packages
*(None beyond standard C# libraries)*
