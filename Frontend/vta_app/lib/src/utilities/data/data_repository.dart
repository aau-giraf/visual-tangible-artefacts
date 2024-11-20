import 'package:flutter/material.dart';
import 'package:global_configuration/global_configuration.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vta_app/src/models/artefact.dart';
import 'package:vta_app/src/models/category.dart';
import 'package:vta_app/src/models/login_form.dart';
import 'package:vta_app/src/models/login_response.dart';
import 'package:vta_app/src/models/user.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'dart:convert';

abstract class ApiDataRepository {
  var apiSettings = GlobalConfiguration().appConfig['ApiSettings'];
  late ApiProvider apiProvider;

  ApiDataRepository() {
    apiProvider = ApiProvider(baseUrl: apiSettings['BaseUrl']['Remote']);
  }

  bool responseOk(http.Response? response) {
    if (response == null) {
      throw Exception('No response from server.');
    }
    switch (response.statusCode) {
      case 200:
        return true;
      case 201:
        return true;
      case 401:
        throw Exception('Invalid username or password.');

      case 500:
        throw Exception('Internal server error.');
      default:
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
      var response = await apiProvider.postAsMultiPart('Users/Categories',
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

  Future<Category?> updateCategory(Category category,
      {required String token}) async {
    var headers = <String, String>{'Authorization': 'Bearer $token'};
    var response = await apiProvider.patchAsJson('Users/Categories/',
        headers: headers, body: category.toJson());
    if (responseOk(response)) {
      var jsonResponse = json.decode(response!.body);
      return Category.fromJson(jsonResponse);
    }
    return null;
  }

  Future<Artefact?> addArtifact(Artefact artefact,
      {required String token}) async {
    try {
      var headers = <String, String>{'Authorization': 'Bearer $token'};
      var response = await apiProvider.postAsMultiPart('Users/Artefacts',
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
}
