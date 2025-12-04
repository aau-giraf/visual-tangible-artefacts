import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/modelsDTOs/category.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import '../database/repositories/artefact_repository.dart';
import '../database/mappers/artefact_mapper.dart';


class ArtifactModel {
  List<Category>? categories;
  List<Category>? mostUsedCategories;
  final ApiProvider apiProvider;

  ArtifactModel(this.apiProvider);

  /// ------------------------------------------------------------
  /// FUNCTIONS FOR SAVING TO LOCAL DATABASE
  /// ------------------------------------------------------------

 /* 
 Future<void> _fetchAndUpdateCategoriesLocal() async {
    try {
      final repo = ArtefactRepository();
      final dbCategories = await repo.getAllCategoriesWithArtefacts();
      categories = dbCategories
          .map((dbCategory) => categoryFromDb(dbCategory))
          .toList();
    } catch (e) {
      rethrow;
    }
  }
  */

  Future<void> _postArtefactLocal(Artefact artefact) async {
      try {
        // TODO Maybe too narrow scope for repo and dbModels, depends on level of access needed
        final repo = ArtefactRepository();
        final dbModel = artefactToDb(artefact);
        await repo.insert(dbModel);
      } catch (e) {
        // Not great catch
        rethrow;
      }
    }


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

  Future<Artefact> postArtefact(Artefact artefact, {required String token}) async {
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
        
        // SAVE LOCALLY
        try {
          await _postArtefactLocal(newArtefact);
        } catch (e) {
          debugPrint('Local DB save failed: $e');
        }
        final catId = newArtefact.categoryId;

        if (catId == 'Session-Artefact') {
          // Do not add to categories list!!! session artefacts are treated as uncategorized.
        } else {
          if (categories != null) {
            final idx = categories!.indexWhere((item) => item.categoryId == catId);
            if (idx != -1) {
              categories![idx].artefacts ??= [];
              categories![idx].artefacts!.add(newArtefact);
            } else {
              // Category wrapper to hold the artefact locally
              categories!.add(Category(categoryId: catId, artefacts: [newArtefact]));
            }
          } else {
            // No categories cached at all - create the list with a single category
            categories = [Category(categoryId: catId, artefacts: [newArtefact])];
          }
        }

        return newArtefact;
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
        if (categories != null) {
          final idx = categories!.indexWhere((c) => c.categoryId == artefact.categoryId);
          if (idx != -1 && categories![idx].artefacts != null) {
            categories![idx].artefacts!.removeWhere((a) => a.artefactId == artefact.artefactId);
          }
        }
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

  void clearCache() {
    categories = [];
    mostUsedCategories = [];
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
