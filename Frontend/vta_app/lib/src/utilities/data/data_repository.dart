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
import 'dart:convert';

abstract class ApiDataRepository {
  var apiSettings = GlobalConfiguration().appConfig['ApiSettings'];
  late ApiProvider apiProvider;

  ApiDataRepository() {
    apiProvider = ApiProvider(baseUrl: apiSettings['BaseUrl']['Local']);
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
    try {
      var loginForm = LoginForm(username: username, password: password);

      final response =
          await apiProvider.postAsJson('Users/Login', body: loginForm.toJson());
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
        return null;
      }
    } catch (e) {
      debugPrint('An error occurred during login: $e');
      return null;
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
          await apiProvider.fetchAsJson('Users/Categories', headers: headers);
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
      debugPrint("An error occured while fetching categories: $e");
      return null;
    }
  }

  Future<Category?> addCategory(Category category,
      {required String token}) async {
    try {
      var headers = <String, String>{'Authorization': 'Bearer $token'};
      var response = await apiProvider.sendAsMultiPart(
          'POST', 'Users/Categories',
          headers: headers, body: category.toJson());
      if (responseOk(response)) {
        var jsonResponse = json.decode(response!.body);
        return Category.fromJson(jsonResponse);
      }
      return null;
    } catch (e) {
      debugPrint("An error occured while posting category: $e");
      return null;
    }
  }

  Future<bool> updateCategory(Category category,
      {required String token}) async {
    var headers = <String, String>{'Authorization': 'Bearer $token'};
    var response = await apiProvider.sendAsMultiPart(
        'PATCH', 'Users/Categories/',
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
        'Users/Categories/$categoryId',
        headers: headers,
      );
      if (responseOk(response)) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      debugPrint("An error occured while deleting category: $e");
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
          .fetchAsJson('Users/Artefacts/$artefactId', headers: headers);
      if (responseOk(response)) {
        var jsonResponse = json.decode(response!.body);
        return Artefact.fromJson(jsonResponse);
      }
      return null;
    } catch (e) {
      debugPrint("An error occurred while fetching artefact: $e");
      return null;
    }
  }

  Future<Artefact?> addArtifact(Artefact artefact,
      {required String token}) async {
    try {
      var headers = <String, String>{'Authorization': 'Bearer $token'};
      var response = await apiProvider.sendAsMultiPart(
          'POST', 'Users/Artefacts',
          headers: headers, body: artefact.toJson());
      if (responseOk(response)) {
        var jsonResponse = json.decode(response!.body);
        return Artefact.fromJson(jsonResponse);
      }
      return null;
    } catch (e) {
      debugPrint("An error occured while posting category: $e");
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
        'Users/Artefacts/$artifactId',
        headers: headers,
      );

      return responseOk(response);
    } catch (e) {
      debugPrint("An error occurred while deleting artifact: $e");
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
          'Users/Categories/most-used?limit=$limit',
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
          'Users/Categories/$categoryId/usage',
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
      debugPrint("An error occured while fetching user data: $e");
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
      debugPrint("An error occured while fetching users: $e");
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

      debugPrint('Related contacts response: ${response?.body}');
      debugPrint('Related contacts status code: ${response?.statusCode}');
      debugPrint('Related contacts headers: ${response?.headers}');
      debugPrint('Related contacts request: ${response?.request}');

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
      debugPrint("An error occured while fetching related contacts: $e");
      return null;
    }
  }
}
