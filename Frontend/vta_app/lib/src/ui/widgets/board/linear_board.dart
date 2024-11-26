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

  /// Function to move artifacts.
  void moveArtifact(int currentId, int newId) {
    if (artifacts[newId] == null) {
      // If the new index is empty, simply move the artifact there
      artifacts[newId] = artifacts[currentId];
      artifacts[currentId] = null;
    } else {
      // If not, attempt to shift artifacts to make room at the new index
      if (shiftArtifactsToMakeRoom(newId)) {
        artifacts[newId] = artifacts[currentId];
        artifacts[currentId] = null;
      } else {
        // If shifting is not possible, perform a swap
        swapArtifacts(currentId, newId);
      }
    }
    setState(() {});
  }

  /// Function to attempt shifting the artifacts, to make room.
  bool shiftArtifactsToMakeRoom(int index) {
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

  /// Function to swap artifacts locations
  void swapArtifacts(int id1, int id2) {
    BoardArtefact? temp = artifacts[id1];
    artifacts[id1] = artifacts[id2];
    artifacts[id2] = temp;
  }

  /// Remove an artifact
  void removeArtifact(int index) {
    artifacts[index] = null;
    setState(() {});
  }

  /// Remove all artifacts
  void removeAllArtifacts() {
    for (int i = artifacts.length - 1; i >= 0; i--) {
      removeArtifact(i);
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
                removeAllArtifacts();
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
    return Stack(
      children: [
        _buildGrid(context),
        Align(
          alignment: Alignment.bottomCenter,
          child: _buildTrashcan(context),
        ),
      ],
    );
  }

  Widget _buildGrid(BuildContext context) {
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
          int currentIndex = artifacts.indexOf(details.data);
          if (currentIndex != -1) {
            moveArtifact(currentIndex, index);
          }
        },
        builder: (BuildContext context, List<BoardArtefact?> candidateData, List<dynamic> rejectedData) {
          return Padding (
            padding: EdgeInsets.all(5),
            child: SizedBox(
              width: MediaQuery.of(context).size.width * 0.2,
              height: MediaQuery.of(context).size.height * 0.4,
              child: artifact == null ? null : _buildDraggableArtifact(context, artifact, index),
            ),
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

  Widget _buildTrashcan(BuildContext context) {
    return DragTarget<BoardArtefact>(
      onAcceptWithDetails: (DragTargetDetails<BoardArtefact> details) {
        int artifactIndex = artifacts.indexOf(details.data);
        print("artifact index: $artifactIndex");
        if (artifactIndex != -1) {
          removeArtifact(artifactIndex);
        }
      },
      builder: (BuildContext context, List<BoardArtefact?> candidateData, List<dynamic> rejectedData) {
        return Container(
          // Defined size to increase target area
          width: 200,
          height: 100,
          color: Colors.transparent,
          alignment: Alignment.center,
          child: _buildTrashcanIcon(),
        );
      },
    );
  }

  Widget _buildTrashcanIcon({
    double width = 50,
    double height = 50,
    Color color = const Color(0xFFF0F2D9)}) {
    return GestureDetector(
      onTap: () {
        confirmRemoveAllArtifacts();
      },
      child: Stack(children: [
        Container(
          width: width,
          height: height,
          decoration: ShapeDecoration(
            color: color,
            shape: const OvalBorder(),
            shadows: const [
              BoxShadow(
                color: Color(0x3F000000),
                blurRadius: 4,
                offset: Offset(0, 4),
                spreadRadius: 0,
              )
            ],
          ),
          child: Center(
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/icons/trash_bin.png'),
                  fit: BoxFit.scaleDown,
                ),
              ),
            ),
          ),
        ),
      ]),
    );
  }
}