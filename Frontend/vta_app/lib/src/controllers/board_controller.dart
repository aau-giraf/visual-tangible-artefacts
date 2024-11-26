import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:path/path.dart';

import '../models/board_model.dart';
import '../modelsDTOs/category.dart';
import '../ui/widgets/board/artefact.dart';
import '../ui/widgets/remove_all_dialog.dart';
import '../modelsDTOs/artefact.dart';
import '../utilities/data/data_repository.dart';

class BoardController with ChangeNotifier {
  final BoardModel _boardModel;

  BoardController(this._boardModel);

  List<BoardArtefact> get artefacts => _boardModel.artefacts;

  bool get isGestureInsideMat => _boardModel.isGestureInsideMat;
  List<Category>? get categories => _boardModel.categories;
  /*TODO: Should this be handled by the controller, model, or UI?*/
  //get AnimationController animationController => _boardModel.animationController;
  //get Animation<Offset> offsetAnimation => _boardModel.offsetAnimation;
  bool get showDeleteHover => _boardModel.showDeleteHover;
  bool get isDraggingOverTrashCan => _boardModel.isDraggingOverTrashCan;
  /*TODO: Should we declare them here
  final double? width;
  final double? height;
  final Color? backgroundColor;
*/
  void setDeleteHover(bool show){
    _boardModel.setDeleteHover(show);
  }
  void setOverTrashCan(bool overTrash){
    _boardModel.setOverTrashCan(overTrash);
  }
  Future<bool> loadCategories(String token) async {
    _boardModel.loadCategories(await ArtifactRepository().fetchCategories(token));
    if (categories != null) {
      notifyListeners();
      return true;
    }
    return false;
  }

  void removeArtefactsPopUp(BuildContext context) {
    showDialog(context: context, builder: (context) {
      return RemoveAllDialog(controller: this);
    });
  }

  void removeArtefacts(BuildContext context) {
    _boardModel.removeAllArtefacts(context);
  }

  void removeArtefact(GlobalKey artefactKey) {
    _boardModel.removeArtefact(artefactKey);
  }

  void addArtefact(BoardArtefact artefact) {
    _boardModel.addArtefact(artefact);
  }
  /*TODO: This should maybe be a controller function*/
  void updateArtefactPosition(BoardArtefact artefact, Offset offset,
      BuildContext context) {
    _boardModel.updateArtefactPosition(artefact, offset, context);
  }
  void loadArtefactSize(BoardArtefact artefact) {
    // Access the size of the artifact's content after it has been rendered
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final RenderBox? renderBox =
      artefact.key.currentContext?.findRenderObject() as RenderBox?;
      if (renderBox != null) {
        final size = renderBox.size;

        // Update the rendered size in the artifact
        artefact.renderedSize = size;
      }
    });
  }

  bool isInsideMat(Offset globalOffset, BuildContext context) {
    final RenderBox? renderBox = context.findRenderObject() as RenderBox?;
    if (renderBox == null) return false;

    // Get the global position of the top-left corner of the TalkingMat
    final Offset matTopLeftGlobal = renderBox.localToGlobal(Offset.zero);

    // Check if the artifact is inside the mat by comparing global coordinates
    return globalOffset.dx - matTopLeftGlobal.dx >= 0 &&
        globalOffset.dx + matTopLeftGlobal.dx <= renderBox.size.width &&
        globalOffset.dy - matTopLeftGlobal.dy >= 0 &&
        globalOffset.dy + matTopLeftGlobal.dy <= renderBox.size.height;
  }
}