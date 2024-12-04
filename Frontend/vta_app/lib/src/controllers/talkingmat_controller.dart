import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';

class TalkingmatController extends ValueNotifier<List<BoardArtefact>> {
  TalkingmatController({List<BoardArtefact>? initialArtifacts})
      : super(initialArtifacts ?? []);

  void addArtifact(BoardArtefact artefact) {
    value.add(artefact);
    notifyListeners();
  }

  void removeArtifact(BoardArtefact artefact) {
    value.removeWhere((item) => item.key == artefact.key);
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
