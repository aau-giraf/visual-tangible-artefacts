# VTA Improvement Roadmap

> Concrete plan for stabilising the codebase before adding features.
> For detailed architectural analysis see `docs/improvement_proposals.md`.
> its KEY that you FIRST plan and then execute
> ensure that each logically clustered improvement is its own feature branch

---

## Phase 1 — Stop the Bleeding (1–2 weeks) ✅ COMPLETED

Goal: CI catches real problems, tests pass, critical security holes are closed.


### 1.1 Fix the 14 failing backend tests ✅

**All 13 integration test failures share one root cause: a route conflict between `UsersController` and `BoardsController`.**

`UsersController` uses `[Route("api/[controller]")]` = `api/Users`.
`BoardsController` uses `[Route("api/Users/Boards")]`.

When a test POSTs to `/api/Users/Boards`, ASP.NET sees an ambiguous match — `UsersController` thinks `Boards` is a route parameter, and returns 405 MethodNotAllowed. Every test that calls `CreateBoard()` in the test helpers fails, and every test downstream of that fails with empty JSON deserialization errors.

**Fix:** Change the `BoardsController` route to something unambiguous (e.g. `[Route("api/boards")]`) and update tests + Flutter API calls to match. Alternatively, add explicit route constraints on `UsersController` to prevent the collision.

The 1 remaining unit test failure (`BoardArtefactLayoutDTO_DefaultValues_ShouldBeCorrect`) should pass on a clean `dotnet build && dotnet test` — the DTO defaults are correct in source, the test was run against a stale binary.

**Files to touch:**
- `Backend/VTA.API/Controllers/BoardsController.cs` — route attribute
- `Backend/VTA.API/Controllers/SavedArtefactsController.cs` — route attribute (if it also nests under `api/Users/`)
- `Backend/VTA.Tests/` — update any hardcoded URL strings in test helpers
- `Frontend/vta_app/` — update API URL paths in board-related model/service files
- `Frontend/admin-dashboard/` — update API URL paths if boards are admin-managed

### 1.2 Add Flutter and admin-dashboard CI jobs ✅

The CI workflow at `.github/workflows/dotnet-desktop.yml` only runs `dotnet test`. The Flutter app and admin dashboard have zero CI — broken builds can merge to `dev-main` undetected.

Add two jobs to the existing workflow:

**Flutter job:**
```yaml
flutter-ci:
  runs-on: ubuntu-latest
  defaults:
    run:
      working-directory: Frontend/vta_app
  steps:
    - uses: actions/checkout@v4
    - uses: subosito/flutter-action@v2
      with:
        flutter-version: '3.x'
    - run: flutter pub get
    - run: flutter analyze --fatal-infos
    - run: flutter test
```

**Admin dashboard job:**
```yaml
admin-ci:
  runs-on: ubuntu-latest
  defaults:
    run:
      working-directory: Frontend/admin-dashboard
  steps:
    - uses: actions/checkout@v4
    - uses: actions/setup-node@v4
      with:
        node-version: '20'
    - run: npm ci
    - run: npm run build  # runs vue-tsc + vite build
```

**File to touch:** `.github/workflows/dotnet-desktop.yml`

### 1.3 Remove admin dashboard mock auth bypass ✅

The login function in `Frontend/admin-dashboard/src/stores/auth.ts` has a mock block (lines 14–21) that sets a fake token, marks the user as authenticated, and `return`s before ever calling the real API. The admin dashboard never actually authenticates.

```typescript
// This entire block must be deleted:
token.value = 'local-mock-token';
user.value = { id: 'local-user-id' };
isAuthenticated.value = true;
localStorage.setItem('token', token.value);
localStorage.setItem('user', JSON.stringify(user.value));
router.push('/dashboard');
return;
```

The real login logic already exists below it (lines 24–35) and will work once this block is removed.

**File to touch:** `Frontend/admin-dashboard/src/stores/auth.ts` — delete lines 14–21.

### 1.4 Fix admin user deletion orphaning assets ✅

`AdminController.DeleteUser()` calls `Users.Remove()` without cleaning up filesystem assets (images, sounds, board snapshots). Database rows cascade-delete via MySQL foreign keys, but files on disk are orphaned permanently.

`UsersController.DeleteUser()` (lines 310–370) already does this correctly — it eager-loads artefacts and boards, deletes images/sounds/snapshots from disk, then removes DB entities.

**Fix:** Extract the cascade-delete logic from `UsersController.DeleteUser()` into a shared static helper (or a service method — this seeds Phase 2), and call it from both controllers.

**Files to touch:**
- `Backend/VTA.API/Controllers/UsersController.cs` — extract delete logic
- `Backend/VTA.API/Controllers/AdminController.cs` — call shared delete logic

### 1.5 Stop exposing the ElevenLabs API key to client devices ✅

The Flutter app stores the ElevenLabs API key in `SharedPreferences` and calls `api.elevenlabs.io` directly from the user's device. The key is extractable.

The backend already has a working TTS proxy — `ElevenLabsService` in `Backend/VTA.API/Utilities/ElevenLabsService.cs` with endpoints on `ArtefactsController` (`GenerateSpeechSimple`, `GenerateSpeechAndSave`).

**Fix:** Rewrite Flutter's `ElevenLabsService` to call the backend TTS endpoints instead of `api.elevenlabs.io`. Remove the API key input UI and client-side key storage.

**Files to touch:**
- `Frontend/vta_app/lib/src/utilities/elevenlabs_service.dart` — rewrite to call backend
- `Frontend/vta_app/lib/src/utilities/config/elevenlabs_config.dart` — delete
- `Frontend/vta_app/lib/src/controllers/elevenlabs_controller.dart` — remove API key management
- `Frontend/vta_app/lib/src/ui/widgets/text_to_speech_widget.dart` — remove API key input UI

---

## Phase 2 — Backend Service Layer (2–4 weeks)

Extract business logic from controllers into service classes with interfaces. Start with the duplicated-logic hotspots identified in `docs/improvement_proposals.md` §2–3:

- `IUserService` — unified `DeleteUser()` with cascade cleanup (seeds planted in 1.4), auth logic
- `IRelationService` — single source of truth for pairing CRUD (currently duplicated between `AdminController` and `RelationController`)
- `ITtsService` — extract ElevenLabs integration from `ArtefactsController`

Pattern: controllers handle HTTP concerns only (model binding, auth, status codes). Services own business logic and `VTAContext`. Register via `builder.Services.AddScoped<IService, Service>()`.

## Phase 3 — God Class Splits (2–4 weeks)

Split the 7 files over 450 LOC identified in `docs/improvement_proposals.md` §1. Prioritise by coupling risk — don't split proactively, split when you're already touching the file for a feature or bugfix.

## Phase 4 — Reliability & Observability (ongoing)

- Replace `Console.WriteLine` (100+) with `ILogger` in backend
- Replace `print()`/`debugPrint()` (100+) with a logging package in Flutter
- Fix 23 empty catch blocks in Flutter
- Add sync transaction safety and retry logic
- Add pagination to list endpoints

## Phase 5 — Backlog

- Token refresh flow
- DI consistency in Flutter
- State management consolidation
- Profile picture sync to backend
- Redis backplane for SyncService (only when horizontal scaling is needed)
