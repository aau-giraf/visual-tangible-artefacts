// controllers/linear_board_controller.dart

import 'package:flutter/material.dart';

import '../ui/widgets/board/artifact.dart';

class LinearBoardController extends ChangeNotifier {
  List<BoardArtefact?> artifacts;
  int fieldCount;

  LinearBoardController({
    required this.artifacts,
    required this.fieldCount,
  });

  @override
  void dispose() {
    super.dispose();
  }

  /// Function for adding an artifact to the board. An index of location can be provided, if available
  void addArtifact(BoardArtefact artifact, {int? index}) {
    int indexOfLocation = -1;

    if (index == null) {
      // Find the first available null spot within the current range of artifacts
      for (int i = 0; i < artifacts.length; i++) {
        if (artifacts[i] == null) {
          indexOfLocation = i;
          break;
        }
      }
    } else {
      // If the index is empty, use it
      if (artifacts[index] == null) {
        indexOfLocation = index;
      } else {
        // If the index is not empty, try to make room
        if (_shiftArtifactsToMakeRoom(index)) {
          indexOfLocation = index;
        }
      }
    }

    // If no location was found for the artifact, notify listeners
    if (indexOfLocation == -1) {
      // Notify the view to show the board full dialog
      _boardFullCallback?.call();
      return;
    }

    // Set the new artifact at the specified index, if a location was found
    artifacts[indexOfLocation] = artifact;
    notifyListeners();
  }

  /// Function to move artifacts.
  void moveArtifact(int currentId, int newId) {
    // Return early if user is trying to place it in the same field
    if (currentId == newId) {
      return;
    }

    // Find a spot
    if (artifacts[newId] == null) {
      // If the new index is empty, simply move the artifact there
      artifacts[newId] = artifacts[currentId];
      artifacts[currentId] = null;
    } else {
      // If not, attempt to shift artifacts to make room at the new index
      if (_shiftArtifactsToMakeRoom(newId)) {
        artifacts[newId] = artifacts[currentId];
        artifacts[currentId] = null;
      } else {
        // If shifting is not possible, perform a swap
        _swapArtifacts(currentId, newId);
      }
    }
    notifyListeners();
  }

  /// Function to attempt shifting the artifacts to make room.
  bool _shiftArtifactsToMakeRoom(int index) {
    // Check if shifting right is possible and needed
    if (index < artifacts.length - 1 && artifacts[index + 1] == null) {
      // Shift the artifact from index to index + 1
      artifacts[index + 1] = artifacts[index];
      artifacts[index] = null;
      return true;
    }

    // Check if shifting left is possible and needed
    if (index > 0 && artifacts[index - 1] == null) {
      // Shift the artifact from index to index - 1
      artifacts[index - 1] = artifacts[index];
      artifacts[index] = null;
      return true;
    }

    // Return false if no shifting occurred
    return false;
  }

  /// Function to swap artifacts' locations
  void _swapArtifacts(int id1, int id2) {
    BoardArtefact? temp = artifacts[id1];
    artifacts[id1] = artifacts[id2];
    artifacts[id2] = temp;
  }

  /// Remove an artifact
  void removeArtifact(int index) {
    artifacts[index] = null;
    notifyListeners();
  }

  /// Remove all artifacts
  void removeAllArtifacts() {
    for (int i = artifacts.length - 1; i >= 0; i--) {
      removeArtifact(i);
    }
  }

  /// Callback to notify the view to show dialogs
  VoidCallback? _boardFullCallback;

  /// Setter for the board full callback
  void setBoardFullCallback(VoidCallback callback) {
    _boardFullCallback = callback;
  }
}