import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/board/artifact.dart'; // Import the LinearBoardButton widget

class LinearBoard extends StatefulWidget {
  final List<BoardArtefact?> ?artifacts;
  final Color? backgroundColor;

  const LinearBoard({
    super.key,
    this.artifacts,
    this.backgroundColor,
  });

  @override
  createState() => LinearBoardState();
}

class LinearBoardState extends State<LinearBoard> with TickerProviderStateMixin {
  late List<BoardArtefact?> artifacts;
  int fieldCount = 4;

  @override
  void initState() {
    super.initState();
    // Initialize with a fixed number spots in the map
    artifacts = List<BoardArtefact?>.filled(fieldCount, null, growable: false);
  }

  /// Function for adding an artifact to the board. An index of location can be provided, if available
  void addArtifact(BoardArtefact artifact, {int? index}) {
    int indexOfLocation = -1;

    if (index == null) {
      // We should find the first available null spot within the current range of artifacts
      for (int i = 0; i < artifacts.length; i++) {
        if (artifacts[i] == null) {
          indexOfLocation = i;
          break;
        }
      }
    } else {
      // If the index is empty, we can pass it
      if (artifacts[index] == null) {
        indexOfLocation = index;
      } else {
        // If the index was not empty, try and make room
        if (shiftArtifactsToMakeRoom(index)) {
          indexOfLocation = index;
        }
      }
    }

    // If no location was found for the artifact, let the user know and return
    if(indexOfLocation == -1) {
      showBoardFullDialog();
      return;
    }

    // Set the new artifact at the specified index, if a location was found
    setState(() {
      artifacts[indexOfLocation] = artifact;
    });
  }

  /// Function to attempt shifting the artifacts, to make room.
  bool shiftArtifactsToMakeRoom(int index) {
    // Attempt to find a space by moving artifacts around within the size of the map.
    for (int i = artifacts.length - 1; i > index; i--) {
      if (artifacts[i] == null) {
        // First, attempt to move it to the right
        for (int j = i; j > index; j--) {
          artifacts[j] = artifacts[j - 1];
        }
        artifacts[index] = null;
        return true;
      }
    }

    for (int i = 0; i < index; i++) {
      if (artifacts[i] == null) {
        // If it didn't succeed moving it to the right, move it to the left
        for (int j = i; j < index; j++) {
          artifacts[j] = artifacts[j + 1];
        }
        removeArtifact(index);
        return true;
      }
    }

    // Return false if unable to move artifacts
    return false;
  }

  /// Remove an artifact
  void removeArtifact(int index) {
    artifacts[index] = null;
  }

  /// Remove all artifacts
  void removeAllArtifacts() {
    for (int i = artifacts.length - 1; i > 0; i--) {
      artifacts[i] = null;
    }
  }

  /// Confirmation dialog for removing all artifacts on the board
  void confirmRemoveAllArtifacts() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm"),
          content: Text("Are you sure you want to remove all artifacts?"),
          actions: <Widget>[
            TextButton(
              child: Text("Cancel"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
            TextButton(
              child: Text("Yes"),
              onPressed: () {
                setState(() {
                  removeAllArtifacts();
                  }
                );
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  /// Display a message to the user that the board is full
  void showBoardFullDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Error"),
          content: const Text("Board is full."),
          actions: <Widget>[
            TextButton(
              child: const Text("OK"),
              onPressed: () {
                Navigator.of(context).pop(); // Close the dialog
              },
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.85,
        height: MediaQuery.of(context).size.height * 0.5,
        decoration: BoxDecoration(
            color: const Color.fromARGB(255, 255, 255, 255),
            borderRadius: BorderRadius.circular(10.0),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                spreadRadius: 2,
                blurRadius: 2,
                offset: const Offset(0, 4),
              )
            ]),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < fieldCount; i++) ...[
              _buildBox(context, artifacts[i], i),
              if (i < fieldCount - 1) _buildVerticalDivider(context),
            ]
          ],
        ),
      ),
    );
  }

  Widget _buildBox(BuildContext context, BoardArtefact? artifact, int index) {
    return Expanded(
      child: DragTarget<BoardArtefact>(
        onAcceptWithDetails: (DragTargetDetails<BoardArtefact> details) {
          addArtifact(details.data, index: index);
        },
        builder: (BuildContext context, List<BoardArtefact?> candidateData, List<dynamic> rejectedData) {
          return SizedBox(
            width: MediaQuery.of(context).size.width * 0.2,
            height: MediaQuery.of(context).size.height * 0.4,
            child: artifact == null ? null : _buildDraggableArtifact(context, artifact, index),
          );
        },
      ),
    );
  }

  Widget _buildDraggableArtifact(BuildContext context, BoardArtefact artifact, int index) {
    return Draggable<BoardArtefact>(
      data: artifact,
      feedback: Material(
        type: MaterialType.transparency,
        child: Container(
          width: MediaQuery.of(context).size.width * 0.2,
          height: MediaQuery.of(context).size.height * 0.4,
          child: artifact.content,
        ),
      ),
      onDragCompleted: () {
        removeArtifact(index);
      },
      childWhenDragging: Opacity(
        opacity: 0.5,
        child: artifact.content,
      ),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
        ),
        child: artifact.content,
      ),
    );
  }

  Widget _buildVerticalDivider(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.44,
      width: 1,
      color: Colors.grey,
    );
  }
}
