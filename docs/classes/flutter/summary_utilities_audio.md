# Utilities: Audio Summary

**Path:** `Frontend/vta_app/lib/src/utilities/audio/`

Platform-conditional audio playback and recording utilities.

## Files

| File | Lines | Description |
|------|-------|-------------|
| `network_audio.dart` | 2 | Conditional export: selects `network_audio_io.dart` (mobile/desktop) or `network_audio_web.dart` (web) |
| `network_audio_io.dart` | 46 | `NetworkAudio` — loads and plays remote audio via HTTP using `just_audio` package |
| `network_audio_web.dart` | 55 | `NetworkAudio` — web variant using blob URLs for HTML5 `<audio>` playback |
| `recorder.dart` | 1 | Conditional export: selects `recorder_io.dart` (mobile) or `recorder_stub.dart` (web) |
| `recorder_io.dart` | 13 | Factory function returning `AudioRecorder` from `record` package |
| `recorder_stub.dart` | 4 | Returns `null` on unsupported platforms |
| `artefact_sound_player.dart` | 93 | `ArtefactSoundPlayer` mixin — cached audio playback with completion tracking and cleanup. Used by board artifact widgets. |

## Pattern
Uses Dart conditional imports (`export '...' if (dart.library.io)`) for platform abstraction. Mobile uses `just_audio`/`record` packages; web uses `dart:html` APIs.
