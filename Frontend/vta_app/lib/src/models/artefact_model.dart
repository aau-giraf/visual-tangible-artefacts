import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/modelsDTOs/category.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';

class ArtifactModel {
  List<Category> _categories = [];
  final ApiProvider apiProvider;

  ArtifactModel(this.apiProvider);

  Future<void> fetchCategories({required String token}) async {
    try {
      var response = await apiProvider.fetchAsJson("Categories", headers: {
        'Authorization': 'Bearer $token',
      });
      if (response != null && response.ok) {
        var jsonResponse = json.decode(response.body) as List;
        var categories = jsonResponse
            .map((jsonCategory) =>
                Category.fromJson(jsonCategory as Map<String, dynamic>))
            .toList();
        categories.sort((a, b) => a.categoryIndex!.compareTo(b.categoryIndex!));
        _categories = categories;
      } else {
        throw ArtifactException(
            message:
                'Failed to fetch categories with status code: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint("$e");
      rethrow;
    }
  }

  Future<void> postCategory(Category category, {required String token}) async {
    try {
      var response = await apiProvider
          .postAsJson("Users/Categories", headers: {'Authorization': token});
      if (response != null && response.ok) {
        var jsonResponse = jsonDecode(response.body);
        var newCategory = Category.fromJson(jsonResponse);
        _categories.add(newCategory);
        _categories
            .sort((a, b) => a.categoryIndex!.compareTo(b.categoryIndex!));
      }
    } catch (e) {}
  }
}

class ArtifactException implements Exception {
  final String message;

  ArtifactException({this.message = 'ArtifactException'});

  @override
  String toString() {
    return message;
  }
}
