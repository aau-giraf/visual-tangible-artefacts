# ArtifactModel

**File:** `Frontend/vta_app/lib/src/models/artefact_model.dart` (494 lines)

## Purpose

Central orchestrator for artefact and category data. Manages CRUD operations against the backend API and maintains an in-memory cache of categories (with nested artefacts). Also contains stub local-database methods for future offline support (currently commented out).

## Class: `ArtifactModel`

### Dependencies
- `ApiProvider` — injected HTTP client for all API calls
- `ArtefactRepository`, `CategoryRepository` — local DB access (used in stub methods only)
- `artefact_mapper.dart` — DTO-to-DB conversion

### Key Fields
- `categories: List<Category>?` — cached category list (each containing nested artefacts)
- `mostUsedCategories: List<Category>?` — top-N most-used categories
- `apiProvider: ApiProvider` — injected API client

### Public Methods

| Method | Description |
|--------|-------------|
| `fetchAndUpdateCategories(token)` | GET `Users/Categories`, parses JSON, sorts by `categoryIndex`, updates `categories` cache |
| `postCategory(category, token)` | POST `Users/Categories` as multipart, adds returned category to cache |
| `deleteCategory(category, token)` | DELETE `Users/Categories/{id}`, removes from cache |
| `postArtefact(artefact, token)` | POST `Users/Artefacts` as multipart (handles `Sound` as `Uint8List`), adds to correct category in cache. Special-cases `Session-Artefact` categoryId (not added to cache) |
| `deleteArtefact(artefact, token)` | DELETE `Users/Artefacts/{id}`, removes from category in cache |
| `updateArtefact(artefact, token)` | PATCH `Users/Artefacts` as multipart, then re-fetches the artefact via GET to get updated URLs |
| `fetchAndUpdateMostUsedCategories(token, limit)` | GET `Users/Categories/most-used?limit=N` |
| `trackCategoryUsage(categoryId, token)` | POST `Users/Categories/{id}/usage`, refreshes most-used list |
| `clearCache()` | Empties both category lists |

### Private Methods (Local DB — all commented out at call sites)
`_fetchAndUpdateCategoriesLocal`, `_postArtefactLocal`, `_postCategoryLocal`, `_deleteCategoryLocal`, `_deleteArtefactLocal`, `_updateArtefactLocal`, `_trackCategoryUsageLocal`, `_fetchAndUpdateMostUsedCategoriesLocal` — prepared for offline-first architecture but not active.

### Error Handling
All methods catch exceptions, print debug info, and rethrow. Throws `ArtifactException` with Danish-language messages on non-OK responses.

## Class: `ArtifactException`
Custom exception with a `message` field. Default message: `'ArtifactException'`.

## Design Notes
- Dual online/offline architecture is scaffolded but offline paths are commented out.
- Category-to-DB mapping (`_categoryToDb`) is inlined here rather than in the mappers directory.
- The `postArtefact` method handles binary sound data by injecting `Uint8List` into the multipart body under key `'Sound'`.
- Error messages are in Danish.
