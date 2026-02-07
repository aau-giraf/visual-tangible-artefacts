# Models DTOs Summary

**Path:** `Frontend/vta_app/lib/src/modelsDTOs/`

Plain data transfer objects for API communication. All support JSON serialization. No business logic.

## Files

| File | Classes | Key Fields | Methods |
|------|---------|------------|---------|
| `artefact.dart` (72 lines) | `Artefact` | artefactId, artefactIndex, userId, categoryId, imageUrl, soundUrl, image (`Uint8List?`), sound (`Uint8List?`), name, nameShown | `fromJson()`, `toJson()`, `displayName` getter |
| `category.dart` (61 lines) | `Category` | userId, categoryId, categoryIndex, name, artefacts (`List<Artefact>?`), imageUrl, image (`Uint8List?`), usageCount, lastUsedDate | `fromJson()`, `toJson()` |
| `user.dart` (44 lines) | `User`, `UserRole` enum | id, name, username, nameVisible, fieldCount, role, categories | `fromJson()`, `toJson()` |
| `pairing.dart` (33 lines) | `PairingDTO` | id, caregiverId, childId, isActive, createdAt, caregiver, child | `fromJson()` |
| `board_update.dart` (33 lines) | `BoardUpdate` | type, payload | `fromJson()`, `toJson()`, static factories: `add()`, `move()`, `remove()`, `layout()`, `fieldCount()` |
| `signup_form.dart` (26 lines) | `SignupForm`, `UserRole` enum | username, password, name, role | `toJson()` |
| `signup_response.dart` (13 lines) | `SignupResponse` | user, token | `fromJson()` |
| `login_form.dart` (11 lines) | `LoginForm` | username, password | `toJson()` |
| `login_response.dart` (11 lines) | `LoginResponse` | token, userId | `fromJson()` |

## Notes
- `UserRole` enum is defined in both `user.dart` and `signup_form.dart` (duplication).
- `Category` contains nested `List<Artefact>` — categories own their artefacts.
- `Artefact` and `Category` carry optional `Uint8List` fields for binary image/sound data (used in multipart uploads).
- `BoardUpdate` uses static factory constructors for type-safe event creation.
