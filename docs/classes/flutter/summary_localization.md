# Localization Documentation

**Path:** `Frontend/vta_app/lib/src/localization/`

## Overview
The VTA app uses Flutter's standard `flutter_localizations` package and ARB (Application Resource Bundle) files for internationalization (i18n).

## Structure

- **`app_en.arb`**: The source of truth for English strings. Contains key-value pairs where keys are the resource identifiers and values are the English translations.
- **`app_localizations.dart`**: Generated code (by Flutter) that provides the localized strings to the app.
- **`app_localizations_en.dart`**: Generated code specifically for the English locale.

## Usage
- The `AppLocalizations.delegate` is registered in `MaterialApp` (in `src/app.dart`).
- Strings are accessed in widgets via `AppLocalizations.of(context)!.keyName`.

## Note
Although `Localization` enum exists in `SettingsController` with support for Danish, the current file structure primarily shows an English ARB file (`app_en.arb`). Danish support might be pending or handled dynamically.
