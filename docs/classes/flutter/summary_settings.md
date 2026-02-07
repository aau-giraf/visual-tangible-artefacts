# Settings Module Documentation

**Path:** `Frontend/vta_app/lib/src/settings/`

## Overview
The settings module manages user preferences and application configuration using a standard Controller-Service pattern. It handles settings like "Text Under Images", "Linear Artifact Count", and Localization.

## Files

### 1. `settings_controller.dart`
- **Role:** The "Glue" between the UI and the data service.
- **Key Class:** `SettingsController` (extends `ChangeNotifier`).
- **State:** Maintains local state variables (`_textUnderImages`, `_linearArtifactCount`, `_localization`).
- **Methods:**
    - `loadSettings()`: Loading initial values from the service.
    - `update...()`: Methods to change a setting, notify listeners (UI), and persist the change via the service.

### 2. `settings_service.dart`
- **Role:** Handles persistence and data retrieval.
- **Key Class:** `SettingsService`.
- **Storage:** Uses `SharedPreferencesAsync` for local storage and `UserRepository` to sync key settings (like `textUnderImages` and `linearArtifactCount`) to the backend database.
- **Sync Logic:** Includes logic to bulk update artifacts in the database if the "Text Under Images" setting changes globally.

### 3. `settings_view.dart`
- **Role:** The UI screen for modifying settings.
- **Key Class:** `SettingsView`.
- **Widgets:** Uses `flutter_settings_screens` library widgets (`SwitchSettingsTile`, `DropDownSettingsTile`) to build the preferences list.
- **Integration:** Wraps content in a `ListenableBuilder` to automatically rebuild when the controller notifies of changes.
