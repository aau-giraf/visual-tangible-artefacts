# Class: ElevenLabsService

**Path:** `Backend/VTA.API/Utilities/ElevenLabsService.cs`

## Overview
The `ElevenLabsService` class provides a client-side interface for interacting with the ElevenLabs Text-to-Speech (TTS) API. It handles authentication, speech generation, and retrieval of voice and user information from the ElevenLabs platform.

## Extends
*(None)*

## Implements
*(None)*

## Properties
- `BaseUrl` (const string): The base URL for the ElevenLabs API (`https://api.elevenlabs.io/v1`).
- `DefaultVoiceId` (const string): The default voice ID to use for TTS (currently a Danish voice).
- `DefaultModelId` (const string): The default model ID for TTS (currently "eleven_turbo_v2_5" for multilingual support).
- `_httpClient` (readonly `HttpClient`): An HTTP client instance used for making API requests.
- `_apiKey` (readonly string): The ElevenLabs API key used for authentication.

## Methods

### `ElevenLabsService(HttpClient httpClient, string apiKey)` (Constructor)
- **Purpose**: Initializes a new instance of the `ElevenLabsService`.
- **Parameters**:
  - `httpClient` (`HttpClient`): An `HttpClient` instance, typically injected via dependency injection.
  - `apiKey` (string): The ElevenLabs API key.
- **Functionality**: Sets the `xi-api-key` header for all subsequent HTTP requests made by this service instance.

### `GenerateSpeechAsync(string text, string? voiceId = null, string? modelId = null, double? stability = null, double? similarityBoost = null, bool? useSpeakerBoost = null, double? speed = null, string? languageCode = null)`
- **Purpose**: Generates speech audio from text using the ElevenLabs API with customizable voice settings.
- **Parameters**:
  - `text` (string): The text to convert to speech.
  - `voiceId` (string, nullable): The specific voice ID to use. Defaults to `DefaultVoiceId` if not provided.
  - `modelId` (string, nullable): The specific model ID to use. Defaults to `DefaultModelId` if not provided.
  - `stability` (double, nullable): Voice stability setting (0.0 to 1.0).
  - `similarityBoost` (double, nullable): Similarity boost setting (0.0 to 1.0).
  - `useSpeakerBoost` (bool, nullable): Whether to use speaker boost.
  - `speed` (double, nullable): Speaking speed (0.25 to 4.0, default 0.8).
  - `languageCode` (string, nullable): Language code (e.g., "da", "en") for multilingual models.
- **Returns**: A `byte[]` containing the audio data if successful, otherwise `null`. Includes debug logging for requests and errors.

### `GetVoicesAsync()`
- **Purpose**: Retrieves a list of available voices from the ElevenLabs API.
- **Parameters**: None
- **Returns**: A JSON string containing voice data if successful, otherwise `null`.

### `GetUserInfoAsync()`
- **Purpose**: Retrieves user information and quota details from the ElevenLabs API.
- **Parameters**: None
- **Returns**: A JSON string containing user data if successful, otherwise `null`.

### `ValidateApiKeyAsync()`
- **Purpose**: Validates the configured API key by making a test request to fetch user information.
- **Parameters**: None
- **Returns**: `true` if the API key is valid (user info is successfully retrieved), `false` otherwise.

## Internal Imports
*(None apparent, uses standard .NET types)*

## Notable Packages
- `System.Net.Http`
- `System.Text`
- `System.Text.Json`
