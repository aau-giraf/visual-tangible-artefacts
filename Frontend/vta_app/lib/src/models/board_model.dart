import 'package:flutter/material.dart';

import 'package:vta_app/src/ui/widgets/board/artefact.dart';

import '../modelsDTOs/category.dart';

class BoardModel
{
  List<Category> _categories = [];
  final List<BoardArtefact> _artefacts = [];
  bool _isGestureInsideMat = false;
  /*TODO: Should this be handled by the controller, model, or UI?*/
  //late AnimationController _animationController
  //late Animation<Offset> _offsetAnimation;
  bool _showDeleteHover = false;
  bool _isDraggingOverTrashCan = false;
  bool _moveCategoriesMode = false;

  List<Category> get categories => _categories;
  List<BoardArtefact> get artefacts => _artefacts;
  bool get isGestureInsideMat => _isGestureInsideMat;
  /*TODO: Should this be handled by the controller, model, or UI?*/
  //get AnimationController animationController => _animationController;
  //get Animation<Offset> offsetAnimation => _offsetAnimation;
  bool get showDeleteHover => _showDeleteHover;
  bool get isDraggingOverTrashCan => _isDraggingOverTrashCan;
  bool get moveCategoriesMode => _moveCategoriesMode;
  void setDeleteHover(bool show){
    _showDeleteHover = show;
  }
  void setOverTrashCan(bool overTrash){
    _isDraggingOverTrashCan = overTrash;
  }
  void setMoveCategories(bool move){
    _moveCategoriesMode = move;
  }

  void loadCategories(List<Category>? cat){
    _categories = cat;
  }

  void removeAllArtefacts(BuildContext context) {

  }
  void removeArtefact(GlobalKey artefactKey) {
    _artefacts.removeWhere((artefact) => artefact.key == artefactKey);
  }
  void addArtefact(BoardArtefact artefact) {
      _artefacts.add(artefact);
  }

  void clearArtefacts() {
    _artefacts.clear();
  }
  /*TODO: This should maybe be a controller function*/
  void updateArtefactPosition(BoardArtefact artefact, Offset offset, BuildContext context) {
    // Get the rendered size of the artifact if available
    Size? size = artefact.renderedSize;

    if (size != null) {
      // Get the RenderBox of the current widget to handle coordinate conversions
      final RenderBox renderBox = context.findRenderObject() as RenderBox;

      // Convert the global touch/click position to local coordinates
      // This ensures the position is relative to the board's coordinate space
      final localPosition = renderBox.globalToLocal(offset);

      // Update the artifact's position in the state
      // This will trigger a rebuild with the new position
      //setState(() {
      // artefact.position = localPosition;
      //});
    }
  }
}TextButton _buildCategoryButton(
      Key? key, BuildContext context, int index, Category item) {
    return TextButton(
      key: key,
      onPressed: () => _showCategoryModal(context, categories[index]),
      child: _buildCategoryContainer(item),
    );
  }