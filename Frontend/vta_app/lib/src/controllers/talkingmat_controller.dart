import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';

class TalkingmatController extends ValueNotifier<List<BoardArtefact>> {
  final Function(BoardArtefact)? onArtefactAdded;
  
  TalkingmatController({List<BoardArtefact>? initialArtifacts, this.onArtefactAdded})
      : super(initialArtifacts ?? []);

  void addArtifact(BoardArtefact artefact) {
    value.add(artefact);
    onArtefactAdded?.call(artefact);
    notifyListeners();
  }

  void removeArtifact(BoardArtefact artefact) {
    // Prefer removing by savedArtefactId (instance id) to avoid removing all duplicates
    if (artefact.savedArtefactId != null) {
      value.removeWhere((item) => item.savedArtefactId == artefact.savedArtefactId);
    } else {
      // Fallback: remove a single instance matching the artefactId
      final idx = value.indexWhere((item) => item.artefactId == artefact.artefactId);
      if (idx != -1) {
        value.removeAt(idx);
      }
    }
    notifyListeners();
  }

  void removeAllArtifacts({BuildContext? context}) {
    if (context != null && context.mounted) {
      _showRemoveAllArtifactsAlert(context);
    }
  }

  void _showRemoveAllArtifactsAlert(BuildContext context) {
    showDialog(
        context: context,
        builder: (context) {
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
                  value.clear();
                  Navigator.of(context).pop(); // Close the dialog
                  notifyListeners();
                },
              ),
            ],
          );
        });
  }
}
