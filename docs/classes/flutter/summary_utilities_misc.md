# Utilities: Miscellaneous Summary

**Path:** `Frontend/vta_app/lib/src/utilities/` (various subdirectories)

## Files

| File | Lines | Description |
|------|-------|-------------|
| `extensions/string_extension.dart` | 5 | `StringExtension` — adds `capitalize()` method |
| `json/json_serializable.dart` | 6 | `JsonSerializable` abstract class — `toJson()`/`fromJson()` contract |
| `platform_utils.dart` | 91 | `PlatformUtils` — static methods `getApiUrl()` and `getSyncServiceUrl()` with platform-aware URL resolution (web uses `GlobalConfiguration`, mobile uses hardcoded fallbacks) |
| `services/camera_service.dart` | 21 | `CameraManager` singleton — lazy init of available cameras via `availableCameras()` |
| `data/ImageData.dart` | 9 | `ImageData` — holds `Uint8List data`, `String extension`, optional `String? fileName` |
| `config/elevenlabs_config.dart` | 156 | `ElevenLabsConfig` — static SharedPreferences manager for all ElevenLabs settings (API key, voice ID, model ID, stability, similarity boost, speaker boost, enabled flag). Methods: `getApiKey/setApiKey`, `getDefaultVoiceId/setDefaultVoiceId`, `getAllSettings`, `isConfigured`, `resetToDefaults`. Default voice: `Bj9UqZbhQsanLzgalpEG`, model: `eleven_v3` |
| `config/voice_config_validator.dart` | 52 | `VoiceConfigValidator` — resolves voice IDs to display names, validates voice selection, provides ElevenLabs voice options list |
