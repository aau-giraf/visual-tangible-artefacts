# Class: SecretsProvider (Singleton)

**Path:** `Backend/VTA.API/Utilities/SecretsProvider.cs`

## Overview
The `SecretsProvider` class implements the Singleton design pattern to provide a globally accessible, thread-safe mechanism for storing and retrieving application secrets. The class comment suggests potential ambiguity regarding its full necessity given built-in configuration mechanisms for JWT.

## Extends
*(None)*

## Implements
*(None)*

## Properties
- `_instance` (private static readonly `Lazy<SecretsProvider>`): A `Lazy` initialized instance of `SecretsProvider` to ensure thread-safe, lazy instantiation of the singleton.
- `Instance` (public static `SecretsProvider`): The public accessor for the single instance of the `SecretsProvider`.
- `Secrets` (`ConcurrentDictionary<string, string?>`): A thread-safe dictionary used to store key-value pairs of secrets.

## Methods

### `SecretsProvider()` (Private Constructor)
- **Purpose**: Initializes a new instance of the `SecretsProvider`. Being private, it prevents direct instantiation from outside the class, enforcing the Singleton pattern.
- **Functionality**: Initializes the `Secrets` `ConcurrentDictionary`.

### `AddSecret(string key, string? value)`
- **Purpose**: Adds a new secret or updates an existing one in the `Secrets` dictionary.
- **Parameters**:
  - `key` (string): The key under which the secret will be stored.
  - `value` (string, nullable): The secret value to store.

## Internal Imports
*(None apparent from the snippet, uses standard .NET types)*

## Notable Packages
- `System.Collections.Concurrent` (for `ConcurrentDictionary`)

## Relationships
*(None explicit within the provided snippet, serves as a utility for storing configuration/secrets)*
