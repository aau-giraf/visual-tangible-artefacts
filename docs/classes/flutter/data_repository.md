# DataRepository

**File:** `Frontend/vta_app/lib/src/utilities/data/data_repository.dart` (377 lines)

## Purpose

High-level API repository layer providing typed data access for auth, artefacts, categories, and users. Alternative to the model-based approach in `ArtifactModel`/`AuthModel` — both exist in the codebase.

## Class: `ApiDataRepository` (abstract base)

### Setup
- Reads `ApiSettings` from `GlobalConfiguration`
- Creates `ApiProvider` using `PlatformUtils.getApiUrl()`

### Key Method
- `responseOk(Response?)` — validates HTTP response: returns `true` for 2xx, throws `Exception` for 401/500/null/other

## Class: `AuthRepository` extends `ApiDataRepository`
| Method | Description |
|--------|-------------|
| `login(username, password)` | POST `Users/Login`, caches JWT + userId in SharedPreferences under keys `jwt_token` and `userId` |
| `getToken()` | Reads JWT from SharedPreferences |

## Class: `ArtifactRepository` extends `ApiDataRepository`
| Method | Description |
|--------|-------------|
| `fetchCategories(token)` | GET `Categories`, sorted by `categoryIndex` |
| `addCategory(category, token)` | POST `Categories` (multipart) |
| `updateCategory(category, token)` | PATCH `Categories/` (multipart) |
| `deleteCategory(categoryId, token)` | DELETE `Categories/{id}` |
| `fetchArtefact(artefactId, token)` | GET `Artefacts/{id}` |
| `addArtifact(artefact, token)` | POST `Artefacts` (multipart) |
| `deleteArtifact(artifactId, token)` | DELETE `Artefacts/{id}` |
| `fetchMostUsedCategories(token, limit)` | GET `Categories/most-used?limit=N` |
| `trackCategoryUsage(categoryId, token)` | POST `Categories/{id}/usage` |

## Class: `UserRepository` extends `ApiDataRepository`
| Method | Description |
|--------|-------------|
| `fetchUser(token)` | GET `Users` — returns single user |
| `fetchAllUsers(token)` | GET `Users` — returns list (same endpoint, different parse) |
| `fetchRelatedContacts(token)` | GET `Contacts` — connected caregivers/children |
| `updateUserSettings(token, nameVisible?, fieldCount?)` | PATCH `Users` |
| `bulkUpdateArtefactsNameShown(token, nameShown)` | PATCH `Artefacts/bulk-update-name-shown` |

## Design Notes
- **Duplication:** `ArtifactModel` and `ArtifactRepository` (this file) duplicate much of the same API logic. `ArtifactModel` also caches in memory; this class does not.
- `AuthRepository` stores the JWT under key `jwt_token`, while `AuthModel` uses `jwtToken` — different SharedPreferences keys for the same data.
- Error handling: catches exceptions and returns `null`/`false` (swallows errors after debug print).
