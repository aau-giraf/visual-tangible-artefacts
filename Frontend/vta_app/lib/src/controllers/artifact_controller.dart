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

  Future<void> newCategory(BuildContext context) async {
    var popup = AddItemPopup(
      isCategory: true,
      onSubmit: (name, imageBytes) async {
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
      builder: (context) => popup,
    );
  }

  Future<void> deleteCategory(Category category, BuildContext context) async {
    try {
      await _showDeleteConfirmationDialog(context, onDelete: () async {
        await _model.deleteCategory(category,
            token: GetIt.I.get<Token>().value!);
        notifyListeners();
        if (context.mounted) {
          _showSuccessActionSnackBar(context, 'Categori slettet');
        }
      });
    } catch (e) {
      if (context.mounted) {
        _showErrorSnackBar(context, e.toString());
      }
    }
  }

  Future<void> newArtifact(BuildContext context, String categoryId) async {
    var popup = AddItemPopup(
        isCategory: false,
        onSubmit: (name, imageBytes) {
          try {
            var newArtefact = Artefact(
                categoryId: categoryId,
                artefactIndex: 0,
                userId: GetIt.I.get<UserInfo>().userId,
                image: imageBytes);
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
        builder: (context) {
          return popup;
        });
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
