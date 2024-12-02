import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/models/artefact_model.dart';
import 'package:vta_app/src/modelsDTOs/category.dart';
import 'package:vta_app/src/shared/global_snackbar.dart';
import 'package:vta_app/src/singletons/token.dart';

class ArtifactController extends ChangeNotifier {
  final ArtifactModel _model;
  List<Category>? get categories => _model.categories;

  ArtifactController(this._model);

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

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).removeCurrentSnackBar();
    GlobalSnackbar.show(context, message,
        color: Colors.white, iconColor: Colors.red);
  }
}
