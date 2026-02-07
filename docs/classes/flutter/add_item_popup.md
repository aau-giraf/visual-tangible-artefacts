# AddItemPopup

**File:** `Frontend/vta_app/lib/src/ui/widgets/board/add_item_popup.dart` (1193 lines)

## Purpose

Modal dialog for creating/editing artefacts and categories. Handles name input, image capture (camera/upload/AI generation), and sound attachment (recording/upload/AI TTS).

## Class: `AddItemPopup` extends `StatefulWidget`

### Props
- `isCategory` — determines which fields are shown (categories have no sound)
- `onSubmit(name, imageBytes?, soundBytes?)` — callback with collected data
- `category?` — pre-fills form for editing existing category
- `title` — dialog title (default: "Tilføj")

## State: `_AddItemPopupState`

### Image Sources
1. **Camera** — navigates to `TakePictureScreen`, returns bytes; desktop shows "not supported"
2. **File upload** — `FilePicker.platform.pickFiles(type: FileType.image)`
3. **AI generation** — opens `AIPage` dialog, receives base64-encoded image

### Sound Sources (artefacts only)
Opens a nested sound modal dialog with three options:
1. **Microphone recording** — uses `record` package via `createRecorder()` factory; shows live amplitude level bar (`_LevelBar` widget) or sine-wave pulse fallback; saves as `.m4a` (AAC-LC)
2. **File upload** — `FilePicker.platform.pickFiles(type: FileType.audio)`
3. **AI Text-to-Speech** — text input (max 50 chars) → voice selector (male/female via ElevenLabs voice IDs) → calls backend `Users/Artefacts/generate-speech-simple` endpoint → receives audio bytes

### TTS Generation (`_generateSpeechViaBackend`)
- POST to `{baseUrl}Users/Artefacts/generate-speech-simple` with `{text, voiceId}`
- Authenticated via JWT Bearer token
- Voice ID resolved through `VoiceConfigValidator`
- Persists selected voice to `ElevenLabsConfig` on success

### Validation (`_canSubmit`)
- Categories: name + image required
- Artefacts: name + image required (sound optional despite commented-out check)

### Helper Widget
`_LevelBar` — horizontal progress bar (0.0–1.0) showing recording amplitude

### Design Notes
- 1193 lines — largest widget in the codebase; combines form, camera, recording, and TTS in one file
- Dual `StateSetter` pattern: outer `setState` + inner `setDialogState` for nested sound modal
- Recorder created lazily via `createRecorder()` factory (returns null on web)
- Audio playback preview creates fresh `AudioPlayer` instances (web reliability workaround)
- All user-facing strings in Danish
