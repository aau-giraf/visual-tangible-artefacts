# ElevenLabsController

**File:** `Frontend/vta_app/lib/src/controllers/elevenlabs_controller.dart` (269 lines)

## Purpose

ChangeNotifier managing the ElevenLabs TTS integration lifecycle: configuration, API key validation, voice listing, speech generation, and quota tracking.

## Class: `ElevenLabsController` extends `ChangeNotifier`

### State
- `_service` — `ElevenLabsService?` (null when disabled/unconfigured)
- `_availableVoices` — cached voice list
- `_userInfo` — subscription/quota data (raw map)
- `_isLoading` / `_lastError` — UI state

### Methods

| Method | Description |
|--------|-------------|
| `initialize()` | Reads enabled flag + API key from `ElevenLabsConfig` (SharedPreferences) → validates key → creates service |
| `configure(apiKey)` | Tests new API key → saves to config → enables integration |
| `disable()` | Sets enabled=false, clears service + caches |
| `loadVoices()` | Fetches available voices from ElevenLabs API |
| `loadUserInfo()` | Fetches subscription/quota info |
| `generateSpeech({text, voiceId?, voiceSettings?, modelId?})` | TTS generation; falls back to config defaults for voice/model/settings |
| `generateSpeechForArtefact({text, artefactId, ...})` | Convenience wrapper returning raw `Uint8List?` audio bytes |
| `getVoice(voiceId)` | Fetches single voice details |
| `clearCache()` | Clears voices + user info |

### Quota Management
- `getQuotaUsed()` / `getQuotaLimit()` — reads from cached `_userInfo` subscription data
- `hasQuotaForText(text)` — checks if character budget allows the text (assumes available if unknown)
- `estimateCost(text)` — returns `text.length` (character count)

### Design Notes
- Clean separation: controller handles lifecycle/state, `ElevenLabsService` handles HTTP, `ElevenLabsConfig` handles persistence
- All methods return `bool` or nullable results — errors stored in `_lastError`
- `artefactId` parameter in `generateSpeechForArtefact` is accepted but unused
