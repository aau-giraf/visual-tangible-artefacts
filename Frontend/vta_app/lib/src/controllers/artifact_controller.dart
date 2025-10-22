import 'dart:io';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/models/artefact_model.dart';
import 'package:vta_app/src/modelsDTOs/artefact.dart';
import 'package:vta_app/src/modelsDTOs/category.dart';
import 'package:vta_app/src/shared/global_snackbar.dart';
import 'package:vta_app/src/singletons/token.dart';
import 'package:vta_app/src/singletons/user_info.dart';
import 'package:vta_app/src/ui/widgets/board/add_item_popup.dart';

class ArtefactController extends ChangeNotifier {
  final ArtifactModel _model;
  List<Category>? get categories => _model.categories;
  List<Category>? get mostUsedCategories => _model.mostUsedCategories;

  ArtefactController(this._model);
  

  Future<void> updateArtifacts({BuildContext? context}) async {
    var token = GetIt.instance.get<Token>();
    try {
      await _model.fetchAndUpdateCategories(token: token.value!);
    } catch (e) {
      if (context != null && context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> updateMostUsedCategories(
      {BuildContext? context, int limit = 3}) async {
    var token = GetIt.instance.get<Token>();
    try {
      await _model.fetchAndUpdateMostUsedCategories(
          token: token.value!, limit: limit);
    } catch (e) {
      if (context != null && context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> newCategory(BuildContext context) async {
    var popup = AddItemPopup(
      isCategory: true,
      title: 'Tilføj kategori',
      onSubmit: (name, imageBytes, soundBytes) async {
        try {
          var newCategory = Category(
            categoryIndex: 0,
            userId: GetIt.I.get<UserInfo>().userId,
            name: name,
            image: imageBytes,
          );
          await _model.postCategory(
            newCategory,
            token: GetIt.I.get<Token>().value!,
          );
          notifyListeners();
          _showSuccessActionSnackBar(context, 'Category tilføjet');
        } catch (e) {
          _showErrorSnackBar(context, e.toString());
        }
      },
    );
    await showDialog(
      context: context,
      barrierColor: Colors.black.withValues(alpha: 0.80),
      builder: (context) => popup,
    );
  }

  Future<void> deleteCategory(Category category, BuildContext context) async {
    // Save ScaffoldMessenger reference before dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    try {
      await _showDeleteConfirmationDialog(context, onDelete: () async {
        await _model.deleteCategory(category,
            token: GetIt.I.get<Token>().value!);
        notifyListeners();

        _showSuccessSnackBarAfterAsync(
          scaffoldMessenger,
          screenHeight,
          'Categori slettet',
        );
      });
    } catch (e) {
      _showErrorSnackBarAfterAsync(
        scaffoldMessenger,
        screenHeight,
        e.toString(),
      );
    }
  }

  Future<void> newArtifact(BuildContext context, String categoryId) async {
    var popup = AddItemPopup(
        isCategory: false,
        title: 'Tilføj artefakt',
        onSubmit: (name, imageBytes, soundBytes) {
          try {
            var newArtefact = Artefact(
                categoryId: categoryId,
                artefactIndex: 0,
                userId: GetIt.I.get<UserInfo>().userId,
                image: imageBytes,
                sound: soundBytes,
                name: name);
            _model.postArtefact(newArtefact,
                token: GetIt.I.get<Token>().value!);
            _showSuccessActionSnackBar(context, 'Artefact tilføjet');
            notifyListeners();
          } catch (e) {
            if (context.mounted) {
              _showErrorSnackBar(context, e.toString());
            }
          }
        });
    await showDialog(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.80),
        builder: (context) {
          return popup;
        });
  }

  Future<String> getArtifactName(String artefactId) async {
    return "Test: artefactId is $artefactId";
  }

  Future<void> deleteArtefact(BuildContext context, Artefact artefact) async {
    // Save ScaffoldMessenger reference before dialog
    final scaffoldMessenger = ScaffoldMessenger.of(context);
    final screenHeight = MediaQuery.of(context).size.height;

    try {
      await _showDeleteConfirmationDialog(context, onDelete: () async {
        _model.deleteArtefact(artefact, token: GetIt.I.get<Token>().value!);

        _showSuccessSnackBarAfterAsync(
          scaffoldMessenger,
          screenHeight,
          'Artefact slettet',
        );
      });
    } catch (e) {
      _showErrorSnackBarAfterAsync(
        scaffoldMessenger,
        screenHeight,
        e.toString(),
      );
    }
  }

  Future<void> updateArtefact(
    BuildContext context, 
    Artefact artefact,
  ) async {
    try {
      await _model.updateArtefact(artefact, token: GetIt.I.get<Token>().value!);
      notifyListeners();
      if (context.mounted) {
        _showSuccessActionSnackBar(context, 'Artefact opdateret');
      }
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
      rethrow;
    }
  }

  Future<void> trackCategoryUsage(String categoryId,
      {BuildContext? context}) async {
    var token = GetIt.instance.get<Token>();

    try {
      var category = _model.categories?.firstWhere(
        (cat) => cat.categoryId == categoryId,
        orElse: () => Category(),
      );

      if (category?.categoryId == null) {
        return;
      }

      var success =
          await _model.trackCategoryUsage(categoryId, token: token.value!);
      if (success) {
        notifyListeners();
      }
    } catch (e) {
    }
  }

  void _showSuccessActionSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    GlobalSnackbar.show(context, message,
        color: Colors.white, iconColor: Colors.green);
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    GlobalSnackbar.show(context, message,
        color: Colors.white, iconColor: Colors.red);
  }

  // Helper methods for async calls (using saved ScaffoldMessenger)
  void _showSuccessSnackBarAfterAsync(
    ScaffoldMessengerState messenger,
    double screenHeight,
    String message,
  ) {
    messenger.removeCurrentSnackBar();
    GlobalSnackbar.show(
      null, // No context available after async gap
      message,
      color: Colors.white,
      iconColor: Colors.green,
      showAtTop: true,
      scaffoldMessenger: messenger,
      screenHeight: screenHeight,
    );
  }

  void _showErrorSnackBarAfterAsync(
    ScaffoldMessengerState messenger,
    double screenHeight,
    String message,
  ) {
    messenger.removeCurrentSnackBar();
    GlobalSnackbar.show(
      null, // No context available after async gap
      message,
      color: Colors.white,
      iconColor: Colors.red,
      showAtTop: true,
      scaffoldMessenger: messenger,
      screenHeight: screenHeight,
    );
  }

  // This can be used for category or artefact deletion by passing the appropriate delete action
  Future<void> _showDeleteConfirmationDialog(
    BuildContext context, {
    required Future<void> Function() onDelete,
  }) async {
    await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Slet'),
          content: const Text('Er du sikker på du vil slette denne?'),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
              },
              child: const Text('Annuller'),
            ),
            TextButton(
              onPressed: () async {
                // Call the provided delete callback
                await onDelete();
                Navigator.of(context).pop();
              },
              child: const Text('Slet'),
            ),
          ],
        );
      },
    );
  }
}
