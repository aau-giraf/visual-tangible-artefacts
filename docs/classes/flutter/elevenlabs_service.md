# ElevenLabsService

**File:** `Frontend/vta_app/lib/src/utilities/api/elevenlabs_service.dart` (229 lines)

## Purpose

Client for the ElevenLabs TTS API. Handles speech generation, voice listing, and API key validation. Uses `ApiProvider` internally pointed at `https://api.elevenlabs.io/v1`.

## Class: `ElevenLabsService`

### Constructor
- `ElevenLabsService({required String apiKey})` — creates its own `ApiProvider` with ElevenLabs base URL

### Key Constants
- `_baseUrl`: `https://api.elevenlabs.io/v1`
- `_defaultVoiceId`: `Bj9UqZbhQsanLzgalpEG`

### Methods

| Method | Endpoint | Description |
|--------|----------|-------------|
| `generateSpeech(text, voiceId?, voiceSettings?, modelId?, seed?)` | POST `/text-to-speech/{voiceId}` | Returns `ElevenLabsResponse` with audio bytes. Default model: `eleven_v3` |
| `generateSpeechForArtefact(text, artefactId, ...)` | (delegates to `generateSpeech`) | Wrapper intended for backend upload integration (currently just delegates) |
| `getVoices()` | GET `/voices` | Returns `List<ElevenLabsVoice>?` |
| `getVoice(voiceId)` | GET `/voices/{id}` | Returns single `ElevenLabsVoice?` |
| `getUserInfo()` | GET `/user` | Returns raw JSON map (quota info) |
| `validateApiKey()` | (delegates to `getUserInfo`) | Returns `bool` — true if API key works |

### Authentication
All requests include `xi-api-key` header with the injected API key.

## Class: `ElevenLabsVoicePresets`

Static voice configuration presets:
- `popularVoices`: Map of name → voiceId for 9 built-in voices (Adam, Rachel, etc.)
- `balanced`, `stable`, `expressive`: Pre-configured `VoiceSettings` instances

## Design Notes
- Creates its own `ApiProvider` instance (not shared with the app's main API provider).
- `generateSpeechForArtefact` is a thin wrapper that doesn't actually upload to backend yet.
