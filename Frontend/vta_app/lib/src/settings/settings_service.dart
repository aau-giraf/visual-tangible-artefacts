import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/settings/settings_controller.dart';
import 'package:vta_app/src/utilities/data/data_repository.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/modelsDTOs/user.dart';

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

  Future<int?> linearArtifactCount() async {
    return await SharedPreferencesAsync().getInt('linearArtifactCount');
  }

  Future<int?> localization() async {
    return await SharedPreferencesAsync().getInt('localization');
  }

  Future<bool?> showDirectionalBoard() async {
    return await SharedPreferencesAsync().getBool('showDirectionalBoard');
  }

  Future<void> updateTextUnderImages(bool newValue) async {
    await SharedPreferencesAsync().setBool('textUnderImages', newValue);
    // Also update the database
    await _updateUserSettingsInDatabase();
  }

  Future<void> updateLinearArtifactCount(int newValue) async {
    await SharedPreferencesAsync().setInt('linearArtifactCount', newValue);
    // Also update the database
    await _updateUserSettingsInDatabase();
  }

  /// Updates user settings in the database
  Future<void> _updateUserSettingsInDatabase() async {
    try {
      final token = GetIt.instance.get<Token>().value;
      if (token == null) return;
      
      final userRepository = UserRepository();
      final currentUser = await userRepository.fetchUser(token);
      if (currentUser == null) return;

      // TODO: Update the user object with current local settings and send to database
      // final textUnderImages = await SharedPreferencesAsync().getBool('textUnderImages') ?? false;
      // final linearArtifactCount = await SharedPreferencesAsync().getInt('linearArtifactCount') ?? 4;
      
      // TODO: Create updated user object and send to database via PUT API
      // final updatedUser = User(
      //   id: currentUser.id,
      //   name: currentUser.name,
      //   guardianKey: currentUser.guardianKey,
      //   username: currentUser.username,
      //   nameVisible: textUnderImages,
      //   fieldCount: linearArtifactCount,
      //   categories: currentUser.categories,
      // );
      
      // TODO: Add method to UserRepository to update user via PUT API
      // For now, we'll just keep local settings in sync
      
    } catch (e) {
      print('Error updating user settings in database: $e');
    }
  }

  Future<void> updateLocalization(Localization newLocalization) async {
    await SharedPreferencesAsync()
        .setInt('localization', newLocalization.index);
  }

  Future<void> updateShowDirectionalBoard(bool newValue) async {
    await SharedPreferencesAsync().setBool('showDirectionalBoard', newValue);
  }

  /// Fetch user settings from the API
  Future<User?> fetchUserSettings() async {
    try {
      final token = GetIt.instance.get<Token>().value;
      if (token == null) return null;
      
      final userRepository = UserRepository();
      return await userRepository.fetchUser(token);
    } catch (e) {
      print('Error fetching user settings: $e');
      return null;
    }
  }

  /// Loads text under images setting from API or falls back to local storage
  Future<bool?> textUnderImagesFromApi() async {
    final user = await fetchUserSettings();
    if (user != null) {
      // Update local storage with API value for consistency
      await updateTextUnderImages(user.nameVisible);
      return user.nameVisible;
    }
    // Fall back to local storage
    return await textUnderImages();
  }

  /// Loads linear artifact count setting from API or falls back to local storage
  Future<int?> linearArtifactCountFromApi() async {
    final user = await fetchUserSettings();
    if (user != null) {
      // Update local storage with API value for consistency
      await updateLinearArtifactCount(user.fieldCount);
      return user.fieldCount;
    }
    // Fall back to local storage
    return await linearArtifactCount();
  }

  /// Persists the user's preferred ThemeMode to local or remote storage.
  Future<void> updateThemeMode(ThemeMode theme) async {
    // Use the shared_preferences package to persist settings locally or the
    // http package to persist settings over the network.
  }
}
