# Class: ArtifactAddedEvent

**Path:** `Backend/SyncService/Models/ArtifactAdded/ArtifactAddedEvent.cs`

## Overview
The `ArtifactAddedEvent` class is a data structure used to encapsulate information about an artifact being added, typically for communication in a real-time synchronization context (e.g., SignalR). It acts as a wrapper for the actual payload of the event.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `Type` (string, required): A string identifying the type of event (e.g., "ArtifactAdded").
- `Payload` (`ArtifactAddedPayload`, required): The actual data payload of the event, containing details about the added artifact.

## Methods
*(None explicitly defined)*

## Internal Imports
*(Implicitly, `ArtifactAddedPayload` is expected to be in the same namespace or a related one, within `SyncService.Models.ArtifactAdded`)*

## Notable Packages
*(None beyond standard C# libraries)*
