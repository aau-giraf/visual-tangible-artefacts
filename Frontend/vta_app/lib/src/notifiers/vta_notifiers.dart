
import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/modelsDTOs/category.dart';
import 'package:vta_app/src/modelsDTOs/user.dart';
import 'package:vta_app/src/utilities/data/data_repository.dart';
import 'package:logging/logging.dart';

/// Create a logger for the VtaNotifiers for diagnostic purposes
final _log = Logger('VtaNotifiers');

/// AuthState manages the authentication state of the application, 
/// including login, logout, and token management.
class AuthState with ChangeNotifier {
  String? _token;
  String? _userId;

  String? get token => _token;
  String? get userId => _userId;


/// Attempts to log in the user with the provided username and password.
  Future<String?> login(String username, String password) async {
    try {
      var loginResponse = await AuthRepository().login(username, password);
      if (loginResponse != null) {
        _token = loginResponse.token;
        _userId = loginResponse.userId;
        notifyListeners();
        return token;
      } else {
        // This shouldn't happen since AuthRepository throws exceptions
        throw Exception('Login failed - no response received');
      }
    } catch (e) {
      // Clear any existing token/userId on login failure
      _token = null;
      _userId = null;
      notifyListeners();
      // Re-throw the exception so it reaches the UI
      rethrow;
    }
  }

/// Loads the JWT token from shared preferences and checks if it's valid (not expired).
  Future<bool> loadTokenFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    if (_token != null && !JwtDecoder.isExpired(_token!)) {
      return true;
    } else {
      return false;
    }
  }

/// Loads the user ID from shared preferences.
  Future<bool> loadUserIdFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    if (_userId != null) {
      return true;
    } else {
      return false;
    }
  }

/// Logs out the user by clearing the token and user ID from memory and shared preferences.
  void logout() {
    _token = null;
    SharedPreferences.getInstance().then((prefs) {
      prefs.remove('jwt_token');
      prefs.remove('userId');
    });
    notifyListeners();
  }
}

/// ArtifactState manages the state of categories and artefacts in the application,
/// including loading, adding, updating, and deleting categories and artefacts.
class ArtifactState with ChangeNotifier {
  List<Category>? _categories = [];

  List<Category>? get categories => _categories;

/// Loads categories from the repository using the provided token.
  Future<bool> loadCategories(String token) async {
    _categories = await ArtifactRepository().fetchCategories(token);
    if (_categories != null) {
      notifyListeners();
      return true;
    }
    return false;
  }


/// Adds a new category to the repository and updates the local state.
  Future<bool> addCategory(Category category, {required String token}) async {
    var newCategory =
        await ArtifactRepository().addCategory(category, token: token);
    if (newCategory != null) {
      _categories?.add(newCategory);
      _categories?.sort((a, b) => a.categoryIndex!.compareTo(b.categoryIndex!));
      notifyListeners();
      return true;
    }
    return false;
  }


/// Updates an existing category in the repository and updates the local state.
  Future<bool> updateCategory(Category category,
      {required String token}) async {
    try {
      var responseOk =
          await ArtifactRepository().updateCategory(category, token: token);
      if (responseOk == false) return false;
      var categoryMatch = _categories
          ?.firstWhere((element) => element.categoryId == category.categoryId);
      if (categoryMatch != null) {
        int index = _categories!.indexOf(categoryMatch);
        _categories![index].name = category.name;
      }
      _categories?.sort((a, b) => a.categoryIndex!.compareTo(b.categoryIndex!));
      notifyListeners();
      return true;
    } catch (e) {
      return false;
    }
  }


/// Deletes a category from the repository and updates the local state.
  Future<bool> deleteCategory(String categoryId,
      {required String token}) async {
    try {
      final success =
          await ArtifactRepository().deleteCategory(categoryId, token: token);
      if (success) {
        _categories
            ?.removeWhere((category) => category.categoryId == categoryId);
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _log.info('Fejl ved sletning af kategori: $e');
      return false;
    }
  }


/// Adds a new artefact to the repository and updates the local state.
  Future<bool> addArtifact(Artefact artifact, {required String token}) async {
    var newArtifact =
        await ArtifactRepository().addArtifact(artifact, token: token);
    if (newArtifact != null) {
      _categories
          ?.firstWhere(
              (category) => category.categoryId == newArtifact.categoryId)
          .artefacts
          ?.add(newArtifact);
      notifyListeners();
      return true;
    }
    return false;
  }

  // Inside ArtifactState class:
  
  /// Deletes an artefact from the repository and updates the local state.
  Future<bool> deleteArtifact(String artifactId,
      {required String token}) async {
    try {
      final success = await ArtifactRepository()
          .deleteArtifact(artifactId: artifactId, token: token);

      if (success) {
        // Remove artifact from local state
        for (var category in _categories ?? []) {
          category.artefacts
              ?.removeWhere((artifact) => artifact.artefactId == artifactId);
        }
        notifyListeners();
        return true;
      }
      return false;
    } catch (e) {
      _log.info('Fejl ved sletning af artefact: $e');
      return false;
    }
  }

  List<Category>? _mostUsedCategories = [];

  List<Category>? get mostUsedCategories => _mostUsedCategories;

/// Loads the most used categories from the repository using the provided token.
  Future<bool> loadMostUsedCategories(String token, {int limit = 3}) async {
    _mostUsedCategories =
        await ArtifactRepository().fetchMostUsedCategories(token, limit: limit);
    _mostUsedCategories ??= [];
    notifyListeners();
    return true;
  }

/// Tracks the usage of a category and updates the most used categories.
  Future<bool> trackCategoryUsage(String categoryId,
      {required String token}) async {
    var responseOk =
        await ArtifactRepository().trackCategoryUsage(categoryId, token: token);
    if (responseOk) {
      await loadMostUsedCategories(token);
      return true;
    } else {
      return false;
    }
  }
}

/// UserState manages the state of the user in the application, including loading user data.
class UserState with ChangeNotifier {
  User? _user;
  User? get user => _user;
  Future<bool> loadUser(String token) async {
    _user = await UserRepository().fetchUser(token);
    if (_user != null) {
      notifyListeners();
      return true;
    }
    return false;
  }
}
