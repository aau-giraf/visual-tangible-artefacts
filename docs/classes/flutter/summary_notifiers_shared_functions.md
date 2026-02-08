# Notifiers & Shared Functions Documentation

**Paths:**
- `Frontend/vta_app/lib/src/notifiers/`
- `Frontend/vta_app/lib/src/functions/`

## Overview
This section covers global state management using `ChangeNotifier` (Provider) and shared utility functions used across the app.

## Notifiers (`vta_notifiers.dart`)

This file contains multiple `ChangeNotifier` classes that act as global state containers, provided at the root of the app via `MultiProvider`.

### `AuthState`
- **Role:** Manages authentication state (User ID and JWT Token).
- **Methods:** `login()`, `logout()`, `loadTokenFromCache()`, `loadUserIdFromCache()`.
- **Storage:** Persists token and ID to `SharedPreferences`.

### `ArtifactState`
- **Role:** Manages the list of categories and artifacts.
- **Methods:** `loadCategories()`, `addCategory()`, `updateCategory()`.
- **Data Source:** Uses `ArtifactRepository` to fetch data.

### `UserState` (inferred from usage)
- **Role:** Manages current user profile data.
- **Methods:** `loadUser()`.

## Shared Functions

### `auth.dart` (`AuthPage`)
- **Role:** Acts as the "Gatekeeper" or "Splash" widget.
- **Logic:**
    1. Checks if a valid token exists in cache.
    2. If valid: Navigates to `LoadingPage` (which loads user/artifact data) and then to the main app.
    3. If invalid: Navigates to `LoginScreen`.

### `loading_page.dart` (`LoadingPage`)
- **Role:** A generic utility widget that executes a list of futures (`awaitCallbacks`) while showing a loading spinner.
- **Behavior:**
    - Shows `CircularProgressIndicator` while waiting.
    - Shows `ErrorScreen` if any callback fails.
    - Renders the `child` widget upon success.
