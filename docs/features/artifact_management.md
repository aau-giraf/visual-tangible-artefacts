# Feature: Artifact Management

## Summary

Artifact Management is the core content system of VTA. **Artefacts** (images with optional sounds and names) are grouped into **Categories**, both owned by a user. The backend exposes two controllers — `ArtefactsController` (CRUD + TTS endpoints at `api/Artefacts`) and `CategoriesController` (CRUD + usage tracking at `api/Categories`) — with filesystem-backed asset storage via `ImageUtilities` and `SoundUtilities`, and static file serving through `AssetsController`. The Flutter app wraps these APIs in `ArtifactModel` (HTTP calls + local in-memory cache) → `ArtefactController` (UI orchestration with confirmation dialogs and snackbars). Local database stubs exist (`ArtefactRepository`, `CategoryRepository`) but are currently commented out, with all operations going through the REST API.

---

## Class Diagram (Public API Surface)

```mermaid
classDiagram
    direction LR

    %% ── Backend ──────────────────────────────────
    namespace Backend {
        class ArtefactsController {
            +GetArtefacts() ActionResult~List~ArtefactGetDTO~~
            +GetArtefact(artefactId) ActionResult~ArtefactGetDTO~
            +PatchArtefact(ArtefactPatchDTO) IActionResult
            +PostArtefact(ArtefactPostDTO) ActionResult~ArtefactGetDTO~
            +DeleteArtefact(artefactId) IActionResult
            +PlayArtefactAudio(artefactId) IActionResult
            +GenerateSpeech(ArtefactTextToSpeechDTO) ActionResult~ArtefactGetDTO~
            +GenerateSpeechSimple(SimpleTtsRequest) IActionResult
            +GenerateSpeechAndSave(ArtefactTtsRequest) IActionResult
            +GenerateAndSaveSpeech(StandaloneTtsRequest) IActionResult
            +BulkUpdateNameShown() IActionResult
        }
        class CategoriesController {
            +GetCategories() ActionResult~List~CategoryGetDTO~~
            +GetCategory(categoryId) ActionResult~CategoryGetDTO~
            +PatchCategory(CategoryPatchDTO) IActionResult
            +PostCategory(CategoryPostDTO) ActionResult~CategoryGetDTO~
            +DeleteCategory(categoryId) IActionResult
            +TrackCategoryUsage(categoryId) IActionResult
            +GetMostUsedCategories(limit) ActionResult~List~CategoryGetDTO~~
        }
        class AssetsController {
            +GetArtefactImage(userId, filename) IActionResult
            +GetCategoryImage(userId, filename) IActionResult
            +GetSoundFile(userId, filename) IActionResult
        }
        class ImageUtilities {
            +AddImage(file, id, dir, userId)$ Task~string?~
            +DeleteImage(imgName, dir, userId)$ bool?
        }
        class SoundUtilities {
            +AddSound(file, soundId, userId)$ Task~string?~
            +AddSound(bytes, soundId, userId, ext)$ Task~string?~
            +DeleteSound(soundId, userId)$ bool?
        }
    }

    %% ── Flutter ──────────────────────────────────
    namespace Flutter {
        class ArtefactController {
            +categories List~Category~?
            +mostUsedCategories List~Category~?
            +updateArtifacts(context?) Future~void~
            +updateMostUsedCategories(context?, limit) Future~void~
            +newCategory(context) Future~void~
            +deleteCategory(category, context) Future~void~
            +newArtifact(context, categoryId, onCreated?) Future~void~
            +deleteArtefact(context, artefact) Future~bool~
            +updateArtefact(context, artefact) Future~void~
            +trackCategoryUsage(categoryId, context?) Future~void~
            +clearUserData() Future~void~
        }
        class ArtifactModel {
            +categories List~Category~?
            +mostUsedCategories List~Category~?
            +fetchAndUpdateCategories(token) Future~void~
            +fetchAndUpdateMostUsedCategories(token, limit) Future~void~
            +postCategory(category, token) Future~void~
            +deleteCategory(category, token) Future~void~
            +postArtefact(artefact, token) Future~Artefact~
            +deleteArtefact(artefact, token) Future~void~
            +updateArtefact(artefact, token) Future~void~
            +trackCategoryUsage(categoryId, token) Future~bool~
            +clearCache() void
        }
        class ApiProvider {
            +fetchAsJson(path, headers) Future~Response?~
            +postAsJson(path, body, headers) Future~Response?~
            +sendAsMultiPart(method, path, body, headers) Future~Response?~
            +delete(path, headers) Future~Response?~
        }
        class AddItemPopup {
            +isCategory bool
            +title String
            +onSubmit Function
        }
    }

    %% ── Relationships ────────────────────────────
    ArtefactController --> ArtifactModel : delegates to
    ArtifactModel --> ApiProvider : HTTP calls
    ArtefactController ..> AddItemPopup : shows dialog

    ArtifactModel ..> ArtefactsController : POST/PATCH/DELETE /api/Artefacts
    ArtifactModel ..> CategoriesController : GET/POST/DELETE /api/Categories
    ArtefactsController --> ImageUtilities : save/delete artefact images
    ArtefactsController --> SoundUtilities : save/delete sound files
    CategoriesController --> ImageUtilities : save/delete category images
    AssetsController ..> ImageUtilities : serves files from Assets/
```

---

## Sequence Diagram — Create Artefact

```mermaid
sequenceDiagram
    actor User
    participant UI as ArtifactBoardScreen
    participant AC as ArtefactController
    participant Popup as AddItemPopup
    participant AM as ArtifactModel
    participant AP as ApiProvider
    participant BC as ArtefactsController (Backend)
    participant IU as ImageUtilities
    participant SU as SoundUtilities
    participant DB as MySQL

    User->>UI: Tap "Add artefact"
    UI->>AC: newArtifact(context, categoryId)
    AC->>Popup: showDialog(AddItemPopup)
    User->>Popup: Enter name, pick image, record sound
    Popup->>AC: onSubmit(name, imageBytes, soundBytes)
    AC->>AM: postArtefact(artefact, token)
    AM->>AP: sendAsMultiPart("POST", "Artefacts", body)
    AP->>BC: POST /api/Artefacts (multipart form)
    BC->>BC: Validate userId from JWT
    BC->>IU: AddImage(image, artefactId, "Artefacts", userId)
    IU-->>BC: imagePath
    BC->>SU: AddSound(sound, artefactId, userId)
    SU-->>BC: soundPath
    BC->>DB: INSERT Artefact
    DB-->>BC: OK
    BC-->>AP: 200 ArtefactGetDTO (with asset URLs)
    AP-->>AM: Response
    AM->>AM: Add to local categories cache
    AM-->>AC: Artefact
    AC->>AC: notifyListeners()
    AC->>UI: Show success snackbar
```

---

## Sequence Diagram — Fetch Categories with Artefacts

```mermaid
sequenceDiagram
    participant AC as ArtefactController
    participant AM as ArtifactModel
    participant AP as ApiProvider
    participant CC as CategoriesController (Backend)
    participant DB as MySQL

    AC->>AM: fetchAndUpdateCategories(token)
    AM->>AP: fetchAsJson("Categories", headers)
    AP->>CC: GET /api/Categories
    CC->>DB: SELECT Categories WHERE UserId = jwt.id<br/>INCLUDE Artefacts
    DB-->>CC: List~Category~ with nested Artefacts
    CC->>CC: Map to CategoryGetDTO (includes asset URLs)
    CC-->>AP: 200 List~CategoryGetDTO~
    AP-->>AM: Response
    AM->>AM: Parse JSON → List~Category~
    AM->>AM: Sort by categoryIndex
    AM->>AM: categories = sorted list
    AM-->>AC: done
    AC->>AC: notifyListeners()
```

---

## Architectural Concerns

| # | Concern | Severity | Detail |
|---|---------|----------|--------|
| 1 | **ArtefactsController is a god class (795 LOC)** | 🔴 Critical | Handles CRUD, 4 different TTS endpoints, audio playback, bulk operations, and inline `ElevenLabsService` creation. Extract TTS into a dedicated `TtsController` and use DI for `ElevenLabsService`. |
| 2 | **Commented-out local database code** | 🟠 High | `ArtifactModel` has complete local DB methods (`_postArtefactLocal`, `_deleteCategoryLocal`, etc.) all commented out. This creates confusion — either finish offline-first or remove the dead code. |
| 3 | **No backend service/repository layer** | 🟠 High | Both controllers use `VTAContext` directly (EF Core DbContext in controller). Extracting an `IArtefactService` / `ICategoryService` would improve testability and SRP. |
| 4 | **Static utility classes** | 🟡 Medium | `ImageUtilities` and `SoundUtilities` are static — cannot be mocked in tests, no DI. Convert to injectable services (e.g., `IFileStorageService`). |
| 5 | **Asset URL construction in DTOConverter** | 🟡 Medium | `DTOConverter.MapArtefactToArtefactGetDTO` receives `Request.Scheme` and `Request.Host` to build URLs. This breaks if assets move to a CDN or object storage. Centralise URL generation. |
| 6 | **Console.WriteLine in production code** | 🟡 Medium | `PostArtefact()` contains `Console.WriteLine("----" + artefactPostDTO.Name)` — debug noise. Replace with structured `ILogger`. |
| 7 | **Duplicate `updateArtifact` methods** | 🟡 Medium | `ArtefactController` has both `updateArtefact(context, artefact)` and `updateArtifact(context, artefact)` (same signature, lines 186 and 229) — one delegates to model, the other also shows snackbar. Consolidate. |
| 8 | **No authorization on AssetsController** | 🟡 Medium | Any authenticated user can fetch any other user's asset files via `GET /api/Assets/Artefacts/{userId}/{filename}` — no ownership check. |
