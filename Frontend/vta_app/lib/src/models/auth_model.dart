import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vta_app/src/modelsDTOs/login_response.dart';
import 'package:vta_app/src/modelsDTOs/signup_form.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';

/// Model for handling authentication and storing authentication data
class AuthModel {
  String? token;
  final ApiProvider apiProvider;

  AuthModel(this.apiProvider);

  /// Checks if a valid token is stored in the device
  Future<bool> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');
    return token != null && token.isNotEmpty;
  }

  /// Logs in the user with the provided [username] and [password]
  Future<void> login(String username, String password) async {
    try {
      var response = await apiProvider.postAsJson('Users/Login',
          body: {'username': username, 'password': password});
      if (response != null && response.ok) {
        var jsonData = jsonDecode(response.body);
        var model = LoginResponse.fromJson(jsonData);
        token = model.token;
      } else {
        _throwAuthException(response?.statusCode);
      }
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }
  }

  /// clears all data stored on in the [SharedPreferences]
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }

  /// Signs up the user with the provided [email] and [password]
  Future<void> signup(SignupForm form) async {
    try {
      var response =
          await apiProvider.postAsJson('Users/Signup', body: form.toJson());
      if (response != null && response.ok) {
        var jsonData = jsonDecode(response.body);
        var model = LoginResponse.fromJson(jsonData);
        token = model.token;
      } else {
        throw Exception(
            'Signup failed with status code: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }
  }

  /// Throws an [AuthException] based on the [statusCode]
  void _throwAuthException(int? statusCode) {
    String message;
    if (statusCode == null) {
      message = 'No response from server';
    } else if (statusCode == 409) {
      message = 'This username already exists, please choose another';
    } else if (statusCode == 404) {
      message = 'Invalid username or password';
    } else if (statusCode <= 500) {
      message = 'A server error occured';
    } else {
      message = 'An unknown error occured';
    }
    throw AuthException(message: message);
  }
}

/// Exception for handling authentication errors
/// with a custom [message]
///
/// if message is not provided, the default message is 'AuthException'
class AuthException implements Exception {
  final String? message;

  AuthException({this.message = 'AuthException'});

  @override
  String toString() {
    return message!;
  }
}
