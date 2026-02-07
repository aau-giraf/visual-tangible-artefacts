# Class: PendingSessionRequest

**Path:** `Backend/SyncService/Models/PendingSessionRequest.cs`

## Overview
The `PendingSessionRequest` class represents a request from one user to another to initiate a collaboration session. It captures the initiator and recipient of the request, the time it was made, and includes a `CancellationTokenSource` to manage the request's timeout.

## Extends
*(None)*

## Implements
*(None)*

## Properties

- `FromUserId` (string, required): The unique identifier of the user who initiated the session request.
- `ToUserId` (string, required): The unique identifier of the user to whom the session request was sent.
- `RequestTime` (DateTime, required): The timestamp when the session request was initiated.
- `TimeoutCts` (`CancellationTokenSource`, required): A `CancellationTokenSource` instance used to manage the timeout of the pending session request. When its token is cancelled, the request is considered expired.

## Methods
*(None explicitly defined)*

## Internal Imports
*(None apparent from the snippet)*

## Notable Packages
- `System.Threading` (for `CancellationTokenSource`)
