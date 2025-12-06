import 'package:flutter/material.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';
import 'package:vta_app/src/ui/widgets/board/board_artifact.dart';
import 'package:get_it/get_it.dart';
import 'package:vta_app/src/singletons/token.dart';

// For now just refer to already used menues, but maybe add its own functionality later

class QuickAddArtefactButton extends StatefulWidget {

  final ArtefactController artefactController;
  final Function(BoardArtefact) onArtifactAdded;

  const QuickAddArtefactButton({
    super.key,
    required this.artefactController,
    required this.onArtifactAdded,
  });

  @override
  State<QuickAddArtefactButton> createState() => _FloatingActionButtonExampleState();
}

class _FloatingActionButtonExampleState extends State<QuickAddArtefactButton> {
  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Align(
          alignment: Alignment.topRight,
          child: Padding(
            padding: const EdgeInsets.only(top: 50.0, right: 120.0),
            child: FloatingActionButton(
              heroTag: 'quickAddArtefact',
              onPressed: () {
                widget.artefactController.newArtifact(
                  context,
                  'Session-Artefact',
                  onCreated: (createdArtefact) {
                    // Build headers if token exists so network images/audio can be fetched
                    final token = GetIt.instance.get<Token>().value;
                    Map<String, String>? headers;
                    if (token != null) headers = {'Authorization': 'Bearer $token'};
                    final boardArtefact = BoardArtefact.fromArtefact(createdArtefact, headers: headers);
                    widget.onArtifactAdded(boardArtefact);
                  },
                );
              },
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              shape: const CircleBorder(),
              child: const Icon(Icons.add_rounded, size: 40),
            ),
          ),
        ),
      ],
    );
  }
}
