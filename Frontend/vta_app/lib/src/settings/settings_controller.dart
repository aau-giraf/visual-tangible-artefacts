import 'package:flutter/material.dart';

import 'settings_service.dart';

/// A class that many Widgets can interact with to read user settings, update
/// user settings, or listen to user settings changes.
///
/// Controllers glue Data Services to Flutter Widgets. The SettingsController
/// uses the SettingsService to store and retrieve user settings.
class SettingsController with ChangeNotifier {
  SettingsController(this._settingsService);

  // Make SettingsService a private variable so it is not used directly.
  final SettingsService _settingsService;

  bool _textUnderImages = false;

  Localization _localization = Localization.danish;

  bool get textUnderImages => _textUnderImages;

  Localization get localization => _localization;

  /// Load the user's settings from the SettingsService. It may load from a
  /// local database or the internet. The controller only knows it can load the
  /// settings from the service.
  Future<void> loadSettings() async {
    // Load textUnderImages
    var textUnderImages = await _settingsService.textUnderImages();
    if (textUnderImages != null) {
      _textUnderImages = textUnderImages;
    }
    // Load localization
    var localization = await _settingsService.localization();
    if (localization != null) {
      _localization = Localization.values[localization];
    }
    // Important! Inform listeners a change has occurred.
    notifyListeners();
  }

  Future<void> updateTextUnderImages(bool? newValue) async {
    if (newValue == null) return;
    if (newValue == _textUnderImages) return;

    _textUnderImages = newValue;

    notifyListeners();

    await _settingsService.updateTextUnderImages(newValue);
  }

  Future<void> updateLocalization(Localization? newLocalization) async {
    if (newLocalization == null) return;

    if (newLocalization == _localization) return;

    _localization = newLocalization;

    notifyListeners();

    await _settingsService.updateLocalization(newLocalization);
  }
}

enum Localization { english, danish }
