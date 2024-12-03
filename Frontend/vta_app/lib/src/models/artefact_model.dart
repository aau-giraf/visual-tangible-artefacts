import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/modelsDTOs/category.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';

class ArtifactModel {
  List<Category>? categories;
  final ApiProvider apiProvider;

  ArtifactModel(this.apiProvider);

  Future<void> fetchAndUpdateCategories({required String token}) async {
    try {
      var response =
          await apiProvider.fetchAsJson("Users/Categories", headers: {
        'Authorization': 'Bearer $token',
      });
      if (response != null && response.ok) {
        var jsonResponse = json.decode(response.body) as List;
        var newCategories = jsonResponse
            .map((jsonCategory) =>
                Category.fromJson(jsonCategory as Map<String, dynamic>))
            .toList();
        newCategories
            .sort((a, b) => a.categoryIndex!.compareTo(b.categoryIndex!));
        categories = newCategories;
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
      var response = await apiProvider.postAsJson("Users/Categories",
          body: category.toJson(), headers: {'Authorization': token});
      if (response != null && response.ok) {
        var jsonResponse = jsonDecode(response.body);
        var newCategory = Category.fromJson(jsonResponse);
        categories!.add(newCategory);
        categories!
            .sort((a, b) => a.categoryIndex!.compareTo(b.categoryIndex!));
      } else {
        throw ArtifactException(
            message:
                'Failed to post category, status code: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }
  }

  Future<void> postArtefact(Artefact artefact, {required String token}) async {
    try {
      var response = await apiProvider.sendAsMultiPart(
          'POST', "Users/Artefacts",
          body: artefact.toJson(), headers: {'Authorization': token});
      if (response != null && response.ok) {
        var jsonResponse = jsonDecode(response.body);
        var newArtefact = Artefact.fromJson(jsonResponse);
        categories
            ?.firstWhere((item) => item.categoryId == newArtefact.categoryId)
            .artefacts
            ?.add(newArtefact);
      } else {
        throw ArtifactException(
            message:
                'Failed to post artefact, status code: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }
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
