import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vta_app/src/modelsDTOs/login_response.dart';
import 'package:vta_app/src/modelsDTOs/signup_form.dart';
import 'package:vta_app/src/singletons/user_info.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import 'package:vta_app/src/singletons/token.dart';

/// Model for handling authentication and storing authentication data
class AuthModel {
  Token token;
  UserInfo userInfo;
  final ApiProvider apiProvider;

  AuthModel(this.apiProvider, this.token, this.userInfo);

  /// Checks if a valid token is stored in the device
  Future<bool> checkAuth() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('jwtToken');
    return token != null && token.isNotEmpty;
  }

  Future<void> loadCache() async {
    final prefs = await SharedPreferences.getInstance();
    token.value = prefs.getString('jwtToken');
    userInfo.userId = prefs.getString('userId');
  }

  /// Logs in the user with the provided [username] and [password]
  Future<void> login(String username, String password) async {
    try {
      var response = await apiProvider.postAsJson('Users/Login',
          body: {'username': username, 'password': password});
      if (response != null && response.ok) {
        var jsonData = jsonDecode(response.body);
        var model = LoginResponse.fromJson(jsonData);
        token.value = model.token;
        userInfo.userId = model.userId;
        await cacheData(token: token.value, userId: userInfo.userId);
      } else {
        _throwAuthException(response?.statusCode);
      }
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }
  }

  Future<void> cacheData({String? token, String? userId}) async {
    final prefs = await SharedPreferences.getInstance();
    if (token != null) {
      prefs.setString('jwtToken', token);
    }
    if (userId != null) {
      prefs.setString('userId', userId);
    }
  }

  Future<void> clearCacheData() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('jwtToken');
      await prefs.remove('userId');
    } catch (e) {
      debugPrint('[AuthModel.clearCacheData] failed: $e');
    } finally {
      token.value = null;
      userInfo.userId = null;
    }
  }

  /// clears all data stored on in the [SharedPreferences]
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
    await clearCacheData();
  }

  /// Signs up the user with the provided [email] and [password]
  Future<void> signup(SignupForm form) async {
    try {
      var response =
          await apiProvider.postAsJson('Users/Signup', body: form.toJson());
      if (response != null && response.ok) {
        var jsonData = jsonDecode(response.body);
        var model = LoginResponse.fromJson(jsonData);
        token.value = model.token;
        userInfo.userId = model.userId;
        cacheData(token: token.value, userId: userInfo.userId);
      } else {
        throw Exception(
            'Mislykkedes at oprette bruger, status kode: ${response?.statusCode}');
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
      message = 'Ingen respons fra server';
    } else if (statusCode == 409) {
      message = 'Dette brugernavn eksisterer allerede, vælg et andet';
    } else if (statusCode == 404) {
      message = 'Forkert brugernavn eller kodeord';
    } else if (statusCode <= 500) {
      message = 'En serverfejl opstod';
    } else {
      message = 'En ukendt fejl opstod';
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
