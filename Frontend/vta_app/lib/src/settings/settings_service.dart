import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vta_app/src/settings/settings_controller.dart';

/// A service that stores and retrieves user settings.
///
/// By default, this class does not persist user settings. If you'd like to
/// persist the user settings locally, use the shared_preferences package. If
/// you'd like to store settings on a web server, use the http package.
class SettingsService {
  /// Loads the User's preferred ThemeMode from local or remote storage.
  Future<ThemeMode> themeMode() async => ThemeMode.system;

  Future<bool?> textUnderImages() async {
    return await SharedPreferencesAsync().getBool('textUnderImages');
  }

  Future<int?> localization() async {
    return await SharedPreferencesAsync().getInt('localization');
  }

  Future<void> updateTextUnderImages(bool newValue) async {
    await SharedPreferencesAsync().setBool('textUnderImages', newValue);
  }

  Future<void> updateLocalization(Localization newLocalization) async {
    await SharedPreferencesAsync()
        .setInt('localization', newLocalization.index);
  }

  /// Persists the user's preferred ThemeMode to local or remote storage.
  Future<void> updateThemeMode(ThemeMode theme) async {
    // Use the shared_preferences package to persist settings locally or the
    // http package to persist settings over the network.
  }
}
