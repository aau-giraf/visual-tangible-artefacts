import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/modelsDTOs/category.dart';
import 'package:vta_app/src/modelsDTOs/login_form.dart';
import 'package:vta_app/src/modelsDTOs/login_response.dart';
import 'package:vta_app/src/modelsDTOs/user.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/utilities/platform_utils.dart';
import 'dart:convert';
import 'package:logging/logging.dart';


final _log = Logger('DataRepository');
abstract class ApiDataRepository {
  var apiSettings = GlobalConfiguration().appConfig['ApiSettings'];
  late ApiProvider apiProvider;

  ApiDataRepository() {
    apiProvider = ApiProvider(baseUrl: PlatformUtils.getApiUrl());
    _log.fine('[DataRepository] Using API URL: ${PlatformUtils.getApiUrl()}');
  }

  bool responseOk(http.Response? response) {
    if (response == null) {
      throw Exception('No response from server.');
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return true;
    } else if (response.statusCode == 401) {
      throw Exception('Invalid username or password.');
    } else if (response.statusCode == 500) {
      throw Exception('500 Internal server error.');
    } else {
      throw Exception('Unexpected response code ${response.statusCode}.');
    }
  }
}

class AuthRepository extends ApiDataRepository {
  Future<LoginResponse?> login(String username, String password) async {
    var loginForm = LoginForm(username: username, password: password);

    final response =
        await apiProvider.postAsJson('Users/Login', body: loginForm.toJson());
    
    // responseOk() will throw exception for 401, 500, etc. or return true for success
    // It should never return false, but if it does, we'll handle it
    try {
      if (responseOk(response)) {
        var loginResponse = LoginResponse.fromJson(json.decode(response!.body));
        if (loginResponse.token != null) {
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', loginResponse.token!);
          await prefs.setString('userId', loginResponse.userId ?? '');
          return loginResponse;
        } else {
          throw Exception('Login response received, but token is null.');
        }
      } else {
        // This should never happen since responseOk() throws exceptions
        throw Exception('Unexpected login failure.');
      }
    } catch (e) {
      // Re-throw the exception so it bubbles up to the UI
      _log.fine('Login error in AuthRepository: $e');
      rethrow;
    }
  }

  Future<String?> getToken() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }
}

class ArtifactRepository extends ApiDataRepository {
  Future<List<Category>?> fetchCategories(String token) async {
    try {
      Map<String, String> headers = {
        "Authorization": 'Bearer $token',
      };
      var response =
          await apiProvider.fetchAsJson('Categories', headers: headers);
      if (responseOk(response)) {
        var jsonResponse = json.decode(response!.body) as List;
        var categories = jsonResponse
            .map((jsonCategory) =>
                Category.fromJson(jsonCategory as Map<String, dynamic>))
            .toList();
        categories.sort((a, b) => a.categoryIndex!.compareTo(b.categoryIndex!));
        return categories;
      } else {
        return null;
      }
    } catch (e) {
      _log.fine("An error occured while fetching categories: $e");
      return null;
    }
  }

  Future<Category?> addCategory(Category category,
      {required String token}) async {
    try {
      var headers = <String, String>{'Authorization': 'Bearer $token'};
      var response = await apiProvider.sendAsMultiPart(
          'POST', 'Categories',
          headers: headers, body: category.toJson());
      if (responseOk(response)) {
        var jsonResponse = json.decode(response!.body);
        return Category.fromJson(jsonResponse);
      }
      return null;
    } catch (e) {
      _log.fine("An error occured while posting category: $e");
      return null;
    }
  }

  Future<bool> updateCategory(Category category,
      {required String token}) async {
    var headers = <String, String>{'Authorization': 'Bearer $token'};
    var response = await apiProvider.sendAsMultiPart(
        'PATCH', 'Categories/',
        headers: headers, body: category.toJson());
    if (responseOk(response)) {
      return true;
    }
    return false;
  }

  Future<bool> deleteCategory(String categoryId,
      {required String token}) async {
    try {
      var headers = <String, String>{'Authorization': 'Bearer $token'};
      var response = await apiProvider.delete(
        'Categories/$categoryId',
        headers: headers,
      );
      if (responseOk(response)) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      _log.fine("An error occured while deleting category: $e");
      return false;
    }
  }

  Future<Artefact?> fetchArtefact(String artefactId,
      {required String token}) async {
    try {
      Map<String, String> headers = {
        "Authorization": 'Bearer $token',
      };
      var response = await apiProvider
          .fetchAsJson('Artefacts/$artefactId', headers: headers);
      if (responseOk(response)) {
        var jsonResponse = json.decode(response!.body);
        return Artefact.fromJson(jsonResponse);
      }
      return null;
    } catch (e) {
      _log.fine("An error occurred while fetching artefact: $e");
      return null;
    }
  }

  Future<Artefact?> addArtifact(Artefact artefact,
      {required String token}) async {
    try {
      var headers = <String, String>{'Authorization': 'Bearer $token'};
      var response = await apiProvider.sendAsMultiPart(
          'POST', 'Artefacts',
          headers: headers, body: artefact.toJson());
      if (responseOk(response)) {
        var jsonResponse = json.decode(response!.body);
        return Artefact.fromJson(jsonResponse);
      }
      return null;
    } catch (e) {
      _log.fine("An error occured while posting category: $e");
      return null;
    }
  }

  Future<bool> deleteArtifact({
    required String artifactId,
    required String token,
  }) async {
    try {
      var headers = <String, String>{'Authorization': 'Bearer $token'};

      var response = await apiProvider.delete(
        'Artefacts/$artifactId',
        headers: headers,
      );

      return responseOk(response);
    } catch (e) {
      _log.fine("An error occurred while deleting artifact: $e");
      return false;
    }
  }

  Future<List<Category>?> fetchMostUsedCategories(String token,
      {int limit = 3}) async {
    try {
      Map<String, String> headers = {
        "Authorization": 'Bearer $token',
      };
      var response = await apiProvider.fetchAsJson(
          'Categories/most-used?limit=$limit',
          headers: headers);

      if (responseOk(response)) {
        var jsonResponse = json.decode(response!.body) as List;
        var categories = jsonResponse
            .map((jsonCategory) =>
                Category.fromJson(jsonCategory as Map<String, dynamic>))
            .toList();
        return categories;
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  Future<bool> trackCategoryUsage(String categoryId,
      {required String token}) async {
    try {
      var headers = <String, String>{'Authorization': 'Bearer $token'};
      var response = await apiProvider.postAsJson(
          'Categories/$categoryId/usage',
          headers: headers,
          body: {});

      if (responseOk(response)) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
    }
  }
}

class UserRepository extends ApiDataRepository {
  Future<User?> fetchUser(String token) async {
    try {
      Map<String, String> headers = {
        "Authorization": 'Bearer $token',
      };
      var response = await apiProvider.fetchAsJson('Users', headers: headers);
      if (responseOk(response)) {
        var jsonResponse = json.decode(response!.body);
        var user = User.fromJson(jsonResponse);
        return user;
      } else {
        return null;
      }
    } catch (e) {
      _log.fine("An error occured while fetching user data: $e");
      return null;
    }
  }

  Future<List<User>?> fetchAllUsers(String token) async {
    try {
      Map<String, String> headers = {
        "Authorization": 'Bearer $token',
      };
      var response = await apiProvider.fetchAsJson('Users', headers: headers);
      if (responseOk(response)) {
        var jsonResponse = json.decode(response!.body) as List;
        var users = jsonResponse
            .map((jsonUser) => User.fromJson(jsonUser as Map<String, dynamic>))
            .toList();
        return users;
      } else {
        return null;
      }
    } catch (e) {
      _log.fine("An error occured while fetching users: $e");
      return null;
    }
  }

  /// Fetch only related contacts for the current user
  /// For caregivers: returns their connected children
  /// For children: returns their connected caregivers
  Future<List<User>?> fetchRelatedContacts(String token) async {
    try {
      Map<String, String> headers = {
        "Authorization": 'Bearer $token',
      };
      var response = await apiProvider.fetchAsJson('Contacts',
          headers: headers);

      _log.fine('Related contacts response: ${response?.body}');
      _log.fine('Related contacts status code: ${response?.statusCode}');
      _log.fine('Related contacts headers: ${response?.headers}');
      _log.fine('Related contacts request: ${response?.request}');

      if (responseOk(response)) {
        var jsonResponse = json.decode(response!.body) as List;
        var users = jsonResponse
            .map((jsonUser) => User.fromJson(jsonUser as Map<String, dynamic>))
            .toList();
        return users;
      } else {
        return null;
      }
    } catch (e) {
      _log.fine("An error occured while fetching related contacts: $e");
      return null;
    }
  }

  /// Update user settings (NameVisible, FieldCount)
  Future<bool> updateUserSettings({
    required String token,
    bool? nameVisible,
    int? fieldCount,
  }) async {
    try {
    
      Map<String, String> headers = {
        "Authorization": 'Bearer $token',
      };
      
      Map<String, dynamic> body = {};
      if (nameVisible != null) body['nameVisible'] = nameVisible;
      if (fieldCount != null) body['fieldCount'] = fieldCount;
      
      
      var response = await apiProvider.patchAsJson('Users', 
        headers: headers, 
        body: body
      );
      
      return responseOk(response);
    } catch (e) {
      return false;
    }
  }

  /// Bulk update nameShown for all user's artefacts
  Future<bool> bulkUpdateArtefactsNameShown({
    required String token,
    required bool nameShown,
  }) async {
    try {
      
      Map<String, String> headers = {
        "Authorization": 'Bearer $token',
      };
      
      Map<String, dynamic> body = {'nameShown': nameShown};
            
      var response = await apiProvider.patchAsJson(
        'Artefacts/bulk-update-name-shown', 
        headers: headers, 
        body: body
      );

      
      return responseOk(response);
    } catch (e) {
      return false;
    }
  }
}
