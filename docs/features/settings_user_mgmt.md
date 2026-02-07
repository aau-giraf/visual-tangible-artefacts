# Feature: Settings & User Management

## Summary

Settings & User Management covers **user profile configuration** and **contact/relationship lookup**. The Flutter app's **`SettingsController`** (ChangeNotifier) exposes two user-facing settings — *Text Under Images* (`NameVisible`) and *Linear Artifact Count* (`FieldCount`) — persisted to both `SharedPreferences` (local) and the backend via **`PATCH /api/Users`**. The **`SettingsService`** implements a dual-storage strategy: API-first loading with local fallback. Profile pictures are stored **only** in `SharedPreferences` (as base64 strings) and are never synced. The backend's **`ContactsController`** and the duplicate `UsersController.GetRelatedContacts` endpoint return role-aware contact lists (caregiver→children, child→caregivers). A `Localization` enum exists in the controller but the UI setting is **commented out**.

---

## Class Diagram (Public API Surface)

```mermaid
classDiagram
    direction TB

    %% ── Backend ──────────────────────────────────
    namespace Backend {
        class UsersController {
            +PatchUser(UserPatchDTO) IActionResult
            +GetRelatedContacts() ActionResult~List~UserGetDTO~~
            +GetUsers() ActionResult~List~UserGetDTO~~
            +GetUser(id) ActionResult~UserGetDTO~
            +PutUser(id, User) IActionResult
            +DeleteUser(id) IActionResult
        }
        class ContactsController {
            +GetContacts() ActionResult~List~UserGetDTO~~
        }
        class UserPatchDTO {
            +NameVisible: bool?
            +FieldCount: int?
        }
        class UserGetDTO {
            +Id: string
            +Name: string?
            +Username: string
            +NameVisible: bool
            +FieldCount: int
            +Role: UserRole
            +Categories: List~CategoryGetDTO~
        }
    }

    %% ── Flutter ──────────────────────────────────
    namespace Flutter {
        class SettingsController {
            +textUnderImages: bool
            +linearArtifactCount: int
            +localization: Localization
            +loadSettings() Future~void~
            +updateTextUnderImages(bool?) Future~void~
            +updateLinearArtifactCount(int?) Future~void~
            +updateLocalization(Localization?) Future~void~
        }
        class SettingsService {
            +themeMode() Future~ThemeMode~
            +textUnderImages() Future~bool?~
            +linearArtifactCount() Future~int?~
            +localization() Future~int?~
            +showDirectionalBoard() Future~bool?~
            +updateTextUnderImages(bool) Future~void~
            +updateLinearArtifactCount(int) Future~void~
            +updateLocalization(Localization) Future~void~
            +updateShowDirectionalBoard(bool) Future~void~
            +fetchUserSettings() Future~User?~
            +textUnderImagesFromApi() Future~bool?~
            +linearArtifactCountFromApi() Future~int?~
            +updateThemeMode(ThemeMode) Future~void~
        }
        class UserRepository_API["UserRepository (API)"] {
            +fetchUser(token) Future~User?~
            +fetchUsers(token) Future~List?~
            +fetchRelatedContacts(token) Future~List?~
            +updateUserSettings(token, nameVisible?, fieldCount?) Future~bool~
            +bulkUpdateArtefactsNameShown(token, nameShown) Future~bool~
        }
        class SettingsView {
            «StatelessWidget»
            +controller: SettingsController
        }
        class ProfilePictureSettingsTile {
            «StatefulWidget»
            -_loadProfilePicture() void
            -_saveProfilePicture(Uint8List) void
            -_pickImageFromGallery() void
            -_takePicture() void
        }
    }

    %% ── Relationships ────────────────────────────
    SettingsView --> SettingsController : reads/writes
    SettingsView --> ProfilePictureSettingsTile : contains
    SettingsController --> SettingsService : delegates persistence
    SettingsService --> UserRepository_API : API calls
    UserRepository_API ..> UsersController : PATCH /api/Users
    UserRepository_API ..> ContactsController : GET /api/Contacts
    ProfilePictureSettingsTile ..> SharedPreferences : base64 image
    SettingsService ..> SharedPreferences : local fallback
```

---

## Sequence Diagram — Update "Text Under Images" Setting

```mermaid
sequenceDiagram
    actor User
    participant SV as SettingsView
    participant SC as SettingsController
    participant SS as SettingsService
    participant SP as SharedPreferences
    participant UR as UserRepository (API)
    participant UC as UsersController
    participant DB as MySQL

    User->>SV: Toggle "Text Under Images" switch
    SV->>SC: updateTextUnderImages(true)
    SC->>SC: _textUnderImages = true
    SC->>SC: notifyListeners() → UI rebuilds
    SC->>SS: updateTextUnderImages(true)
    SS->>SP: setBool('textUnderImages', true)

    SS->>SS: _updateUserSettingsInDatabase(nameVisible: true, bulkUpdateArtefacts: true)
    SS->>UR: updateUserSettings(token, nameVisible: true)
    UR->>UC: PATCH /api/Users {NameVisible: true}
    UC->>UC: user.NameVisible = true
    UC->>DB: SaveChangesAsync()
    UC-->>UR: 204 No Content
    UR-->>SS: true

    SS->>UR: bulkUpdateArtefactsNameShown(token, nameShown: true)
    UR->>UC: PATCH /api/Artefacts/bulk-update-name-shown {nameShown: true}
    UC->>DB: UPDATE artefacts SET name_shown = true WHERE userId = ...
    UC-->>UR: 200 OK
    UR-->>SS: true
```

---

## Sequence Diagram — Load Settings on App Start

```mermaid
sequenceDiagram
    participant App as MyApp
    participant SC as SettingsController
    participant SS as SettingsService
    participant UR as UserRepository (API)
    participant UC as UsersController
    participant SP as SharedPreferences

    App->>SC: loadSettings()
    SC->>SS: textUnderImagesFromApi()
    SS->>SS: fetchUserSettings()
    SS->>UR: fetchUser(token)
    UR->>UC: GET /api/Users/{id}
    UC-->>UR: UserGetDTO {nameVisible, fieldCount, ...}
    UR-->>SS: User model

    alt API available
        SS->>SP: setBool('textUnderImages', user.nameVisible)
        SS-->>SC: user.nameVisible
    else API unavailable
        SS->>SP: getBool('textUnderImages')
        SP-->>SS: cached value
        SS-->>SC: cached value
    end

    SC->>SS: linearArtifactCountFromApi()
    Note right of SS: Same API-first / local-fallback pattern
    SS-->>SC: fieldCount value

    SC->>SC: notifyListeners() → UI rebuilds
```

---

## Sequence Diagram — Get Contacts (Role-Based)

```mermaid
sequenceDiagram
    participant App as Flutter App
    participant UR as UserRepository (API)
    participant CC as ContactsController
    participant DB as MySQL

    App->>UR: fetchRelatedContacts(token)
    UR->>CC: GET /api/Contacts (Bearer token)
    CC->>CC: Extract userId from JWT
    CC->>DB: SELECT role FROM Users WHERE id = userId
    alt Role = Caregiver
        CC->>DB: SELECT child FROM Relations WHERE caregiverId = userId AND isActive
        DB-->>CC: List of children
    else Role = Child
        CC->>DB: SELECT caregiver FROM Relations WHERE childId = userId AND isActive
        DB-->>CC: List of caregivers
    end
    CC-->>UR: List~UserGetDTO~
    UR-->>App: List of contacts
```

---

## Architectural Concerns

| # | Concern | Severity | Detail |
|---|---------|----------|--------|
| 1 | **Duplicate contacts endpoint** | 🟠 High | `ContactsController.GetContacts()` (route `api/Contacts`) and `UsersController.GetRelatedContacts()` (route `api/Users/related-contacts`) contain nearly identical role-based contact logic. Consolidate into one. |
| 2 | **Profile picture not synced** | 🟠 High | `_ProfilePictureSettingsTile` stores the image as base64 in `SharedPreferences` only. Switching devices or clearing app data loses the profile picture. Should sync to backend. |
| 3 | **Base64 image in SharedPreferences** | 🟡 Medium | Storing a full-resolution photo as base64 in SharedPreferences is memory-inefficient and can slow app startup. Use file storage with a path reference. |
| 4 | **No validation on PATCH** | 🟡 Medium | `PatchUser` accepts any `FieldCount` value including negatives or zero. Add `[Range]` validation attributes to `UserPatchDTO`. |
| 5 | **Localization setting commented out** | 🟡 Medium | `SettingsController.loadSettings()` has the localization loading fully commented out. The `Localization` enum and `updateLocalization()` method exist but the UI toggle was removed. Either complete or remove. |
| 6 | **Silent failures in SettingsService** | 🟡 Medium | `_updateUserSettingsInDatabase` has empty `catch` blocks and missing log messages (`if (!success) { return; }`). Failures are swallowed with no user feedback. |
| 7 | **`themeMode()` is a stub** | 🟢 Low | Always returns `ThemeMode.system`. `updateThemeMode()` is a no-op. Either implement or remove from the API surface. |
| 8 | **Hardcoded Danish strings** | 🟡 Medium | `SettingsView` uses hardcoded Danish text ("Profilbillede", "Vælg profilbillede") instead of using the app's l10n system. |
| 9 | **Unused DI injections** | 🟢 Low | `ContactsController` injects `IConfiguration` and `ILogger` via primary constructor but `IConfiguration` is never used. |
