import 'package:flutter/material.dart';
import 'package:jwt_decoder/jwt_decoder.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:vta_app/src/models/category.dart';
import 'package:vta_app/src/utilities/data/data_repository.dart';

class AuthState with ChangeNotifier {
  String? _token;
  String? _userId;

  String? get token => _token;
  String? get userId => _userId;

  Future<String?> login(String username, String password) async {
    var loginResponse = await AuthRepository().login(username, password);
    _token = loginResponse?.token;
    _userId = loginResponse?.userId;
    notifyListeners();
    return token;
  }

  Future<bool> loadTokenFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _token = prefs.getString('jwt_token');
    if (_token != null && !JwtDecoder.isExpired(_token!)) {
      return true;
    } else {
      return false;
    }
  }

  Future<bool> loadUserIdFromCache() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    if (_userId != null) {
      return true;
    } else {
      return false;
    }
  }

  void logout() {
    _token = null;
    notifyListeners();
  }
}

class ArtifactState with ChangeNotifier {
  List<Category>? _categories = [];

  List<Category>? get categories => _categories;

  Future<bool> loadCategories(String token) async {
    _categories = await ArtifactRepository().fetchCategories(token);
    if (_categories != null) {
      notifyListeners();
      return true;
    }
    return false;
  }

  Future<bool> addCategory(Category category, {required String token}) async {
    var newCategory =
        await ArtifactRepository().addCategory(category, token: token);
    if (newCategory != null) {
      _categories?.add(newCategory);
      notifyListeners();
      return true;
    }
    return false;
  }
}
