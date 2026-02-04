// ignore_for_file: avoid_print, unused_element

import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/modelsDTOs/category.dart';
import 'package:vta_app/src/utilities/api/api_provider.dart';
import '../database/repositories/artefact_repository.dart';
import '../database/repositories/category_repository.dart';
import '../database/mappers/artefact_mapper.dart';
import '../database/models/category_db.dart';

class ArtifactModel {
  List<Category>? categories;
  List<Category>? mostUsedCategories;
  final ApiProvider apiProvider;

  ArtifactModel(this.apiProvider);

  /// ------------------------------------------------------------
  /// FUNCTIONS FOR SAVING TO LOCAL DATABASE
  /// ------------------------------------------------------------

  /// Converts Category DTO to CategoryDB model
  CategoryDB _categoryToDb(Category c) {
    return CategoryDB(
      categoryId: c.categoryId ?? '',
      categoryIndex: c.categoryIndex,
      userId: c.userId ?? '',
      name: c.name,
      imagePath: c.imageUrl,
      modifiedDate: DateTime.now().millisecondsSinceEpoch ~/ 1000,
    );
  }

  // Reserved for future offline/local database functionality
  Future<void> _fetchAndUpdateCategoriesLocal() async {
    try {
      final repo = CategoryRepository();
      final dbCategories = await repo.getAll();
      final jsonString =
          jsonEncode(dbCategories.map((e) => e.toMap()).toList());

      // Decode back to List<dynamic> to match online response structure
      var jsonResponse = jsonDecode(jsonString) as List;

      var newCategories = jsonResponse
          .map((jsonCategory) =>
              Category.fromJson(jsonCategory as Map<String, dynamic>))
          .toList();
      newCategories
          .sort((a, b) => a.categoryIndex!.compareTo(b.categoryIndex!));
      categories = newCategories;
    } catch (e) {
      debugPrint('[ArtifactModel] Failed to fetch local categories: $e');
      rethrow;
    }
  }

  // Reserved for future offline/local database functionality
  Future<void> _postArtefactLocal(Artefact artefact) async {
    try {
      final repo = ArtefactRepository();
      final dbModel = artefactToDb(artefact);
      await repo.insert(dbModel);
    } catch (e) {
      debugPrint('Local DB artefact insert failed: $e');
      rethrow;
    }
  }

  // Reserved for future offline/local database functionality
  Future<void> _postCategoryLocal(Category category) async {
    try {
      final repo = CategoryRepository();
      final dbModel = _categoryToDb(category);
      await repo.insert(dbModel);
    } catch (e) {
      debugPrint('Local DB category insert failed: $e');
      rethrow;
    }
  }

  // Reserved for future offline/local database functionality
  Future<void> _deleteCategoryLocal(String categoryId) async {
    try {
      final repo = CategoryRepository();
      await repo.delete(categoryId);
    } catch (e) {
      debugPrint('Local DB category delete failed: $e');
      rethrow;
    }
  }

  // Reserved for future offline/local database functionality
  Future<void> _deleteArtefactLocal(String artefactId) async {
    try {
      final repo = ArtefactRepository();
      await repo.delete(artefactId);
    } catch (e) {
      debugPrint('Local DB artefact delete failed: $e');
      rethrow;
    }
  }

  // Reserved for future offline/local database functionality
  Future<void> _updateArtefactLocal(Artefact artefact) async {
    try {
      final repo = ArtefactRepository();
      final dbModel = artefactToDb(artefact);
      await repo.update(dbModel);
    } catch (e) {
      debugPrint('Local DB artefact update failed: $e');
      rethrow;
    }
  }

  // Reserved for future offline/local database functionality
  Future<void> _trackCategoryUsageLocal(String categoryId) async {
    try {
      final repo = CategoryRepository();
      await repo.incrementUsageCount(categoryId);
    } catch (e) {
      debugPrint('Local DB category usage tracking failed: $e');
      rethrow;
    }
  }

  // Reserved for future offline/local database functionality
  Future<void> _fetchAndUpdateMostUsedCategoriesLocal({int limit = 3}) async {
    try {
      final repo = CategoryRepository();
      final dbCategories = await repo.getAll();

      // Sort by usage count and take the top N
      dbCategories.sort((a, b) {
        final aUsage = (a as CategoryDB).usageCount;
        final bUsage = (b as CategoryDB).usageCount;
        return bUsage.compareTo(aUsage);
      });

      final topCategories = dbCategories.take(limit).toList();
      final jsonString = jsonEncode(
          topCategories.map((e) => (e as CategoryDB).toMap()).toList());
      var jsonResponse = jsonDecode(jsonString) as List;

      var newMostUsedCategories = jsonResponse
          .map((jsonCategory) =>
              Category.fromJson(jsonCategory as Map<String, dynamic>))
          .toList();
      mostUsedCategories = newMostUsedCategories;
    } catch (e) {
      debugPrint('Local DB fetch most used categories failed: $e');
      rethrow;
    }
  }

  /// ------------------------------------------------------------
  /// FUNCTIONS FOR SAVING TO LOCAL DATABASE
  /// ------------------------------------------------------------

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
                'Mislykkedes at hente kategorier, status kode: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('[ArtifactModel] Error: $e');
      rethrow;
    }
    try {
      /// For future local use only
      // await _fetchAndUpdateCategoriesLocal();
    } catch (e) {
      debugPrint('Local DB fetch failed: $e');
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

        // Save locally
        try {
          // await _postCategoryLocal(newCategory);
        } catch (e) {
          debugPrint('Local DB save failed: $e');
        }
      } else {
        throw ArtifactException(
            message:
                'Mislykkedes at poste kategori, status kode: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('[ArtifactModel] Error: $e');
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

        // Delete locally
        try {
          // await _deleteCategoryLocal(category.categoryId!);
        } catch (e) {
          debugPrint('Local DB delete failed: $e');
        }
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

  Future<Artefact> postArtefact(Artefact artefact,
      {required String token}) async {
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
          // await _postArtefactLocal(newArtefact);
        } catch (e) {
          debugPrint('Local DB save failed: $e');
        }
        final catId = newArtefact.categoryId;

        if (catId == 'Session-Artefact') {
          // Do not add to categories list!!! session artefacts are treated as uncategorized.
        } else {
          if (categories != null) {
            final idx =
                categories!.indexWhere((item) => item.categoryId == catId);
            if (idx != -1) {
              categories![idx].artefacts ??= [];
              categories![idx].artefacts!.add(newArtefact);
            } else {
              // Category wrapper to hold the artefact locally
              categories!
                  .add(Category(categoryId: catId, artefacts: [newArtefact]));
            }
          } else {
            // No categories cached at all - create the list with a single category
            categories = [
              Category(categoryId: catId, artefacts: [newArtefact])
            ];
          }
        }

        return newArtefact;
      } else {
        throw ArtifactException(
            message:
                'Failed to post artefact, status code: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('[ArtifactModel] Error: $e');
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
          final idx = categories!
              .indexWhere((c) => c.categoryId == artefact.categoryId);
          if (idx != -1 && categories![idx].artefacts != null) {
            categories![idx]
                .artefacts!
                .removeWhere((a) => a.artefactId == artefact.artefactId);
          }
        }

        // Delete locally
        try {
          // await _deleteArtefactLocal(artefact.artefactId!);
        } catch (e) {
          debugPrint('Local DB delete failed: $e');
        }
      } else {
        throw ArtifactException(
            message:
                'Failed to delete artefact, status code: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('[ArtifactModel] Error: $e');
      rethrow;
    }
  }

  Future<void> updateArtefact(Artefact artefact,
      {required String token}) async {
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
          body: body, headers: {'Authorization': 'Bearer $token'});

      if (response != null && response.ok) {
        // Update the local artefact in the categories list
        var category = categories?.firstWhere(
          (cat) => cat.categoryId == artefact.categoryId,
          orElse: () => Category(),
        );
        if (category?.artefacts != null) {
          var index = category!.artefacts!
              .indexWhere((a) => a.artefactId == artefact.artefactId);
          if (index != -1) {
            // Fetch the updated artefact to get the new soundUrl if sound was updated
            var getResponse = await apiProvider.fetchAsJson(
                "Users/Artefacts/${artefact.artefactId}",
                headers: {'Authorization': 'Bearer $token'});
            if (getResponse != null && getResponse.ok) {
              var updatedArtefact =
                  Artefact.fromJson(jsonDecode(getResponse.body));
              category.artefacts![index] = updatedArtefact;

              // Update locally
              try {
                // await _updateArtefactLocal(updatedArtefact);
              } catch (e) {
                debugPrint('Local DB update failed: $e');
              }
            }
          }
        }
      } else {
        throw ArtifactException(
            message:
                'Failed to update artefact, status code: ${response?.statusCode}');
      }
    } catch (e) {
      debugPrint('[ArtifactModel] Error: $e');
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
      debugPrint('[ArtifactModel] Error: $e');
      rethrow;
    }

    // Try to update from local DB as fallback
    try {
      // await _fetchAndUpdateMostUsedCategoriesLocal(limit: limit);
    } catch (e) {
      debugPrint('Local DB fetch most used failed: $e');
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

        // Track locally
        try {
          // await _trackCategoryUsageLocal(categoryId);
        } catch (e) {
          debugPrint('Local DB usage tracking failed: $e');
        }

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
