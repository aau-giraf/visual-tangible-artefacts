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
import 'package:vta_app/src/ui/widgets/categories/categories_widget.dart';

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

  Future<void> newArtifact(BuildContext context, String categoryId) async {
    var popup = AddItemPopup(
        isCategory: false,
        onSubmit: (name, imageBytes) {
          var newArtefact = Artefact(
              categoryId: categoryId,
              artefactIndex: 0,
              userId: GetIt.I.get<UserInfo>().userId,
              image: imageBytes);
          _model.postArtefact(newArtefact, token: GetIt.I.get<Token>().value!);
        });
    showDialog(
        context: context,
        builder: (context) {
          return popup;
        });
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    GlobalSnackbar.show(context, message,
        color: Colors.white, iconColor: Colors.red);
  }
}
