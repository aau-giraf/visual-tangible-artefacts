# TextToSpeechWidget

**File:** `Frontend/vta_app/lib/src/ui/widgets/text_to_speech_widget.dart` (366 lines)

## Purpose

Standalone TTS card widget using `ElevenLabsController` via Provider. Provides text input, voice selection dropdown, quota display, and a configuration dialog for API key setup.

## Class: `TextToSpeechWidget` extends `StatefulWidget`

### Props
- `artefactId` — target artefact for generated speech
- `onSpeechGenerated(text)` — success callback
- `onError` — error callback

### UI States (via `Consumer<ElevenLabsController>`)
1. **Not configured** → settings icon + "Configure" button → opens API key dialog
2. **Configured** → voice dropdown + text input (max 1000 chars) + character count + quota display + "Generate Speech" button

### Generate Flow (`_generateSpeech`)
1. Validates non-empty text
2. Checks quota via `controller.hasQuotaForText()`
3. Calls `controller.generateSpeechForArtefact(text, artefactId, voiceId?)`
4. On success: calls `onSpeechGenerated`, clears text
5. On failure: shows error snackbar, calls `onError`

### Configuration Dialog (`_showConfigurationDialog`)
- API key input (obscured) → `controller.configure(apiKey)` → validates key → saves to config

### Design Notes
- Uses Provider (`context.read<ElevenLabsController>()`) — unlike most widgets which use GetIt
- English strings (unlike most of the app which is Danish)
- Loads available voices on first render if configured but not yet loaded
- Voice dropdown shows name + category for each ElevenLabs voice
