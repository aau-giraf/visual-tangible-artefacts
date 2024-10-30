import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vta_app/src/models/category.dart';
import 'package:vta_app/src/models/login_form.dart';
import 'package:vta_app/src/models/login_response.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'dart:convert';

abstract class ApiDataRepository {
  ApiProvider apiProvider = ApiProvider(baseUrl: "https://localhost:7180/api/");

  Future<bool> handleResponse(http.Response? response) async {
    if (response == null) {
      throw Exception('No response from server.');
    }
    switch (response.statusCode) {
      case 200:
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
  Future<String?> login(String username, String password) async {
    try {
      var loginForm = LoginForm(username: username, password: password);

      final response =
          await apiProvider.postAsJson('Users/Login', body: loginForm.toJson());
      if (await handleResponse(response)) {
        var loginResponse = LoginResponse.fromJson(json.decode(response!.body));
        if (loginResponse.token != null) {
          String token = loginResponse.token!;
          SharedPreferences prefs = await SharedPreferences.getInstance();
          await prefs.setString('jwt_token', token);
          return token;
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
      if (await handleResponse(response)) {
        var jsonResponse = json.decode(response!.body) as List;
        var categories = jsonResponse
            .map((jsonCategory) =>
                Category.fromJson(jsonCategory as Map<String, dynamic>))
            .toList();
        return categories;
      } else {
        return null;
      }
    } catch (e) {
      debugPrint("An error occured while fetching categories: $e");
      return null;
    }
  }
}
