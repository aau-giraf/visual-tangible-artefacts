import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/modelsDTOs/category.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';

class ArtifactModel {
  List<Category>? categories;
  List<Category>? mostUsedCategories;
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
      var response = await apiProvider.sendAsMultiPart(
          'POST', "Users/Categories",
          body: category.toJson(), headers: {'Authorization': 'Bearer $token'});
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

  Future<void> deleteCategory(Category category,
      {required String token}) async {
    try {
      var response = await apiProvider.delete(
          'Users/Categories/${category.categoryId}',
          headers: {'Authorization': 'Bearer $token'});
      if (response != null && response.ok) {
        categories
            ?.removeWhere((item) => item.categoryId == category.categoryId);
      } else {
        throw ArtifactException(
            message:
                'Kunne ikke slette artefact, status kode: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint(e.toString());
      rethrow;
    }
  }

  Future<void> postArtefact(Artefact artefact, {required String token}) async {
    try {
      // Ensure we pass the sound bytes with the key 'Sound' to match backend IFormFile binding
      var body = artefact.toJson();
      if (artefact.sound != null) {
        // the API provider will convert Uint8List values into multipart files
        body['Sound'] = artefact.sound;
      }
      var response = await apiProvider.sendAsMultiPart(
          'POST', "Users/Artefacts",
          body: body, headers: {'Authorization': 'Bearer $token'});
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

  Future<void> deleteArtefact(Artefact artefact,
      {required String token}) async {
    try {
      var response = await apiProvider.delete(
          "Users/Artefacts/${artefact.artefactId}",
          headers: {'Authorization': 'Bearer $token'});
      if (response != null && response.ok) {
        categories
            ?.firstWhere(
                (category) => category.categoryId == artefact.categoryId)
            .artefacts
            ?.removeWhere((a) => a.artefactId == artefact.artefactId);
      } else {
        throw ArtifactException(
            message:
                'Failed to delete artefact, status code: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }
  }

  Future<void> updateArtefact(Artefact artefact, {required String token}) async {
    try {
      var body = <String, dynamic>{
        'ArtefactId': artefact.artefactId,
        'UserId': artefact.userId,
      };
      if (artefact.name != null) {
        body['Name'] = artefact.name;
      }
      if (artefact.categoryId != null) {
        body['CategoryId'] = artefact.categoryId;
      }
      if (artefact.artefactIndex != null) {
        body['ArtefactIndex'] = artefact.artefactIndex.toString();
      }
      if (artefact.sound != null) {
        body['Sound'] = artefact.sound;
      }
      if (artefact.image != null) {
        body['Image'] = artefact.image;
      }
      if (artefact.nameShown != null) {
        body['NameShown'] = artefact.nameShown;
      }
      
      var response = await apiProvider.sendAsMultiPart(
          'PATCH', "Users/Artefacts",
          body: body, 
          headers: {'Authorization': 'Bearer $token'});
      
      if (response != null && response.ok) {
        // Update the local artefact in the categories list
        var category = categories?.firstWhere(
          (cat) => cat.categoryId == artefact.categoryId,
          orElse: () => Category(),
        );
        if (category?.artefacts != null) {
          var index = category!.artefacts!.indexWhere(
            (a) => a.artefactId == artefact.artefactId
          );
          if (index != -1) {
            // Fetch the updated artefact to get the new soundUrl if sound was updated
            var getResponse = await apiProvider.fetchAsJson(
              "Users/Artefacts/${artefact.artefactId}",
              headers: {'Authorization': 'Bearer $token'}
            );
            if (getResponse != null && getResponse.ok) {
              var updatedArtefact = Artefact.fromJson(jsonDecode(getResponse.body));
              category.artefacts![index] = updatedArtefact;
            }
          }
        }
      } else {
        throw ArtifactException(
            message:
                'Failed to update artefact, status code: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('$e');
      rethrow;
    }
  }

  Future<void> fetchAndUpdateMostUsedCategories(
      {required String token, int limit = 3}) async {
    try {
      var response = await apiProvider
          .fetchAsJson("Users/Categories/most-used?limit=$limit", headers: {
        'Authorization': 'Bearer $token',
      });
      if (response != null && response.ok) {
        var jsonResponse = json.decode(response.body) as List;
        var newMostUsedCategories = jsonResponse
            .map((jsonCategory) =>
                Category.fromJson(jsonCategory as Map<String, dynamic>))
            .toList();
        mostUsedCategories = newMostUsedCategories;
      } else {
        throw ArtifactException(
            message:
                'Failed to fetch most used categories with status code: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint("$e");
      rethrow;
    }
  }

  Future<bool> trackCategoryUsage(String categoryId,
      {required String token}) async {
    try {
      var response = await apiProvider.postAsJson(
          "Users/Categories/$categoryId/usage",
          headers: {'Authorization': 'Bearer $token'},
          body: {});

      if (response != null && response.ok) {
        await fetchAndUpdateMostUsedCategories(token: token);
        return true;
      } else {
        return false;
      }
    } catch (e) {
      return false;
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
