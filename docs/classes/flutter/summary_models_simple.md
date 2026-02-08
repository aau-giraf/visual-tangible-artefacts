# Simple Models Summary

**Path:** `Frontend/vta_app/lib/src/models/`

Data classes and request/response models. No business logic beyond JSON serialization.

## Files

### `board_model.dart` (53 lines)
**Class: `Board`** — Local board state container.
- Fields: `id`, `title`, `talkingMatArtifacts` (`List<BoardArtefact>`), `linearBoardArtifacts` (`List<BoardArtefact?>`), `showDirectional`, `linearBoardFieldCount`
- `id` auto-generated from timestamp + random int
- `copyWith()` for immutable updates
- Represents both TalkingMat (free positioning) and LinearBoard (slot-based) modes

### `board_layout.dart` (146 lines)
Four data classes for board layout API communication:

| Class | Purpose | Key Fields |
|-------|---------|------------|
| `BoardArtefactLayout` | Position/size of one artefact on a board | artefactId, posX, posY, width, height, nameVisible, savedArtefactId |
| `SaveBoardRequest` | Request body for saving a board | name, artefacts (`List<BoardArtefactLayout>`) |
| `BoardLayoutResponse` | API response for a saved board | boardId, name, createdDate, modifiedDate, artefacts |
| `UpdateArtefactLayoutRequest` | Request body for updating artefact position | Same fields as `BoardArtefactLayout` |

All have `fromJson()` / `toJson()`. `BoardArtefactLayout` also has `copyWith()`.

### `elevenlabs_model.dart` (166 lines)
Four data classes for ElevenLabs TTS integration:

| Class | Purpose | Key Fields |
|-------|---------|------------|
| `ElevenLabsRequest` | TTS request body | text, modelId (default: `eleven_monolingual_v1`), voiceSettings, seed |
| `VoiceSettings` | Voice configuration | stability (0.5), similarityBoost (0.75), style, useSpeakerBoost |
| `ElevenLabsResponse` | TTS response wrapper | success, audioData (`Uint8List?`), errorMessage, statusCode |
| `ElevenLabsVoice` | Available voice metadata | voiceId, name, category, description, labels, settings |
| `ElevenLabsException` | Custom exception | message, statusCode |

Factory constructors: `ElevenLabsResponse.success(audioData)`, `ElevenLabsResponse.error(msg, statusCode)`.
