# Root App & Theme Documentation

**Files:** `main.dart`, `src/app.dart`, `theme/app_theme.dart`

## Overview
These files constitute the entry point and foundational configuration of the Flutter application.

## Files

### 1. `main.dart`
- **Role:** The application entry point (`main()` function).
- **Responsibilities:**
    - **Initialization:** `WidgetsFlutterBinding.ensureInitialized()`.
    - **Configuration:** Loads `app_settings.json` via `GlobalConfiguration`.
    - **Database:** Initializes SQLite (on mobile) using `DatabaseHelper`.
    - **Dependency Injection:** Registers Singletons ( `Token`, `UserInfo`, `ApiProvider`, `ArtefactController`, `AuthController`) using `GetIt`.
    - **Services:** sets up `CameraManager`, `NotificationService`, and `SettingsController`.
    - **Execution:** Calls `runApp()` with `MultiProvider` to inject global state (`AuthState`, `ArtifactState`, etc.) into `MyApp`.

### 2. `src/app.dart` (`MyApp`)
- **Role:** The root widget.
- **Widget:** `MaterialApp`.
- **Configuration:**
    - **Routing:** Defines `onGenerateRoute` for navigation (handling `SplashView`, `LoginView`, `SettingsView`, etc.).
    - **Localization:** configured with `AppLocalizations.delegate` and supported locales.
    - **Theme:** Applies `ThemeData` using `AppTheme`.
    - **State Listening:** Wraps `MaterialApp` in `ListenableBuilder` to listen to `SettingsController` for theme changes.

### 3. `theme/app_theme.dart` (Inferred)
- **Role:** Centralized styling configuration.
- **Usage:** Used in `app.dart` to set `inputDecorationTheme` and other global style properties, ensuring consistency across the app.
