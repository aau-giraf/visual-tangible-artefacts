import 'package:flutter/material.dart';
import 'package:vta_app/src/ui/widgets/board/add_item_popup.dart';
import 'package:vta_app/src/controllers/artifact_controller.dart';

// For now just refer to already used menues, but maybe add its own functionality later

class QuickAddArtefactButton extends StatefulWidget {

  final ArtefactController artefactController;

  const QuickAddArtefactButton({
    super.key,
    required this.artefactController,
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
                widget.artefactController.newArtifact(context, 'Session-Artefact');
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
