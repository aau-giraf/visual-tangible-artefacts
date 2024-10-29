import 'package:flutter/material.dart';
import 'package:vta_app/src/models/artefact.dart';

class BoardArtefact {
  final Widget content;
  Offset? position;
  final GlobalKey key; // GlobalKey for accessing the widget's context
  Size? renderedSize;
  Artefact? baseArtefact;

  BoardArtefact({
    required this.content,
    this.position = Offset.zero,
    this.baseArtefact,
  }) : key = GlobalKey();

  factory BoardArtefact.fromArtefact(Artefact artefact,
      {Map<String, String>? headers}) {
    return BoardArtefact(
        content: SizedBox(
          width: 200,
          height: 200,
          child: FadeInImage(
            image: NetworkImage(artefact.imageUrl ?? "", headers: headers),
            placeholder: AssetImage('assets/images/flutter_logo.png'),
          ),
        ),
        baseArtefact: artefact);
  }
}
